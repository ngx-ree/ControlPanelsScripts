// mkl.ks by ngx

@lazyglobal off.
global scriptid is "mkl".
declare parameter preset to "last".
runoncepath("lib/settings.lib.ks",false). // argument 'false' means ship's configuration directory will not be created by running this script.
runoncepath("lib/common.lib.ks").
runoncepath("lib/screen.lib.ks").
runoncepath("lib/ldsv.lib.ks","etc/MKLOCS.save.").

clearscreen.
clearguis().
loadguipos("0:etc/"+scriptid+"_guipos.json"). // Use non-default GUI positions file

global starttime is time:seconds.
lock curtime to time:seconds-starttime.

global scriptend is false.
global savepos is true.
global filelist is list().

// List of CP libraries 'lib' directory. This prevents copying different library files, possibly created before CP scripts installation.
global cplibs is list(
"common.lib.ks",
"ctrlpanel.lib.ks",
"ldsv.lib.ks",
"orbital.lib.ks",
"screen.lib.ks",
"settings.lib.ks"
).

global locfs is 1.
global vollist is list().
list volumes in vollist.
global volopts is list().
global vollex is lexicon().
global volnams is lexicon().
from {local vo is 1.} until vo>(vollist:length-1) step {set vo to vo+1.} do {
	local vnm is volume(vo):name.
	if vnm="" {set vnm to vo+":".}.
	vollex:add(vnm,vo).
	volnams:add(vo,vnm).
	volopts:add(vnm).
}
global mklcpgs is list(1,10,1).
global setspgs is list(1,10,1).

global locfiles to lexicon().
lexcleanup:add(locfiles).
global mklcheck is lexicon().
lexcleanup:add(mklcheck).

global cpopts is lexicon(
"clretc", true,
"cpetc",true,
"cplib",true,
"cpsets",false
).
global savlex is lexicon().

ctrlmpanel("controls1",ship:name+": "+core:tag,list("make local files","settings"),true,true,60,currsets["ctrlm1x"][0],currsets["ctrlm1y"][0]).

