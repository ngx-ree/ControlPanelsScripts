// settings.lib.ks by ngx

// Library 'settings.lib.ks' provides various common variables and values which can be used for initial script settings, like initial GUI screen positions, terminal dimensions etc.
// Settings can be saved in files, which can be either common for all scripts, or specific per script or per vessel-script.
// Particular settings files can either be manually copied and edited or partially managed by 'mkl.ks' script (BETA!)

parameter mkdir is true. // Should this library create ship configuration directory if it does not exist? Set to FALSE for script 'mkl.ks' which should not create and use 'shipdir'.

global shipdir is ship:name. // Variable 'shipdir' contains the name of the subdirectory within the 'etc' subdirectory, where files related to script+ship are stored. It must be set to ship's name. This variable is also used for saving PID values or other values using 'ldsv.lib.ks' library.
if mkdir and not exists("etc/"+shipdir+"/") {createdir("etc/"+shipdir+"/").}. // Create ship's subdirectory if not present and the running script didn't call this library with the FALSE parameter.

global guiposfile is "etc/"+shipdir+"/"+ship:name+"_"+scriptid+"_guipos.json". // Default location for GUI positions file.

// Lexicon 'currsets' contains current settings for various GUI elements (or possibly other variables if needed).
global currsets is lexicon(
"mainx",list(1920,"Maximum X screen resolution"),
"mainy",list(1200,"Maximum Y screen resolution"),
"ctrlx",list(0,"Basic control panel X"), // Computed later below this lexicon, based on other setting values.
"ctrly",list(100,"Basic control panel Y"),
"ctrlw",list(200,"Basic control panel width"),
"ctrlm1x",list(0,"Multipanel 'controls1' X"), // Computed later below this lexicon, based on other setting values.
"ctrlm1y",list(0,"Multipanel 'controls1' Y"), // Computed later below this lexicon, based on other setting values.
"ctrlm1w",list(400,"Multipanel 'controls1' width"),
"ctrlm2x",list(0,"Multipanel 'controls2' X"), // Computed later below this lexicon, based on other setting values.
"ctrlm2y",list(0,"Multipanel 'controls2' Y"), // Computed later below this lexicon, based on other setting values.
"ctrlm2w",list(440,"Multipanel 'controls2' width"),
"inpx",list(0,"Input pane X"), // Computed later below this lexicon, based on other setting values.
"inpy",list(0,"Input pane Y"), // Computed later below this lexicon, based on other setting values.
"popmx",list(0,"Popup (and Y/N) message X"), // Computed later below this lexicon, based on other setting values.
"popmy",list(0,"Popup (and Y/N) message Y"), // Computed later below this lexicon, based on other setting values.
"popmw",list(200,"Popup (and Y/N) message width"),
"popmsg:text:color",list(white,"Initial text color for pop messages"),
"ynmsg:text:color",list(white,"Initial text color for pop messages"),
"minpx",list(0,"Minipanel X"), // Computed later below this lexicon, based on other setting values.
"minpy",list(0,"Minipanel Y"), // Computed later below this lexicon, based on other setting values.
"minpw",list(200,"Minipanel width"),

"guibox",list(list(0,1),"Basic gui box style; heading,pane; 0-layout, 1-box"),
"ctrlmbox",list(list(0,1),"Multipanel box style; heading,pane; 0-layout, 1-box"),
"mpbox",list(list(0,1),"Minipanel box style; heading,pane; 0-layout, 1-box"),
"popbox",list(list(0,1),"Pop message box style; heading,pane; 0-layout, 1-box"),
"ynbox",list(list(0,1),"y/n message box style; heading,pane; 0-layout, 1-box"),

"terminal:width",list(70,"Terminal window width"),
"terminal:height",list(25,"Terminal window height"),
"tclmn1",list(0,"Terminal window column 1"),
"tclmn2",list(20,"Terminal window column 2"),
"tclmn3",list(40,"Terminal window column 3"),

"confsave",list(true,"Confirm save overwrite?"),
"confload",list(false,"Confirm load?"),
"askexit",list(true,"Confirm exit script?"),

"test1",list(true,"testing 1"),
"test2",list(list(1,2),"testing 2"),
"test3",list(list("zzz",2,8),"testing 3"),
"test4",list(list(1,true),"testing 4")
).

// The following expressions set up various setting values relative to other values, such as screen resolution dimensions.
set currsets["ctrlx"][0] to currsets["mainx"][0]-(currsets["ctrlw"][0]*1.50). // Initial X position for basic control panel is at screen's max X minus 150% of control panel's width.
set currsets["ctrlm1x"][0] to currsets["mainx"][0]*0.05. // Initial X position of first control multipanel is at 5% of screen's max X.
set currsets["ctrlm1y"][0] to currsets["mainy"][0]*0.1. // Initial Y position of first control multipanel is at 10% of screen's max Y.
set currsets["ctrlm2x"][0] to currsets["mainx"][0]-(currsets["ctrlm2w"][0]*1.3). // Initial X position of second control multipanel is offset from right screen edge at 130% of the control panel's width.
set currsets["ctrlm2y"][0] to currsets["mainy"][0]*0.3. // Initial Y position of second control multipanel is 30% from screen's bottom (mainy).
set currsets["inpx"][0] to (currsets["mainx"][0]/3).// Initial X position of input pane is at 1/3 of screen's max X.
set currsets["inpy"][0] to (currsets["mainy"][0]/3)*0.6.// Initial Y position of input pane is at 60% of one-third of screen height from bottom.
set currsets["popmx"][0] to (currsets["mainx"][0]/2)-(currsets["popmw"][0]/2). // etc...
set currsets["popmy"][0] to (currsets["mainy"][0]/2).
set currsets["minpx"][0] to (currsets["mainx"][0]/2)-(currsets["minpw"][0]/2).
set currsets["minpy"][0] to (currsets["mainy"][0]/2).

