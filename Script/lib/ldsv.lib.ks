// ldsv.lib.ks by ngx

// This library contains functions for saving and loading various files (like PID parameters or inputs).
// Saving/loading of files is based on the 'savvals' lexicon, which is the lexicon being saved ('writejson') or loaded ('readjson'). Processing of variables-lexicon relations is done by the 'savvalssave' and 'savvalsload' functions in the main script.

declare parameter savfile to "etc/"+shipdir+"/"+ship:name+"_"+scriptid+"_PID.save.". // By default, we will save/load PID parameters. If it is something different, the name of 'savfile' will be set accordingly using this parameter.

global savvals is lexicon(). // Create global 'savvals' lexicon for loading/saving values. The lexicon is handled in the main script.
global savvalsfile is savfile. // Default value of globally accessible 'savvalsfile'.
global savsuffix is "default". // Value to be appended to savvalsfile, typically the name of saved/loaded preset.
global savsel is "". // Currently selected preset (suffix).
global confsave is currsets["confsave"][0]. // Default value of 'Confirm save overwrite' checkbox.
global confload is currsets["confload"][0]. // Default value of 'Confirm load' checkbox.

// Function 'makesave' performs a basic save of the 'savvals' lexicon into a .json file with the required filename. Before the actual save it calls the 'savvalssave' function (in the main script) which must provide the 'savvals' lexicon with required structure and values.
function makesave {
	parameter p1 is savsuffix.
	parameter p2 is savvalsfile.
	savvalssave(). // This function must be present in main script, it stores data (to be saved) into 'savvals' lexicon.
	statmsg("saving: "+p2+p1+".json").
	writejson(savvals,p2+p1+".json").
}

// Function 'makeload' performs a basic load of values from a .json file into the 'savvals' lexicon. After loading it calls the 'savvalsload' function (defined in the main script) which then moves the loaded 'savvals' values into the actual variables in the main script (and performs other processing if necessary).
function makeload {
	parameter p1 is savsuffix.
	parameter p2 is savvalsfile.
	statmsg("loading: "+p2+p1+".json").
	set savvals to readjson(p2+p1+".json").
	savvalsload().// This function must be present in main script, it gets data from stored .json and processes them further to variables.
}

// Function 'chkpreset' loads preset (and/or saves default preset if it does not exist), usually after the main script starts.
function chkpreset {
	parameter ldprs is false.
	parameter preset is "". // Name of the preset to be loaded.
	set savsuffix to "default".
	if not exists(savvalsfile+savsuffix+".json") {
		makesave().
	}
	if ldprs {
		if preset <> "" {
			if exists(savvalsfile+preset+".json") {
				set savsuffix to preset.
			}
			else {
				popmsg(list("No such preset ("+preset+").","Using default."),red).
			}
			makeload().
		}
	}
	set savsel to savsuffix.
}

// Function 'savrefresh' fills the options of a popup menu identified by 'menufiles' with preset identifiers from a given directory specified by 'shdir'.
function savrefresh {
	parameter menufiles. // ID of popup menu whose options should be filled.
	parameter shdir is shipdir. // Directory where files are searched for.
	parameter svfile is savvalsfile. // Base of save/load file name.

	local srchstr is svfile:substring((4+shdir:length()+1),svfile:length-(4+shdir:length()+1)).
	local extlist is listfiles("etc/"+shdir+"/",srchstr).
	menufiles:clear().
	for f in extlist {
		if f:endswith(".json") {
			menufiles:add(f:substring(f:findlast(".save")+6,(f:findlast(".json")-(f:findlast(".save")+6)))).
		}
	}
}

// Function 'listfiles' returns a list of files in a given directory according to search criteria.
function listfiles {
	parameter dir. // Directory to be searched through.
	parameter substr. // String used in search function.
	parameter sfnc is { // Search function. By default, searches for 'substr' substring in the file's name.
		parameter f.
		parameter s.
		return f:contains(s).
	}.

	local finlist is list().
	local tgtdir is open(dir).

	for f in tgtdir:list:keys {
		if sfnc(f,substr) {
			finlist:add(f).
		}
	}
	return finlist.
}