{ //GUI
/// FILES
{
local ldsvset is ctrlpanlex["controls1"]["make local files"]:addhbox().

local saveloadbtn1 is svldbtn(ldsvset).
set saveloadbtn1:ontoggle to {
	parameter tog.
	saveload(tog,guilex["controls1"]:x-200,guilex["controls1"]:y,false,"svldmkl","").
}.

local confset is savldconf(ldsvset).
global saveconfchb1 is confset[0].
global loadconfchb1 is confset[1].

local clretcset is ctrlpanlex["controls1"]["make local files"]:addhbox().
global clretcchb is clretcset:addcheckbox("Clear 'etc'",false).
set clretcchb:tooltip to "If FALSE, the local 'etc/' directory and its contents are preserved and not overwritten by newer ones from the archive. Preservation is useful, for example, when updating a script with patches or a newer version while still using locally created saves and configurations. If TRUE, the ship's local volume 'etc/' directory is deleted with all its contents before copying files from the archive and is replaced with the archive's 'etc/'.".
set clretcchb:toggle to true.
set clretcchb:ontoggle to {
	parameter tog.
	set cpopts["clretc"] to tog.
}.
set clretcchb:pressed to cpopts["clretc"].
global cpetcchb is clretcset:addcheckbox("Copy 'etc'",false).
set cpetcchb:tooltip to "If FALSE, the 'etc/' directory from the archive will not be copied to the ship's local volume. Useful for scripts that do not use the 'etc/' directory structure.".
set cpetcchb:toggle to true.
set cpetcchb:ontoggle to {
	parameter tog.
	set cpopts["cpetc"] to tog.
}.
set cpetcchb:pressed to cpopts["cpetc"].
global cplibchb is clretcset:addcheckbox("Copy 'lib'",false).
set cplibchb:tooltip to "If FALSE, the 'lib/' directory from the archive will not be copied to the ship's local volume. Useful for scripts that do not use the 'lib/' directory structure.".
set cplibchb:toggle to true.
set cplibchb:ontoggle to {
	parameter tog.
	set cpopts["cplib"] to tog.
}.
set cplibchb:pressed to cpopts["cplib"].
global cpsetschb is clretcset:addcheckbox("Copy settings",false).
set cpsetschb:tooltip to "If TRUE, settings files (common, script's, and script+ship's) are also copied if found on the archive volume.".
set cpsetschb:toggle to true.
set cpsetschb:ontoggle to {
	parameter tog.
	set cpopts["cpsets"] to tog.
}.
set cpsetschb:pressed to cpopts["cpsets"].

local pgbox2 is ctrlpanlex["controls1"]["make local files"]:addhlayout().
global filesbox is ctrlpanlex["controls1"]["make local files"]:addvbox().
paging(pgbox2,mklcpgs[0],mklcpgs[1],mklcpgs[2],makedlg@).
global clrselbtn is pgbox2:addbutton("Uncheck").
set clrselbtn:tooltip to "Unchecks all checkboxes, thereby deselecting all selected files.".
set clrselbtn:onclick to {
	ynmsg(list("Uncheck all files?"),red,{
		for f1 in mklcheck:keys {
			set mklcheck[f1][0] to false.
		}
		makedlg(mklcpgs[0],mklcpgs[1],mklcpgs[2]).
	},{}).
}.

global refrshbtn is pgbox2:addbutton("Refresh").
set refrshbtn:tooltip to "Refreshes the file list, useful for example when kOS scripts are added to or deleted from the archive.".
set refrshbtn:onclick to {
	makedlg(mklcpgs[0],mklcpgs[1],mklcpgs[2]).
}.

local spacing is ctrlpanlex["controls1"]["make local files"]:addhlayout().
local space is spacing:addlabel().
set space:style:height to 10.

local btmbuttons is ctrlpanlex["controls1"]["make local files"]:addhlayout().
global fsselmenu is btmbuttons:addpopupmenu().
set fsselmenu:tooltip to "Selects the ship's filesystem from all available kOS volumes. The selected volume will be the target for file copying.".
set fsselmenu:options to volopts.
set fsselmenu:onchange to {
	parameter sel.
	set locfs to vollex[sel].
	set mklocbtn:text to "Copy to "+cutvnm().
	set listlocbtn:text to "Show "+cutvnm().
	set dellocbtn:text to "Delete "+cutvnm().
	set quitbtn1:text to "Switch to "+volnams[locfs]+" and quit".
	set fsselmenu:text to cutvnm().
}.
set fsselmenu:index to fsselmenu:options:indexof(volnams[locfs]).

global mklocbtn is btmbuttons:addbutton("Copy to "+cutvnm()).
set mklocbtn:tooltip to "Copies selected files according to the selected options. Usually, corresponding saves and configurations ('etc/' contents) and libraries ('lib/' contents) are copied. NOTE: before copying, all files on the target volume are deleted, except for the 'boot/' directory and the 'etc/' directory if unchecked.".
set mklocbtn:onclick to {
	ynmsg(list("Copy files to "+volnams[locfs]+"?","Existing files on "+volnams[locfs]+" will be deleted!"),red,{
		print " ".// skip loop printing line
		filelist:clear().
		for lfile in locfiles:keys {
			if locfiles[lfile][0] {
				print "adding "+lfile.
				filelist:add(lfile).
			}
		}
		local mklok is makelocals().
		local reslex is lexicon(
			true,"DONE",
			false,"FAILED"
		).
		print "====== Copying to "+volnams[locfs]+" "+reslex[mklok]+" ======".
		if mklok {
				// popmsg(list("Files copy to "+volnams[locfs],"finished successfully."),green).
			}
			else {
				popmsg(list("Files copy to "+volnams[locfs]+" FAILED!","Check destination volume space."),red).
			}
	},{}).
}.

global listlocbtn is btmbuttons:addbutton("Show "+cutvnm()).
set listlocbtn:tooltip to "Recursively shows the contents (directories and files) of the selected local volume. The listing is paginated (like 'more' in unix/linux), and if a page is longer than the terminal's height, the terminal waits for a keypress (GUI does not react). NOTE: the terminal window must be active (i.e., selected) for the keypress to take effect".
set listlocbtn:onclick to {
	showdir(locfs,":").
}.

global dellocbtn is btmbuttons:addbutton("Delete "+cutvnm()).
set dellocbtn:tooltip to "Deletes the contents of the selected local volume, except for the 'boot/' directory.".
set dellocbtn:onclick to {
	ynmsg(list("Delete all files on "+volnams[locfs]+"?","(Except 'boot' directory)"),red,{
		print " ".// skip loop printing line
		local lfiles is open(locfs+":"):list().
		if lfiles:length=0 {
			print "no files on local FS".
		}
		else {
			for locfile in lfiles:keys {
				if locfile<>"boot" {
					print "deleting "+locfs+":"+locfile.
					deletepath(locfs+":"+locfile).
				}
				else {
					print "preserving 'boot' dir.".
				}
			}
		}
	},{}).
}.

local btmbuttons2 is ctrlpanlex["controls1"]["make local files"]:addhlayout().
global svlastbtn is btmbuttons2:addbutton("Save last selection").
set svlastbtn:tooltip to "Saves the current selection as the 'last' preset. This preset is loaded at the script's start if found. If the 'last' preset does not exist, the 'default' preset is loaded (or created) instead.".
set svlastbtn:onclick to {
	print "saving last selection".
	makesave("last").
}.
global clrsbtn is btmbuttons2:addbutton("Clear terminal screen").
set clrsbtn:tooltip to "Clears the screen of the terminal from which the 'mkl.ks' script was launched.".
set clrsbtn:onclick to {
	clearscreen.
}.
global listarchbtn is btmbuttons2:addbutton("Show Archive").
set listarchbtn:tooltip to "Recursively shows the contents (directories and files) of the archive volume. The listing is paginated (like 'more' in unix/linux), and if a page is longer than the terminal's height, the terminal waits for a keypress (GUI does not react). NOTE: the terminal window must be active (i.e., selected) for the keypress to take effect.".
set listarchbtn:onclick to {
	showdir(0,":").
}.

local btnset3 is ctrlpanlex["controls1"]["make local files"]:addhlayout().
global quitbtn1 is btnset3:addbutton("Switch to "+volnams[locfs]+" and quit").
set quitbtn1:tooltip to "Switches to the selected local ship's volume and ends the script.".
set quitbtn1:onclick to {
	print "switching to local fs".
	switch to locfs.
	set scriptend to true.
}.

global quitbtn2 is guilex["controls1"]:widgets[1]:addbutton("Just Quit").
set quitbtn2:tooltip to "Ends the script without doing anything else (remains on the active volume).".
set quitbtn2:onclick to {
	set scriptend to true.
}.
}
//// SETTINGS
{
local settspane is ctrlpanlex["controls1"]["settings"]:addhlayout().

local locscrid is "UNK".
local setspanev1 is settspane:addvbox().
local scridlab is setspanev1:addlabel("script ID").
set scridlab:tooltip to "The script ID: the script's name without the .ks extension.".
local scriddlg is setspanev1:addtextfield(locscrid). // script id
set scriddlg:onconfirm to {
	parameter str.
	if str="" {
		popmsg(list("Script ID cannot be empty."),red).
		set scriddlg:text to "UNK".
	}
	else {
		set locscrid to str.
		set setsfiles to getsfiles(locscrid,locshipid,locshipdir).
	}
	updlocs().
}.

local locshipid is ship:name.
local setspanev2 is settspane:addvbox().
local shipidlab is setspanev2:addlabel("ship ID").
set shipidlab:tooltip to "The ship ID: the ship's name.".
local shipiddlg is setspanev2:addtextfield(locshipid). // ship id
set shipiddlg:onconfirm to {
	parameter str.
	set locshipid to str.
	set setsfiles to getsfiles(locscrid,locshipid,locshipdir).
	updlocs().
}.

local locshipdir is locshipid.
local setspanev3 is settspane:addvbox().
local shipdirlab is setspanev3:addlabel("ship directory").
set shipdirlab:tooltip to "The ship configuration directory under 'etc/': the ship's name.".
local shipdirdlg is setspanev3:addtextfield(locshipdir). // ship dir
set shipdirdlg:onconfirm to {
	parameter str.
	set locshipdir to str.
	set setsfiles to getsfiles(locscrid,locshipid,locshipdir).
	updlocs().
}.
global setslex is lexicon().
local setsfiles is getsfiles(locscrid,locshipid,locshipdir).
global locsfile is setsfiles[0].
if exists(locsfile) {
	set setslex to readjson(locsfile).
}
else {
	popmsg(list("File "+locsfile+" not found.","Loading defaults."),white).
	set setslex to currsets.
}

local setsopts is list("Common","Script ID","Script+ship IDs").
local setspanev4 is settspane:addvbox().
local setsellab is setspanev4:addlabel("settings file").
set setsellab:tooltip to "Configuration file.
Common settings - all_settings.json, used when the next two files are missing.
Script settings - etc/'+scriptid+'_settings.json, specified by script ID, used for all scripts of a given ID if the file specified by ship ID is missing.
Script + ship settings - etc/'+shipdir+'/'+ship:name+'_'+scriptid+'_settings.json, specified by both ship and script IDs, located in the ship's directory".
local setselmenu is setspanev4:addpopupmenu().
set setselmenu:options to setsopts.
set setselmenu:onchange to {
	parameter sel.
	set setsfiles to getsfiles(locscrid,locshipid,locshipdir).
	updlocs().
}.
set setselmenu:index to 0.

local settspane1 is ctrlpanlex["controls1"]["settings"]:addhbox().
global fnamebox is settspane1:addlabel("filename: "+locsfile).
local function updlocs {
	set locsfile to setsfiles[setsopts:indexof(setselmenu:value)].
	set fnamebox:text to "filename: "+locsfile.
}

local settspane2 is ctrlpanlex["controls1"]["settings"]:addhlayout().
global settsbox is ctrlpanlex["controls1"]["settings"]:addvbox().
paging(settspane2,setspgs[0],setspgs[1],setspgs[2],setsdlg@).
local pgrefresh is settspane2:addbutton("Reload").
set pgrefresh:tooltip to "Reloads settings from the corresponding file. NOTE: this will revert all unsaved changes.".
set pgrefresh:onclick to {
	ynmsg(list("Reload file?","All unsaved changes will be lost."),red,{
		if exists(locsfile) {
			set setslex to readjson(locsfile).
		}
		else {

			set setslex to currsets.
		}
		setsdlg(setspgs[0],setspgs[1],setspgs[2]).
	},{}).
}.

local confirmset is settspane2:addbutton("Confirm/Save").
set confirmset:tooltip to "Confirms all changes and saves the corresponding file, overwriting the old one if found.".
set confirmset:onclick to {
	ynmsg(list("Confirm and save changes?","file: "+locsfile),rgb(0.6,0.7,1),{
		if exists(locsfile) {
			ynmsg(list("Overwrite existing file?",locsfile),red,{
				writejson(setslex,locsfile).
				statmsg("saving:"+locsfile).
			},{}).
		}
		else {
			statmsg("saving:"+locsfile).
			writejson(setslex,locsfile).
		}
	},{}).
}.

local deleteset is settspane2:addbutton("Delete").
set deleteset:tooltip to "Deletes the corresponding settings file.".
set deleteset:onclick to {
	if exists(locsfile) {
		ynmsg(list("Delete the "+locsfile+" file?"),red,{
			statmsg("deleting:"+locsfile).	
			deletepath(locsfile).
		},{}).
	}
	else {
		popmsg(list("File "+locsfile+" not found."),rgb(0.6,0.7,1)).
	}
}.
}
}

