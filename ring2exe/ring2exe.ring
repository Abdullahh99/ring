/*
**	Application : Ring To Executable 
**	Purpose	    : Convert Ring project source code to executable file 
**		      (Windows, Linux & MacOS X)
**	Author	    : Mahmoud Fayed <msfclipper@yahoo.com>
**	Date	    : 2017.11.06
*/

/*
	Usage

		ring ring2exe.ring filename.ring  [Options]
		This will set filename.ring as input to the program 	

		The next files will be generated 
		filename.ringo	  (The Ring Object File - by Ring Compiler)
		filename.c	  (The C Source code file
				   Contains the ringo file content
				   Will be generated by this program)
		filename_buildvc.bat (Will be executed to build filename.c using Visual C/C++)
		filename_buildgcc.bat (Will be executed to build filename.c using GNU C/C++)
		filename_buildclang.bat (Will be executed to build filename.c using CLang C/C++)
		filename.obj	  (Will be generated by the Visual C/C++ compiler) 
		filename.exe 	  (Will ge generated by the Visual C/C++ Linker)
		filename	  (Executable File - On Linux & MacOS X platforms)

	Note
		We can use 
			ring ring2exe.ring ring2exe.ring 
		This will build ring2exe.exe
		We can use ring2exe.exe 

		ring2exe filename.ring 

		Or (Linux & MacOS X)

		./ring2exe filename.ring

	Testing 	
	
		ring2exe test.ring 
		test 

		Or (Linux & MacOS X)

		./ring2exe test.ring 
		./test

	Options

		-keep       	 : Don't delete Temp. Files
		-static     	 : Build Standalone Executable File (Don't use ring.dll/ring.so/ring.dylib)
		-gui        	 : Build GUI Application (Hide the Console Window)
		-dist	    	 : Prepare application for distribution 
		-allruntime 	 : Include all libraries in distribution
		-noqt	    	 : Remove RingQt from distribution
		-noallegro 	 : Remove RingAllegro from distribution
		-noopenssl  	 : Remove RingOpenSSL from distribution
		-nolibcurl  	 : Remove RingLibCurl from distribution
		-nomysql    	 : Remove RingMySQL from distribution
		-noodbc     	 : Remove RingODBC from distribution
		-nosqlite   	 : Remove RingSQLite from distribution
		-noopengl   	 : Remove RingOpenGL from distribution
		-nofreeglut 	 : Remove RingFreeGLUT from distribution
		-nolibzip   	 : Remove RingLibZip from distribution
		-noconsolecolors : Remove RingConsoleColors from distribution
		-nocruntime	 : Remove C Runtime from distribution
*/

C_WINDOWS_NOOUTPUTNOERROR = " >nul 2>nul"
C_LINUX_NOOUTPUTNOERROR   = " > /dev/null"

func Main 
	aPara = sysargv
	aOptions = []
	# Get Options 
		for x = len(aPara) to 1 step -1
			if left(trim(aPara[x]),1) = "-"
				aOptions + lower(trim(aPara[x]))
				del(aPara,x)
			ok
		next
	nParaCount = len(aPara)
	if nParaCount >= 2
		cFile = aPara[nParaCount]
		msg("Process File : " + cFile)
		BuildApp(cFile,aOptions)
	else 
		drawline()
		see "Application : Ring2EXE (Ring script to Executable file)" + nl
		see "Author      : 2017, Mahmoud Fayed <msfclipper@yahoo.com>" + nl
		see "Usage       : ring2exe filename.ring [Options]" + nl
		drawline()
	ok

func DrawLine 
	see copy("=",70) + nl

func msg cMsg
	see "Ring2EXE: " + cMsg + nl

func BuildApp cFileName,aOptions
	msg("Start building the application...")
	# Generate the Object File 
		systemSilent(exefolder()+"../bin/ring " + cFileName + " -go -norun")
	# Generate the C Source Code File 
		cFile = substr(cFileName,".ring","")
		GenerateCFile(cFile,aOptions)
	# Generate the Batch File 
		cBatch = GenerateBatch(cFile,aOptions)
	# Build the Executable File 
		msg("Build the Executable File...")
		systemSilent(cBatch)
		msg("End of building script...")
	# Clear Temp Files 	
		if not find(aOptions,"-keep")
			cleartempfiles()
		ok
	# Prepare Application for distribution
		if find(aOptions,"-dist")
			Distribute(cFile,aOptions)
		ok
		msg("End of building process...")