// Function 'saveload' creates GUI combo with essential elements for controlling saving/loading functions. Typically it is called/dismissed by 'toggle' type button.
function saveload {
	parameter tog. // If TRUE, combo is created. If FALSE, combo is discarded.
	parameter atx is currsets["minpx"][0]. // Initial X screen position.
	parameter aty is currsets["minpy"][0]. // Initial Y screen position.
	parameter hastrnexp is true. // If TRUE, 'Export' and 'Transfer' buttons are created.
	parameter guiid is "saveloadctrl". // Save/Load control's GUI ID, by default 'saveloadctrl'.
	parameter shdir is shipdir. // Directory where file is saved and loaded from.
	parameter savsfx is savsuffix. // Suffix of save file (before '.json').
	parameter savvalsf is savvalsfile. // Base of save/load file name.
	parameter mksave is makesave@. // Function called for the saving process. By default, the 'makesave' function defined in this library.
	parameter mkload is makeload@. // Function called for the loading process. By default, the 'makeload' function defined in this library.

	if tog {
		minipanel(guiid,"Save/Load",true,200,atx,aty,list(true,true)).
		mpComboTog(guiid,"Save",false,{
			parameter tog.
			set mpCombolex[guiid]["items"]["filename"]["textfld"]:text to savsfx.
			set mpCombolex[guiid]["items"]["filename"]["textfld"]:enabled to tog.
			set mpCombolex[guiid]["items"]["filepopup"]["menu"]:enabled to not tog.
			set mpCombolex[guiid]["items"]["Load"]["pbtn"]:enabled to not tog.
			set mpCombolex[guiid]["items"]["Delete"]["pbtn"]:enabled to not tog.
			if mpCombolex[guiid]["items"]:haskey("Export") {set mpCombolex[guiid]["items"]["Export"]["pbtn"]:enabled to not tog.}.
			if mpCombolex[guiid]["items"]:haskey("Transfer") {set mpCombolex[guiid]["items"]["Transfer"]["pbtn"]:enabled to not tog.}.
			return "Save".
		},"Saves the current values. Press the button to enable the textfield to the right and enter the preset's name (or leave the old one to overwrite the existing preset). Then confirm by pressing ENTER (or by clicking outside of the textfield) to save the preset." ).
		set mpCombolex[guiid]["items"]["Save"]["tbtn"]:style:width to 60.

		mpComboText(guiid,"filename",{
			parameter str.
				if mpCombolex:haskey(guiid) and mpCombolex[guiid]["items"]["filename"]["textfld"]:enabled {
				local function dosave {
					mksave(savsfx,savvalsf).
					savrefresh(mpCombolex[guiid]["items"]["filepopup"]["menu"]:options,shdir,savvalsf).
					set mpCombolex[guiid]["items"]["filepopup"]["menu"]:index to mpCombolex[guiid]["items"]["filepopup"]["menu"]:options:indexof(savsfx).
					set mpCombolex[guiid]["items"]["Save"]["tbtn"]:pressed to false.
				}
				if str="" {
				}
				else {
					set savsfx to str.
					set savsuffix to savsfx.
					if exists (savvalsf+savsfx+".json") and confsave {
						ynmsg(list("Overwrite '"+savsfx+"'?"),red,{
							dosave().
						},
						{
							set mpCombolex[guiid]["items"]["Save"]["tbtn"]:pressed to false.
						},false).
					}
					else {
						dosave().
					}
				}
			}

		},"",false).
		set mpCombolex[guiid]["items"]["filename"]["textfld"]:enabled to false.

		mpComboMenu(guiid,"filepopup",{
			parameter sel.
			set savsel to sel.
		},list(),"Selects an existing saved preset.").

		mpComboBtn(guiid,"Load",{
			local function doload {
				set savsfx to savsel.
				set savsuffix to savsfx.
				mkload(savsfx,savvalsf).
				set mpCombolex[guiid]["items"]["filename"]["textfld"]:text to savsfx.
			}
			set savsel to mpCombolex[guiid]["items"]["filepopup"]["menu"]:value.
			if exists (savvalsf+savsel+".json") {
				if confload {
					ynmsg(list("Load "+savsel+"?"),rgb(0.6,0.7,1),{
						doload().
					},
					{},false).
				}
				else {
					doload().
				}
			}
			else {
				popmsg(list("No such preset ("+savsel+")."),red).
			}
		},"Loads the selected preset.").
		set mpCombolex[guiid]["items"]["filename"]["textfld"]:text to savsfx.

		mpComboBtn(guiid,"Delete",{
			local function dodelete {
				local delindex is max(mpCombolex[guiid]["items"]["filepopup"]["menu"]:options:indexof(savsel)-1,0).
				statmsg("deleting: "+savvalsf+savsel+".json").
				deletepath(savvalsf+savsel+".json").
				savrefresh(mpCombolex[guiid]["items"]["filepopup"]["menu"]:options,shdir,savvalsf).
				set mpCombolex[guiid]["items"]["filepopup"]["menu"]:index to delindex.
			}
			if exists (savvalsf+savsel+".json") {
				ynmsg(list("Delete "+savsel+"?"),red,
				{
					dodelete().
				},
				{
				},
				false).
			}
			else {
				popmsg(list("No such preset ("+savsel+")."),red).
			}
		},"Deletes the selected preset.",false).

		if hastrnexp {
			mpComboBtn(guiid,"Export",{
				local exportfile is savvalsf+savsel+".export".
				local function doexport {
					exportPIDs(exportfile).
					popmsg(list("Exported ("+savsel+")."),green).
				}
				if exists (savvalsf+savsel+".json") {
					ynmsg(list("Export "+savsel+"?"),rgb(0.6,0.7,1),{
						if exists (exportfile) {
							ynmsg(list("Overwrite '"+savsel+"' export?"),red,{
								doexport().
							},
							{},false).
						}
						else {
							doexport().
						}
					},
					{},false).
				}
				else {
					popmsg(list("No such PID preset ("+savsel+")."),red).
				}
			},"BETA: Exports the selected preset into a .ks file. The export creates a file that can be used with the 'runoncepath' command as a template for PID parameters. All keys from the 'savvals' lexicon are exported. See the 'exportPIDs' function in the 'ldsv.lib.ks' library for creating optional automatic comments in the exported file.").
			mpComboBtn(guiid,"Transfer",{
				local expsufx is list(".json",".export").
				for expsfx in expsufx {
					local trxsfx is expsfx.
					if exists (savvalsf+savsel+trxsfx) {
						ynmsg(list("Transfer "+savsel+trxsfx),rgb(0.6,0.7,1),{
							local ffile is "1:"+savvalsf+savsel+trxsfx.
							local tfile is "0:"+savvalsf+savsel+trxsfx.
							local function dotransfer {
								copypath(ffile,tfile).
								popmsg(list("Transferred ("+ffile+")."),green).
							}
							if not exists (ffile) {
								popmsg(list("File ("+ffile+") not found.","Either the file is not exported, or script does not run from the local volume."),red,{},300).
							}
							else {
								if not homeconnection:isconnected {
									popmsg(list("Archive not accessible."),red).
								}
								else {
									if exists (tfile) {
									ynmsg(list("Overwrite '"+tfile+"' transfer file?"),red,{
										dotransfer().
									},
									{},false).
									}
									else {
										dotransfer().
									}
								}
							}
						},
						{},false).
					}
					else {
						popmsg(list("No such file ("+savvalsf+savsel+trxsfx+")."),red).
					}
				}

			},"BETA: Copies files corresponding to the selected preset from the local volume to the archive in the 'etc/shipdir' directory. 'shipdir' refers to the current ship's name. Transfers preset.json and preset.export files if they exist.",false).
		}
		savrefresh(mpCombolex[guiid]["items"]["filepopup"]["menu"]:options,shdir,savvalsf).
		set mpCombolex[guiid]["items"]["filepopup"]["menu"]:index to mpCombolex[guiid]["items"]["filepopup"]["menu"]:options:indexof(savsfx).
	}
	else {
		killgui(guiid).
	}
}