function cutvnm {
	parameter len is 6.
	local locn is volnams[locfs].
	if locn:length>len {
		local cvnm is locn:substring(0,len).
		if cvnm:length < locn:length {set cvnm to cvnm+".".}.
		return cvnm.
	}
	else {
		return locn.
	}
}

function getfiles {
	global kscripts is listfiles("",".ks",{
		parameter f.
		parameter s.
		return (f:endswith(s) and f<>"mkl.ks").
	}).
	locfiles:clear().
	for x1 in kscripts {
		local checked is false.
		local descr is "description".
		if mklcheck:haskey(x1) {
			set checked to mklcheck[x1][0].
			set descr to mklcheck[x1][1].
		}
		locfiles:add(x1,list(checked,descr)).
	}
}

function makedlg {
	parameter frm.
	parameter lines.
	parameter currpg.
	for f1 in filesbox:widgets {
		f1:dispose().
	}
	getfiles().
	local mklrray is list().
	for mklitem in locfiles:keys {
		mklrray:add(list(mklitem,locfiles[mklitem][0],locfiles[mklitem][1])).
		if not mklcheck:haskey(mklitem) {
			mklcheck:add(mklitem,list(locfiles[mklitem][0],locfiles[mklitem][1])).
		}
	}
	from {local lin is 1.} until (lin>lines or (frm+lin)>mklrray:length+1) step {set lin to lin+1.} do {
		local mklline is filesbox:addhbox().
		set mklline:style:height to 28.
		local lindex is (frm+lin)-2.
		local findex is mklrray[lindex][0].
		local mklchb is mklline:addcheckbox().
		set mklchb:toggle to true.
		set mklchb:ontoggle to {
			parameter tog.
			if not locfiles:haskey(findex) {locfiles:add(findex,list(false,"description")).}.
			set locfiles[findex][0] to tog.
			set mklcheck[findex][0] to tog.
		}.
		set mklchb:pressed to locfiles[findex][0].
		local lfilelab is mklline:addlabel(findex).
		set lfilelab:tooltip to locfiles[findex][1].
		set lfilelab:style:width to 100.
		local mkldesc is mklline:addtextfield(locfiles[findex][1]).
		set mkldesc:style:hstretch to true.
		set mkldesc:style:align to "right".
		set mkldesc:style:width to 300.
		set mkldesc:onconfirm to {
			parameter str.
			set locfiles[findex][1] to str.
			set mklcheck[findex][1] to str.
		}.
	}
	set mklcpgs to list(frm,lines,currpg).
	return ceiling(mklrray:length/lines).
}