func GenerateCFile cFileName,aOptions
	# Display Message
		msg("Generate C source code file...")
	nTime = clock()
	# Convert the Ring Object File to Hex.
		cFile = read(cFileName+".ringo")
		cHex  = str2hexCStyle(cFile)
	fp = fopen(cFileName+".c","w+")
	# Start writing the C source code - Main Function 
	if isWindows() and find(aOptions,"-gui")
		cCode = '#include "windows.h"' 	+ nl +
			'#include "stdio.h"' 	+ nl +
			'#include "stdlib.h"' 	+ nl +
			'#include "conio.h"' 	+ nl +  
			'#include "ring.h"' 	+ nl +  nl +
		'int WINAPI WinMain ( HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nShowCmd )' + nl +  "{" + nl + nl +
		char(9) + 'int argc;' + nl + char(9) + 'char **argv ;' + nl + 
		char(9) + 'argc = __argc ; ' + nl + char(9) + 'argv = __argv ;' + nl + nl +
		char(9) + 'static const unsigned char bytecode[] = { 
			  '
	else
		cCode = '#include "ring.h"' + nl + nl +
		'int main( int argc, char *argv[])' + nl +  "{" + nl + nl +
		char(9) + 'static const unsigned char bytecode[] = { 
			  '
	ok
	fputs(fp,cCode)
	# Add the Object File Content		
		fputs(fp,cHex)
	fputs(fp, ", EOF" + char(9) + "};"+
	"

	RingState *pRingState ;
	pRingState = ring_state_new();	
	pRingState->argc = argc;
	pRingState->argv = argv;
	ring_state_runobjectstring(pRingState,(char *) bytecode);
	ring_state_delete(pRingState);

	return 0;" + nl + 
	"}")
	fclose(fp)	
	msg("Generation Time : " + ((clock()-nTime)/clockspersecond()) + " seconds...")

func GenerateBatch cFileName,aOptions
	msg("Generate batch|script file...")
	if find(aOptions,"-static")
		return GenerateBatchStatic(cFileName,aOptions)
	else 
		return GenerateBatchDynamic(cFileName,aOptions)
	ok

func GenerateBatchDynamic cFileName,aOptions
	msg("Generate batch|script file for dynamic building...")
	return GenerateBatchGeneral([
		:file = cFileName ,
		:ringlib = [
			:windows = "..\lib\ring.lib" ,
			:linux   = "-L $PWD/../lib -lring",
			:macosx	 = "$PWD/../lib/libring.dylib"
		]
	],aOptions)	

func GenerateBatchStatic cFileName,aOptions
	msg("Generate batch|script file for static building...")
	return GenerateBatchGeneral([
		:file = cFileName ,
		:ringlib = [
			:windows = "..\lib\ringstatic.lib" ,
			:linux   = "-L $PWD/../lib -lringstatic",
			:macosx	 = "-L $PWD/../lib -lringstatic"
		]
	],aOptions)