// BETA!
// Function exports loaded PID values into a .ks file which can be loaded into the main script by the 'runoncepath' command.
// The function exports all the keys in 'savvals' lexicon, assuming they comply with 'global "key" is SCALAR' structure.
// local exportfile is savvalsfile+savsuffix+".export".

// If some lines or sections should be commented, use the 'commentlex' lexicon to define the required comment.
// "//" - Writes the comment after the line containing the "key".
// "///" - Writes a new line and then the comment from the beginning of the section which begins with the "key".
// "////" - Writes a new line and then the comment after the line containing the "key".
// For example, '"tfkp","/// throttle forward",' entry will create something like:
// 		// throttle forward
//		global tfkp is 0.05.
//		global tfki is 0.006.
//		global tfkd is 0.06.
//		global tfeps is 0.
// when tfkp, tfki, tfkd and tfeps are written in 'savvals' lexicon in this order.
function exportPIDs {
	parameter exportfile.
	local commentlex is lexicon( // all PIDs parameters to be exported with comment must be listed here. If there's no such entry, the exported parameter will not be commented.
		"tfkp","/// throttle forward",
		"vvelkp","/// vertical velocity",
		"fwdkp","/// forward velocity",
		"sidkp","/// lateral velocity",
		"rllkp","/// roll angle",
		"ywkp","/// yaw angle",
		"ptchkp","/// pitch angle",
		"jyangkp","/// joystick angle"//,

		// "tfki","/// throttle forward",
		// "vvelki","/// vertical velocity",
		// "fwdki","/// forward velocity",
		// "sidki","/// lateral velocity",
		// "rllki","/// roll angle",
		// "ywki","/// yaw angle",
		// "ptchki","/// pitch angle",
		// "jyangki","/// joystick angle",

		// "tfkd","/// throttle forward",
		// "vvelkd","/// vertical velocity",
		// "fwdkd","/// forward velocity",
		// "sidkd","/// lateral velocity",
		// "rllkd","/// roll angle",
		// "ywkd","/// yaw angle",
		// "ptchkd","/// pitch angle",
		// "jyangkd","/// joystick angle",

		// "tfeps","/// throttle forward",
		// "vveleps","/// vertical velocity",
		// "fwdeps","/// forward velocity",
		// "sideps","/// lateral velocity",
		// "rlleps","/// roll angle",
		// "yweps","/// yaw angle",
		// "ptcheps","/// pitch angle",
		// "jyangeps","/// joystick angle",

		// "plim","//// pitch limitation multiplier",
		// "rlim","// roll limitation multiplier",
		// "ywlim","// yaw limitation multiplier",
		// "fblim","// forward-backward limitation multiplier",
		// "sbdlim","// starboard limitation multiplier",
		// "angywdamp","// yaw angvel dampener multiplier",
		// "angptchdamp","// pitch angvel dampener multiplier",
		// "angrlldamp","// roll angvel dampener multiplier",

		// "fwdskp","/// forward velocity by surfaces",
		// "sidskp","/// lateral velocity by surfaces",
		// "rllskp","/// roll angle by surfaces",
		// "ywskp","/// yaw angle by surfaces",
		// "ptchskp","/// pitch angle by surfaces",

		// "pslim","//// pitch by surfaces limitation multiplier",
		// "rslim","// roll by surfaces limitation multiplier",
		// "ywslim","// yaw by surfaces limitation multiplier",
		// "fbslim","// forward-backward by surfaces limitation multiplier",
		// "sbdslim","// starboard by surfaces limitation multiplier",

		// "rllhkp","/// roll angle by hinges",
		// "ptchhkp","/// pitch angle by hinges",

		// "stkp","/// wheels steer, runway",
		// "qkp","/// dynamic pressure check"

	).

	statmsg("exporting: "+exportfile).
	if exists(exportfile) {deletepath(exportfile).}.
	log "// exported "+savvalsfile+savsuffix to exportfile.
	savvalssave().
	for pidkey in savvals:keys {
		local comment is "".
		if commentlex:haskey(pidkey) {
			local lncomment is commentlex[pidkey].
			if lncomment:contains("////") {
				log "" to exportfile.
				set lncomment to lncomment:replace("////","//").
				set comment to " "+lncomment.
			}
			else if lncomment:contains("///") {
				set lncomment to lncomment:replace("///","//").
				log "" to exportfile.
				log lncomment to exportfile.
			}
			else {
				set comment to " "+lncomment.
			}
		}
		log "global "+pidkey+" is "+savvals[pidkey]+"."+comment to exportfile.
	}
}