function setsdlg {
	parameter frm.
	parameter lines.
	parameter currpg.
	local setrray is list().
	for setitem in setslex:keys {
		setrray:add(list(setitem,setslex[setitem][0],setslex[setitem][1])).
	}
	for f1 in settsbox:widgets {
		f1:dispose().
	}
	from {local lin is 1.} until (lin>lines or (frm+lin)>setrray:length+1) step {set lin to lin+1.} do {
		local setline is settsbox:addhbox().
		local lindex is (frm+lin)-2.
		local setpropln is setline:addlabel(setrray[lindex][0]:tostring()).
		set setpropln:tooltip to setrray[lindex][2].
		local setvalue is setrray[lindex][1].

		if setvalue:typename="RGBA" {
			set setvalue to rgbaln(setline,setvalue).
		}
		else if setvalue:typename="Scalar" {
			local setvalueln is setline:addtextfield(setvalue:tostring()).
			set setvalueln:onconfirm to {
				parameter str.
				set setrray[lindex][1] to str:tonumber(setrray[lindex][1]).

				set setvalueln:text to (setrray[lindex][1]:tostring()).
				updatelex().
			}.
		}
		else if setvalue:typename="String" {
			local setvalueln is setline:addtextfield(setvalue).
			set setvalueln:onconfirm to {
				parameter str.
				set setrray[lindex][1] to str:tostring().
				updatelex().
			}.
		}
		else if setvalue:typename="List" {
			set setvalue to listln(setline,setvalue).
		}
		else if setvalue:typename="Boolean" {
			local setvalueln is setline:addcheckbox("",setvalue).
			set setvalueln:toggle to true.
			set setvalueln:ontoggle to {
				parameter tog.
				set setrray[lindex][1] to tog.
				updatelex().
			}.
		}
		else {
			local setvalueln is setline:addtextfield("UNK:"+setvalue:tostring()).
			set setvalueln:onconfirm to {
				parameter str.
			}.
		}

		local edtline is setline:addbutton("E").
		set edtline:tooltip to "Edit this item.".
		set edtline:style:width to 30.
		set edtline:onclick to {
			dovaldlg(lindex,setvalue:typename,"edit").
		}.

		local addline is setline:addbutton("+").
		set addline:tooltip to "Add new item above this item.".
		set addline:style:width to 30.
		set addline:onclick to {
			if guilex:haskey("addsetline") {killgui("addsetline").}.
			dovaldlg(lindex,"scalar","add").
		}.

		local delline is setline:addbutton("-").
		set addline:tooltip to "Delete this item.".
		set delline:style:width to 30.
		set delline:onclick to {
			ynmsg(list("Remove line?"),red,{
				setslex:remove(setrray[lindex][0]).
				setsdlg(frm,lines,currpg).
			},{}).
		}.
	}

	local function dovaldlg {
		parameter lindex.
		parameter typen.
		parameter act is "add".
		local setsnam is choose setrray[lindex][0] if act="edit" else "".
		local setsval is choose setrray[lindex][1] if act="edit" else 0.
		local setsttip is choose setrray[lindex][2] if act="edit" else "".
		minipanel("addsetline","Add settings item, line "+(lindex+1),false,200,guilex["controls1"]:x+450,guilex["controls1"]:y,list(true,true)).
		if act="add" {
			mpComboMenu("addsetline","setitemtype",{
				parameter sel.
				if sel<>typen {
					killgui("addsetline").
					dovaldlg(lindex,sel,act).
				}
			},list("Scalar","String","Boolean","RGBA")).
			set mpCombolex["addsetline"]["items"]["setitemtype"]["menu"]:index to mpCombolex["addsetline"]["items"]["setitemtype"]["menu"]:options:indexof(typen).
		}
		else {
			local edittype is mpCombolex["addsetline"]["vbox"]:addlabel(typen).
		}

		if act="add" {
			mpComboText("addsetline","property name",{
				parameter str.
				set setsnam to str.
			}).
		}
		else {
			local editprop is mpCombolex["addsetline"]["vbox"]:addlabel(setsnam).

		}

		if typen="RGBA" {
			set setsval to rgbaln(mpCombolex["addsetline"]["vbox"],choose setsval if act="edit" else rgba(1,0,1,0)).
		}
		else if typen="Scalar" {
			mpComboText("addsetline","scalar value",{
				parameter str.
				set setsval to str:tonumber(setsval).
			}).
			if act="edit" {set mpCombolex["addsetline"]["items"]["scalar value"]["textfld"]:text to setsval:tostring().}.
		}
		else if typen="String" {
			mpComboText("addsetline","string value",{
				parameter str.
				set setsval to str.
			}).
			if act="edit" {set mpCombolex["addsetline"]["items"]["string value"]["textfld"]:text to setsval.}.
		}
		else if typen="List" {
			set setsval to listln(mpCombolex["addsetline"]["vbox"],choose setsval if act="edit" else list(0,0)).
		}
		else if typen="Boolean" {
		}
		mpComboText("addsetline","description",{
			parameter str.
			set setsttip to str.
		}).
		if act="edit" {set mpCombolex["addsetline"]["items"]["description"]["textfld"]:text to setsttip.}.

		if act="add" {
			mpComboBtn("addsetline","Add",{

				setrray:insert(lindex,list(setsnam,setsval,setsttip)).
				updatelex().
				setsdlg(frm,lines,currpg).
				killgui("addsetline").
			}).
		}
		else {
			mpComboBtn("addsetline","Update",{


				set setrray[lindex][1] to setsval.
				set setrray[lindex][2] to setsttip.
				updatelex().
				setsdlg(frm,lines,currpg).
				killgui("addsetline").
			}).
		}
		mpComboBtn("addsetline","Cancel",{killgui("addsetline").},"",false).
	}

	local function rgbaln {
		parameter sline.
		parameter rgbaval.
		local rgbaRdlg is sline:addtextfield(rgbaval:r:tostring()).
		set rgbaRdlg:onconfirm to {
			parameter str.
			set rgbaval:r to str:tonumber(rgbaval:r).
			set rgbaRdlg:text to rgbaval:r:tostring().
			updatelex().
		}.
		local rgbaGdlg is sline:addtextfield(rgbaval:g:tostring()).
		set rgbaGdlg:onconfirm to {
			parameter str.
			set rgbaval:g to str:tonumber(rgbaval:g).
			set rgbaGdlg:text to rgbaval:g:tostring().
			updatelex().
		}.
		local rgbaBdlg is sline:addtextfield(rgbaval:b:tostring()).
		set rgbaBdlg:onconfirm to {
			parameter str.
			set rgbaval:b to str:tonumber(rgbaval:b).
			set rgbaBdlg:text to rgbaval:b:tostring().
			updatelex().
		}.
		local rgbaAdlg is sline:addtextfield(rgbaval:a:tostring()).
		set rgbaAdlg:onconfirm to {
			parameter str.
			set rgbaval:a to str:tonumber(rgbaval:a).
			set rgbaAdlg:text to rgbaval:a:tostring().
			updatelex().
		}.
		return rgbaval.
	}

	local function listln {
		parameter sline.
		parameter listval.
		from {local bx is 0.} until (bx=listval:length) step {set bx to bx+1.} do {
			local xx is bx.
			if listval[xx]:typename="Scalar" {
				local bxdlg is sline:addtextfield(listval[xx]:tostring()).
				set bxdlg:onconfirm to {
					parameter str.

					set listval[xx] to str:tonumber(listval[xx]).
					set bxdlg:text to listval[xx]:tostring().
					updatelex().
				}.
			}
			else if listval[xx]:typename="String" {
				local bxdlg is sline:addtextfield(listval[xx]).
				set bxdlg:onconfirm to {
					parameter str.
					set listval[xx] to str.

					updatelex().
				}.
			}
			else if listval[xx]:typename="Boolean" {
				local bxdlg is sline:addcheckbox("",listval[xx]).
				set bxdlg:toggle to true.
				set bxdlg:ontoggle to {
					parameter tog.
					set listval[xx] to tog.
					updatelex().
				}.
			}
			else {
				local bxdlg is sline:addlabel("UNK").
			}
		}
		return listval.
	}

	local function updatelex {
		setslex:clear().
		for f2 in setrray {
			set setslex[f2[0]] to list().
			setslex[f2[0]]:add(f2[1]).
			setslex[f2[0]]:add(f2[2]).
		}
	}

	set setspgs to list(frm,lines,currpg).

	return ceiling(setrray:length/lines).
}

