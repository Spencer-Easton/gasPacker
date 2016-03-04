####gasPacker is a small commandline tool for packaging Google Apps Script libraries into a single file.  
  
#####This tool will:  
1) Download the libraries  
2) Have you select which methods to expose  
3) Package them in their own namespace  
4) Create a single file containing all the packaged libraries  

#####How to build  
 The source for this tool can be found in the src folder.  
 It can be compiled with the dmd compiler found at [http://dlang.org](http://dlang.org/download.html).  
 To compile use `dmd gasPacker.d`. 

#####Dependencies  
  This tool is more of a script as it depends two other projects.  It assumes both gasIO and esparse(part of esprima) are in your PATH.  
  
  1) gasIO:  https://github.com/Spencer-Easton/gasIO  
  gasIO can be built following the instruction on the github page.  
  
  2) esprima: https://github.com/jquery/esprima  
  npm install -g esprima  

#####Basic Usage  
   
     gasPacker options  
     -l     --libs lib1Id=lib1NameSpace,lib2Id=libNameSpace  
              or  
            --libs lib1Id=lib1Namespace --libs=lib2Id=lib2Namespace  
     -f --packFile File name to output to  
     -h     --help This help information.  
     

Command Line Example  

    gasPacker --libs M3BrNtuqhOfGGMqYghYVR2kMLm9v2IJHf=PriorityLogger,MGwgKN2Th03tJ5OdmlzB8KPxhMjh3Sh48=_,MHMchiX6c1bwSqGM1PZiW_PxhMjh3Sh48=Moment --packFile myProjectLibs.gs  
  
  `check the example folder for the output of this operation`  
  
  
 
  