// This function creates a button for toggling GUI elements combo providing save/load related operations.
function svldbtn {
	parameter btnbox.
	parameter btnlab is "Preset: ".

	global btnlabel is btnlab.
	global saveloadbtn is btnbox:addbutton(btnlabel+savsuffix).
	set saveloadbtn:style:align to "center".
	set saveloadbtn:style:width to 130.
	set saveloadbtn:toggle to true.
	// 'ontoggle' must be defined and called from the main script due to the 'pin position' function (combo's initial position must be set from the main script).
	return saveloadbtn.
}

// This function creates checkboxes for save overwrite confirmation and load confirmation.
function savldconf {
	parameter confbox.

	local saveconfchb is confbox:addcheckbox("Confirm save overwrite",confsave).
	set saveconfchb:toggle to true.
	set saveconfchb:ontoggle to {
		parameter tog.
		set confsave to tog.
	}.

	local loadconfchb is confbox:addcheckbox("Confirm load",confload).
	set loadconfchb:toggle to true.
	set loadconfchb:ontoggle to {
		parameter tog.
		set confload to tog.
	}.

	return list(saveconfchb,loadconfchb).
}

// This trigger handles changes to the 'savsuffix' value, for example during selection of a preset to be loaded or setting a preset to be saved.
on savsuffix {
	if defined saveloadbtn {set saveloadbtn:text to btnlabel+savsuffix.}.
	return true.
}