func GenerateBatchGeneral aPara,aOptions
	cFileName = aPara[:file]
	cFile = substr(cFileName," ","_")
	# Generate Windows Batch (Visual C/C++)
		cCode = "call "+exefolder()+"../src/locatevc.bat" + nl +
			"#{f3}" + nl +
			'cl #{f1}.c #{f2} #{f4} -I"..\include" -I"../src/" /link #{f5} /OUT:#{f1}.exe' 
		cCode = substr(cCode,"#{f1}",cFile)
		cCode = substr(cCode,"#{f2}",aPara[:ringlib][:windows])
		# Resource File 
			cResourceFile = cFile + ".rc"
			if fexists(cResourceFile)
				cCode = substr(cCode,"#{f3}","rc " + cResourceFile)
				cCode = substr(cCode,"#{f4}",cFile + ".res")
			else 
				cCode = substr(cCode,"#{f3}","")
				cCode = substr(cCode,"#{f4}","")
			ok
		# GUI Application 
			if find(aOptions,"-gui")
				cCode = substr(cCode,"#{f5}",'advapi32.lib shell32.lib /SUBSYSTEM:WINDOWS,"5.01" ')
			else 
				cCode = substr(cCode,"#{f5}",' /SUBSYSTEM:CONSOLE,"5.01" ')
			ok
		cWindowsBatch = cFile+"_buildvc.bat"
		write(cWindowsBatch,cCode)
	# Generate Linux Script (GNU C/C++)
		cCode = 'gcc -rdynamic #{f1}.c -o #{f1} #{f2} -lm -ldl  -I $PWD/../include  '
		cCode = substr(cCode,"#{f1}",cFile)
		cCode = substr(cCode,"#{f2}",aPara[:ringlib][:linux])
		cLinuxBatch = cFile+"_buildgcc.sh"
		write(cLinuxBatch,cCode)
	# Generate MacOS X Script (CLang C/C++)
		cCode = 'clang #{f1}.c #{f2} -o #{f1} -lm -ldl  -I $PWD/../include  '
		cCode = substr(cCode,"#{f1}",cFile)
		cCode = substr(cCode,"#{f2}",aPara[:ringlib][:macosx])
		cMacOSXBatch = cFile+"_buildclang.sh"
		write(cMacOSXBatch,cCode)
	# Return the script/batch file name
		if isWindows()	
			return cWindowsBatch
		but isLinux()
			systemSilent("chmod +x " + cLinuxBatch)
			return "./"+cLinuxBatch
		but isMacosx()
			systemSilent("chmod +x " + cMacOSXBatch)
			return "./"+cMacOSXBatch	
		ok

func ClearTempFiles
	msg("Clear Temp. Files...")
	if isWindows()
		systemSilent("cleartemp.bat")
	else
		systemSilent("./cleartemp.sh")
	ok

func SystemSilent cCmd
	if isWindows()
		system(cCmd + C_WINDOWS_NOOUTPUTNOERROR)
	else 
		system(cCmd + C_LINUX_NOOUTPUTNOERROR)
	ok

func Make_Folder cFolder
	SystemSilent("mkdir " + cFolder)

func CreateOpenFolder cFolder
	Make_Folder(cFolder)
	chdir(cFolder)

func Distribute cFileName,aOptions
	cBaseFolder = currentdir()
	CreateOpenFolder(:target)
	if isWindows()
		Distribute_For_Windows(cBaseFolder,cFileName,aOptions)
	but isLinux()
		Distribute_For_Linux(cBaseFolder,cFileName,aOptions)
	but isMacOSX()
		Distribute_For_MacOSX(cBaseFolder,cFileName,aOptions)
	ok