function paging {
	parameter pane.
	parameter topline.
	parameter lines.
	parameter currpg.
	parameter shfnc.

	local pagesnum is 0.
	set pagesnum to shfnc(topline,lines,currpg).

	local linbox is pane:addhbox().
	set linbox:style:width to 80.
	local linlab is linbox:addlabel("lines:").
	set linlab:tooltip to "Lines per page. Resetting returns to the first page.".
	set linlab:style:width to 40.
	set linlab:style:align to "right".

	local linbtn is linbox:addbutton(lines:tostring()).
	set linbtn:style:width to 30.
	set linbtn:style:align to "center".
	set linbtn:onclick to {
		set lindlg:text to lines:tostring().
		linbtn:hide.
		lindlg:show.
		set pgminus:enabled to false.
		set pgplus:enabled to false.
	}.
	local lindlg is linbox:addtextfield(lines:tostring()).
	set lindlg:style:width to 30.
	set lindlg:style:align to "center".
	set lindlg:onconfirm to {
		parameter str.
		set lines to str:tonumber(lines).
		if lines<1 {
			set lines to 1.
			set lindlg:text to "1".
		}
		set currpg to 1.
		set topline to 1.
		set pagesnum to shfnc(topline,lines,currpg).
		set pginfo:text to currpg+"/"+pagesnum.
		set linbtn:text to lines:tostring().
		lindlg:hide.
		linbtn:show.
		set pgminus:enabled to true.
		set pgplus:enabled to true.
	}.
	lindlg:hide.

	local pgminus is pane:addbutton("Page -").
	set pgminus:onclick to {
		set currpg to currpg-1.
		if currpg>0 {
			set topline to topline-lines.
			set pagesnum to shfnc(topline,lines,currpg).
			set pginfo:text to currpg+"/"+pagesnum.
		}
		else {
			set currpg to 1.
		}
	}.

	local pgplus is pane:addbutton("Page +").
	set pgplus:onclick to {

		set currpg to currpg+1.
		if currpg<=pagesnum {
			set topline to topline+lines.
			set pagesnum to shfnc(topline,lines,currpg).
			set pginfo:text to currpg+"/"+pagesnum.
		}
		else {
			set currpg to pagesnum.
		}
	}.

	local pginfo is pane:addlabel(currpg+"/"+pagesnum).
	set pginfo:tooltip to "current page / total pages".
	set pginfo:style:width to 30.
}