// Load settings from file(s) if settings file(s) exist.
for sf in getsfiles() {
	if exists(sf) {
		local sset is readjson(sf).
		for s in sset:keys {
			set currsets[s] to sset[s].
		}
	}
	else {print "no such file: "+sf.}
}

// 'scrposlex' lexicon stores GUIs screen positions. Position is stored before a given GUI is deconstructed by the 'killgui' function (in 'screen.lib.ks').
global scrposlex is lexicon().

// Function 'loadguipos' loads saved GUI positions.
function loadguipos {
	parameter gpos is guiposfile.
	if exists(gpos) {
		set scrposlex to readjson(gpos).
		// terminal window width/height dimensions
		if scrposlex:haskey("terminal:width") and scrposlex:haskey("terminal:height") {
			set terminal:width to scrposlex["terminal:width"].
			set terminal:height to scrposlex["terminal:height"].
		}
		else {
			set terminal:width to currsets["terminal:width"][0].
			set terminal:height to currsets["terminal:height"][0].
		}
	}
}

// Function 'getsfiles' returns paths for each settings file.
function getsfiles {
	parameter scrid is scriptid.
	parameter shname is ship:name.
	parameter shdir is shipdir.
	local globsfile is "etc/"+"all_settings.json".
	local scriptfile is "etc/"+scrid+"_settings.json".
	local shipsfile is "etc/"+shdir+"/"+shname+"_"+scrid+"_settings.json".
	return list(globsfile,scriptfile,shipsfile).
}

// Updates status message line, sends message to other terminal if required, and prints message if logwindow is used.
// global variables used:
// termlog - If TRUE, message is sent to other terminal window, specified by 'cpuid'
// cpuid - kOS name tag of other kOS CPU on vessel where log messages can be sent.
// curtime - Elapsed seconds from script's start.
// logwindow - If TRUE, the starting terminal window is in 'log' mode and will print the message.
global function statmsg {
	parameter m. // Message string
	parameter cpid is "controls1". // ID of controls multipanel where message line is created
	local timepfx is round(curtime,1)+":".
	if defined msglex and msglex:haskey(cpid) {
		local prevtxt is msglex[cpid]["msg"]:text.
		local msgline is timepfx+m+"; "+prevtxt.
		set msglex[cpid]["msg"]:text to msgline:substring(0,min(msglex[cpid]["length"],msgline:length)).
	}
	if defined termlog and termlog {
		sendmsg(cpuid,timepfx+m).
	}
	if defined logwindow and logwindow {
		print round(curtime,1)+":"+m.
	}
}

// Sends log message to another terminal.
// global variables used:
// menucpu - popup menu whose value is the id (KOS name tag) of the KOS log destination terminal.
function sendmsg {
	parameter koscpu is menucpu:value. // kOS name tag where messages should be sent
	parameter msg is "".
	if koscpu<>"" and not ship:partsdubbed(koscpu):empty {
		local cpu is processor(koscpu).
		cpu:connection:sendmessage(msg).
	}
}

// For terminal logs, do we have more CPUs?
function hasmorecpu {
	return (SHIP:MODULESNAMED("kOSProcessor"):length()>1).
}

global lexcleanup is list(). // List of lexicons that need to be cleared on the script's exit.
// Function 'exit_cleanup', usually called on the script's exit, cleans lexicons and disposes of all GUIs (one by one, not just 'clearguis()').
// If you want a user lexicon to be cleared, add it to the 'lexcleanup' list after its initialization.
// global variables used:
// savepos - true/false; if true, GUI positions are saved
function exit_cleanup {
	parameter gpos is guiposfile.
	statmsg("script "+scriptid+" clean exit").
	CLEARVECDRAWS().
	if defined guilex {
		for guiid in guilex:keys {
			killgui(guiid).
		}
	}

	if defined ctrlbase {ctrlbase:dispose().}.

	set scrposlex["terminal:width"] to terminal:width.
	set scrposlex["terminal:height"] to terminal:height.

	if defined savepos and savepos {
		writejson(scrposlex,gpos).
	}

	// Destroy all user defined lexicons (if added to 'lexcleanup').
	for lex in lexcleanup {
		unset lex.
	}
	// Destroy global lexicons declared in libraries
	unset lexcleanup.
	unset scrposlex.
	unset ctrlpanlex.
	unset guilex.
	unset glinlex.
	unset mpCombolex.
	unset ctrlCombolex.
	unset setVallex.
	unset mchnrlex.
	unset valboxlex.
	unset msglex.
	unset minguilex.
	unset input_data.
	unset input_fnc.
	unset savvals.
	unset currsets.
}