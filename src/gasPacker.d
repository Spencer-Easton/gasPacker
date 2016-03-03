import std.process;
import std.stdio;
import std.string;
import std.file;
import std.getopt;
import std.json;
import std.format: formattedWrite;
import std.array: appender;
import std.algorithm.mutation: remove;


//I code for me so I'll use globals if I feel like it.
string[string] optLibs;
string fileOut;
string[] publicAPI;

int main(string[] args) {
	GetoptResult cmdOptions;
	try {
		arraySep = ",";
		cmdOptions = getopt(args, "libs|l",
			"lib1Id=lib1NameSpace,lib2Id=libNameSpace\nor\n--libs lib1Id=lib1Namespace --libs=lib2Id=lib2Namespace", &optLibs,
			"packFile|f", "File name to output to", &fileOut
		);
		if (cmdOptions.helpWanted) {
			defaultGetoptPrinter("\ngasPacker options", cmdOptions.options);
			return 0;
		}
	}
	
	catch (std.getopt.GetOptException e) {
		writeln("Invalid arguments use --help for options.");
		return 1;
	}

	if (fileOut is null) {
		writeln("Gaspacker: You must specify an output file");
		return 1;
	}
	else {
		writeln("Packing libraries in: "~fileOut);
	}
	
	std.file.write(fileOut,"");
	foreach(string libId, string libNameSpace; optLibs) {
			writeln("Building Library for: "~libId~" : "~libNameSpace);
		     append(fileOut, makeLibrary(libId,libNameSpace));
		}
	return 0;
}

// main script to build indiviual libraries from source code
string makeLibrary(string libId, string nameSpace){
        string scratchFile = getTempFolder()~"/gasPackerScratch.js";
		int results = fetchLibrary(libId);
		if(results == 0){
		createScratchFile(scratchFile);
		getTopLevelFunctions(scratchFile);
		string packedLibrary = buildLibraryTemplate(publicAPI.join(","), readText(scratchFile), nameSpace);
		removeTempFiles();
		publicAPI = null;
		return packedLibrary;
		}else{
		removeTempFiles();
		return "";
		}
}

// gasIO creates individual files, this recombines them to one file per project.
void createScratchFile(string scratchFile){
	std.file.write(scratchFile,"");
	auto libFiles = getFilesInTempDir();
	foreach(string fileName; libFiles){
		auto thisFile = readText(fileName);
		append(scratchFile,thisFile);
	}
}

string getTempFolder() {
	return tempDir() ~"/gasPacker";
}

void removeTempFiles() {
	auto dmd = execute(["rm", "-r", getTempFolder()]);
	if (dmd.status != 0) writeln("Failed to remove temp files\n", dmd.output);
}

int fetchLibrary(string libId) {
	if (exists(getTempFolder()) == false) {
		mkdir(getTempFolder());
	}
	auto dmd = execute(["gasIO", "-g", "-i"~libId], null, Config.none, size_t.max, getTempFolder());
	if (dmd.status != 0){ writeln("Fetch failed.  Is `" ~ libId ~ "` the correct id?" /*, dmd.output*/ ); return 1;}
	return 0;
	}

auto getFilesInTempDir() {
	return dirEntries(getTempFolder(), "*.{gs}", SpanMode.depth);
}

//allows user to select which functions are exposed
void selectPublicFunctions() {
	string line;
	string lastOption = null;
	writeln("Select functions to expose [yes/no/all]:");
	for (int i = 0; i < publicAPI.length; i++) {
		write(publicAPI[i].split(':')[0] ~" [y/n/a]");
		line = readln().chomp();
		if (line == null && lastOption != null) {
			line = lastOption;
			writeln(line);
		}
		switch (line) {
			case "y":
				lastOption = line;
				break;
			case "n":
			    publicAPI[i] = null; // null out items to remove
				lastOption = line;
				break;
			case "a":
				lastOption = line;
				break;
			case null:
			default:
				i--;
				break;
		}
		
		if(lastOption == "a"){
			break;
		}
	}
	publicAPI = remove!("a == null")(publicAPI); // remove the nulls
}

void getTopLevelFunctions(string fileName) {
	string functions[];
	auto esparsed = execute(["esparse", fileName]);
	if (esparsed.status != 0) writeln("Failed parsing:" ~ fileName);
	else {
		JSONValue esJSON = parseJSON(esparsed.output);
		foreach(JSONValue dec; esJSON["body"].array()) {
			if (dec["type"].str() == "FunctionDeclaration") {
				//writeln("Top Level Function:");
				publicAPI ~= dec.object["id"]["name"].str() ~":"~dec.object["id"]["name"].str();
			}
			if (dec["type"].str() == "VariableDeclaration") {
				foreach(JSONValue vars; dec["declarations"].array()) {
					//writeln("Top Level var: ");
					if (vars.object["init"].type() != JSON_TYPE.NULL) {
						if (vars.object["init"].object["type"].str == "FunctionExpression") {
						    // this is a function
							publicAPI ~= vars["id"]["name"].str() ~":"~vars["id"]["name"].str();
						}
					}
				}
			}
			if (dec["type"].str() == "ExpressionStatement") {
				//Do Nothing! 
			}
		}
	}
	selectPublicFunctions();
}

string buildLibraryTemplate(string exposedAPI, string libSource, string nameSpace) {
string libTemplate = "(function(scope,nameSpace){
	/*
	 * Library Code
	 */
	%s
	/*
	 * End Library Code
	 */
var publicAPI = { 
    %s
                };
scope[nameSpace] = publicAPI || scope[nameSpace];

})(this, \"%s\");\n\n";

	auto writer = appender!string(); formattedWrite(writer, libTemplate, libSource, exposedAPI, nameSpace);
	return writer.data;
}