function showdir {
	parameter svol.
	parameter spath is ":".

	local ident is "".
	local termpg is 1.
	local quit is false.
	print " ".// skip loop printing line
	print "====== volume "+volume(svol):name+" ======".
	iterate(svol+spath).
	local function iterate {
		parameter fpath.

		local ldir is open(fpath):list().
		for lf in ldir:keys {
			if quit {break.}.
			if open(fpath+"/"+lf):isfile {
				// print ident+lf.
			print ident+lf+" ("+open(fpath+"/"+lf):size+" bytes)".
			}
			else {
				print ident+fpath+"/"+lf+" (directory)".
				set ident to ident+"  ".
				iterate(fpath+"/"+lf).
			}
			set termpg to termpg+1.
			if termpg>(terminal:height*0.8) {
				if terminal:input:haschar() {terminal:input:clear().}.
				print "---------- press any key to continue, or [q]uit ----------".
				local chr is terminal:input:getchar().
				if chr="q" {set quit to true.}.
				set termpg to 1.
			}
		}
		set ident to choose "" if ident="" else ident:remove(0,2).
	}
	print "===================================".
	print "FREE/ALL: "+volume(svol):freespace+"/"+volume(svol):capacity.
	terminal:input:clear().
}

function makelocals {
	local finok is true.
	print "====== volume "+volnams[locfs]+" ======".
	print "deleting local files...".
	local lfiles is open(locfs+":"):list().
	for ftodel in lfiles:keys {
		if ftodel<>"boot" {
			if ftodel="etc" and not clretcchb:pressed {
				print "...local etc NOT DELETED".
			}
			else {
				print "deleting "+locfs+":"+ftodel.
				set finok to deletepath(locfs+":"+ftodel).
			}
		}
		else {
			print "preserving 'boot' dir.".
		}
	}

	local confpath is "etc/"+shipdir+"/".
	local archfs is "0".

	print "...copying started".
	if cplibchb:pressed {
		if not exists(locfs+":lib") {
			print "creating "+locfs+":lib".
			createdir(locfs+":lib").
		}
		for llib in cplibs {
			print "copying library: "+llib.
			if exists(archfs+":lib/"+llib) {
				set finok to copypath(archfs+":lib/"+llib,locfs+":lib").
			}
			else {
				print "ERROR: library "+llib+" not found".
				set finok to false.
				return false.
			}
		}
	}
	else {
		print "...SKIPPING lib directory creation and copy".
	}

	if cpetcchb:pressed {
		print "checking for "+locfs+":etc".
		if not exists(locfs+":etc") {
			print "creating "+locfs+":etc".
			createdir(locfs+":etc").
			print "creating "+locfs+":etc/templates".
			createdir(locfs+":etc/templates").
		}

		print "checking for "+locfs+":etc/"+shipdir+"/".

		if not exists(locfs+":"+confpath) {
			print "creating "+locfs+":"+confpath.
			createdir(locfs+":"+confpath).
		}

		if cpsetschb:pressed {
			local allsets is "etc/all_settings.json".
			print "looking for common settings".
			if exists(allsets) {
				if (exists(locfs+":"+allsets)) {
					print "  all_settings exists, skipping...".
				}
				else {
					print "copying settings: "+allsets.
					set finok to copypath(allsets,locfs+":etc/").
				}
			}
			// print "-> common settings finished".
		}
	}
	else {
		print "...SKIPPING etc directory creation".
	}
	if not finok {return false.}.

	for afile in filelist {
		set finok to true.
		print "======================= copying '"+afile+ "' to "+locfs+":".
		set finok to copypath(archfs+":"+afile,locfs+":").
		local locscript is afile:replace(".ks","").
		print "using scriptid: "+locscript.

		if cpetcchb:pressed {

			print "looking for templates".
			local templfile is "etc/templates/"+locscript+"_PID.template.ks".
			if exists(archfs+":"+templfile) {
				if (exists(locfs+":"+templfile)) {
					print "  "+templfile:replace(confpath,"")+" exists, skipping...".
				}
				else {
					print "copying template: "+templfile.
					set finok to copypath(archfs+":"+templfile,locfs+":etc/templates/").
				}
			}
			// print "-> templates finished".

			if exists(archfs+":"+confpath) {
				local archsav is open(archfs+":"+confpath).
				if cpsetschb:pressed {
					print "looking for script settings".
					local scrsets is "etc/"+locscript+"_settings.json".
					if exists(scrsets) {
						if exists(locfs+":"+scrsets) {
							print "  "+locscript+"_settings.json exists, skipping...".
						}
						else {
						print "copying settings: "+scrsets.
						set finok to copypath(scrsets,locfs+":etc/").
						}
					}
					// print "-> script settings finished".

					print "looking for script+ship settings".
					local scshsets is confpath+ship:name+"_"+locscript+"_settings.json".
					if exists(archfs+":"+scshsets) {
						if exists(locfs+":"+scshsets) {
							print "  "+scshsets:replace(confpath,"")+" exists, skipping...".
						}
						else {
							print "copying settings: "+scshsets.
							set finok to copypath(archfs+":"+scshsets,locfs+":"+confpath).
						}
					}
					// print "-> script+ship settings finished".
				}

				print "looking for inputs".
				local dfltpath is confpath+ship:name+"_"+locscript+"_inDefaults.json".
				if exists(archfs+":"+dfltpath) {
					if (exists(locfs+":"+dfltpath)) {
						print "  "+dfltpath:replace(confpath,"")+" exists, skipping...".
					}
					else {
						print "copying inputs: "+dfltpath.
						set finok to copypath(archfs+":"+dfltpath,locfs+":"+confpath).
					}
				}
				
				for dflfile in archsav:list:keys {
					if dflfile:contains(ship:name+"_"+locscript+"_inDefs.save.") {
						if exists(locfs+":"+confpath+dflfile) {
							print "  "+dflfile+" exists, skipping...".
						}
						else {
							print "copying inputs: "+dflfile.
							set finok to copypath(archfs+":"+confpath+dflfile,locfs+":"+confpath).
						}
					}
					if not finok {print "ERROR copying inputs". break.}.
				}
				// print "-> inputs finished".

				print "looking for pidfiles".
				local pidfile is confpath+ship:name+"_"+locscript+"_PID.include.ks".

				if exists(archfs+":"+pidfile) {
					if (exists(locfs+":"+pidfile)) {
						print "  "+pidfile:replace(confpath,"")+" exists, skipping...".
					}
					else {
						print "copying PID include: "+pidfile.
						set finok to copypath(archfs+":"+pidfile,locfs+":"+confpath).
					}
				}
				// print "-> pidfiles finished".

				print "looking for gui positions".
				local gposfile is confpath+ship:name+"_"+locscript+"_guipos.json".
				if exists(archfs+":"+gposfile) {
					if (exists(locfs+":"+gposfile)) {
						print "  "+gposfile:replace(confpath,"")+" exists, skipping...".
					}
					else {
						print "copying GUI pos.: "+gposfile.
						set finok to copypath(archfs+":"+gposfile,locfs+":"+confpath).
					}
				}
				// print "-> gui positions finished".

				print "looking for saves".
				for sfile in archsav:list:keys {
					if sfile:contains(ship:name+"_"+locscript+"_PID.save.") {
						if exists(locfs+":"+confpath+sfile) {
							print "  "+sfile+" exists, skipping...".
						}
						else {
							print "copying save: "+sfile.
							set finok to copypath(archfs+":"+confpath+sfile,locfs+":"+confpath).
						}
					}
					if not finok {print "ERROR copying saves". break.}.
				}
				// print "-> saves finished".

			}
			else {
				print "--- directory "+archfs+":"+confpath+" does not exist".
				print "--- consider using 'newname.ks' to migrate data".
			}
		}
		else {
			print  "...SKIPPING etc files copy".
		}
		print "...copying finished".
		if not finok {return false.}.
	}

	return true.
}