func Distribute_For_Windows cBaseFolder,cFileName,aOptions
	# Delete Files 
		WindowsDeleteFolder("windows")
	CreateOpenFolder(:windows)
	# Prepare Files 
		aFiles = []
		# copy the executable file 
			msg("Prepare to copy the executable file to target/windows")
			aFiles + (cBaseFolder+"\"+cFileName+".exe")
		# Check ring.dll
			if not find(aOptions,"-static")	
				msg("Prepare to copy ring.dll to target/windows")	
				aFiles + (exefolder()+"\ring.dll")
			ok
		# Check All Runtime 
			if find(aOptions,"-allruntime")	
				msg("Prepare to copy all libraries to target/windows")	
				aFiles + (exefolder()+"\*.dll")
				if not find(aOptions,"-noqt")
					WindowsCopyFolder(:audio)
					WindowsCopyFolder(:bearer)
					WindowsCopyFolder(:iconengines)
					WindowsCopyFolder(:imageformats)
					WindowsCopyFolder(:mediaservice)
					WindowsCopyFolder(:platforms)
					WindowsCopyFolder(:playlistformats)
					WindowsCopyFolder(:position)
					WindowsCopyFolder(:printsupport)
					WindowsCopyFolder(:sensorgestures)
					WindowsCopyFolder(:sqldrivers)
					WindowsCopyFolder(:translations)
				ok
			ok
	# Copy Files
		msg("Copy files...")
		for cFile in aFiles 
			systemSilent("copy " + cFile)
		next
	# Check no ring.dll	
		if find(aOptions,"-static")
			msg("Remove ring.dll")
			WindowsDeleteFile("ring.dll")
		ok
	# Check No Qt 
		if find(aOptions,"-noqt")
			msg("Remove RingQt from target/windows")
			WindowsDeleteFile("Qt5*.dll")
			WindowsDeleteFile("ringqt.dll")	
			WindowsDeleteFile("icudt54.dll")		
			WindowsDeleteFile("icuin54.dll")
			WindowsDeleteFile("icuuc54.dll")
			WindowsDeleteFile("libEGL.dll")
			WindowsDeleteFile("libstdc++-6.dll")
			WindowsDeleteFile("libwinpthread-1.dll")
			WindowsDeleteFile("libGLESv2.dll")
			WindowsDeleteFile("D3Dcompiler_47.dll")			
		ok
	# Check No Allegro
		if find(aOptions,"-noallegro")
			msg("Remove RingAllegro from target/windows")
			WindowsDeleteFile("allegro*.dll")
			WindowsDeleteFile("ring_allegro.dll")
			WindowsDeleteFile("FLAC.dll")	
			WindowsDeleteFile("freetype.dll")	
			WindowsDeleteFile("jpeg62.dll")	
			WindowsDeleteFile("libpng16.dll")	
			WindowsDeleteFile("ogg.dll")	
			WindowsDeleteFile("physfs.dll")	
			WindowsDeleteFile("theoradec.dll")	
			WindowsDeleteFile("vorbis.dll")	
			WindowsDeleteFile("vorbisfile.dll")	
			WindowsDeleteFile("zlib.dll")	
		ok
	# Check No OpenSSL
		if find(aOptions,"-noopenssl")
			msg("Remove RingOpenSSL from target/windows")
			WindowsDeleteFile("ring_openssl.dll")
			WindowsDeleteFile("ssleay32.dll")
			WindowsDeleteFile("libeay32.dll")
		ok
	# Check No LibCurl
		if find(aOptions,"-nolibcurl")
			msg("Remove RingLibCurl from target/windows")
			WindowsDeleteFile("ring_libcurl.dll")
			WindowsDeleteFile("ring_internet.dll")
			WindowsDeleteFile("libcurl.dll")
		ok	
	# Check No MySQL
		if find(aOptions,"-nomysql")
			msg("Remove RingMySQL from target/windows")
			WindowsDeleteFile("ring_mysql.dll")
			WindowsDeleteFile("libmysql.dll")
		ok
	# Check No SQLite 
		if find(aOptions,"-nosqlite")
			msg("Remove RingSQLite from target/windows")
			WindowsDeleteFile("ring_sqlite.dll")
		ok
	# Check No ODBC
		if find(aOptions,"-noodbc")
			msg("Remove RingODBC from target/windows")
			WindowsDeleteFile("ring_odbc.dll")
		ok
	# Check No FreeGLUT
		if find(aOptions,"-nofreeglut")
			msg("Remove RingFreeGLUT from target/windows")
			WindowsDeleteFile("ring_freeglut.dll")
			WindowsDeleteFile("freeglut.dll")
			WindowsDeleteFile("glew32.dll")
		ok
	# Check No OpenGL 
		if find(aOptions,"-noopengl")
			msg("Remove RingOpenGL from target/windows")
			WindowsDeleteFile("ring_opengl*.dll")
		ok
	# Check No RingLibZip
		if find(aOptions,"-nolibzip")
			msg("Remove RingLibZip from target/windows")
			WindowsDeleteFile("ring_libzip.dll")
		ok
	# Check No RingConsoleColors
		if find(aOptions,"-noconsolecolors")
			msg("Remove RingConsoleColors from target/windows")
			WindowsDeleteFile("ring_consolecolors.dll")
		ok
	# Check No C Runtime
		if find(aOptions,"-nocruntime")
			msg("Remove C Runtime from target/windows")
			WindowsDeleteFile("msvc*.dll")
			WindowsDeleteFile("libgcc_s_dw2-1.dll")
		ok

func WindowsDeleteFolder cFolder
	systemSilent("rd /s /q " + cFolder)

func WindowsCopyFolder cFolder
	cParentFolder = currentdir()
	CreateOpenFolder(cFolder)
	systemsilent("copy " + exefolder()+cFolder)
	chdir(cParentFolder)

func WindowsDeleteFile cFile 
	systemSilent("del " + cFile)

func Distribute_For_Linux cBaseFolder,cFileName,aOptions
	CreateOpenFolder(:linux)

func Distribute_For_MaxOSX cBaseFolder,cFileName,aOptions
	CreateOpenFolder(:macosx)