function savvalsload {
	set savlex to savvals.

	set locfiles to savlex["locfiles"].
	set cpopts to savlex["cpopts"].

	for lfile in locfiles:keys {
		if not mklcheck:haskey(lfile) {
			mklcheck:add(lfile,list(locfiles[lfile][0],locfiles[lfile][1])).
		}
		else {
			set mklcheck[lfile][0] to locfiles[lfile][0].
			set mklcheck[lfile][1] to locfiles[lfile][1].
		}
	}
	if defined filesbox {
		makedlg(mklcpgs[0],mklcpgs[1],mklcpgs[2]).
	}

	set clretcchb:pressed to cpopts["clretc"].
	set cpetcchb:pressed to cpopts["cpetc"].
	set cplibchb:pressed to cpopts["cplib"].
	set cpsetschb:pressed to cpopts["cpsets"].

}

function savvalssave {
	savlex:clear().
	savlex:add("locfiles",locfiles).
	savlex:add("cpopts",cpopts).
	set savvals to savlex.
}

chkpreset(true,preset).
global looptime is 0.

statmsg("mkl ready").
until scriptend {
	set looptime to time:seconds.
	print "loop:["+(time:seconds-looptime)+"]       " at(0,0).
	wait 0.
}
print "Local volume: "+path():root.
unset filesbox.
exit_cleanup("0:etc/"+scriptid+"_guipos.json"). // Use non-default GUI positions file
