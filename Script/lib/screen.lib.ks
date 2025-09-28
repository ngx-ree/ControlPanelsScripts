// screen.lib.ks by ngx

global guilex is lexicon(). // screens
global glinlex is lexicon(). // screen lines

// General procedure to build GUIs with various functional parts (minimize button, tooltips button...), handling various specific GUI behaviors (popup messages, GUI screen positions).
// Usually called by other GUI building functions.
function makegui {
	parameter guiid. // Unique GUI ID, reserved words (don't use): ctrlpan, popmsg, terminal:width, terminal:height, inputpane
	parameter gtitle is "". // GUI title shown on GUI's heading
	parameter ttips is false. // Whether the tooltips button ('?') and tooltips display at the bottom should be present.
	parameter glines is 1. // Number of screen lines. An older concept not used much, but still needed especially for minipanels.
	parameter gwide is currsets["ctrlm1w"][0]. // Control panel GUI width.
	parameter atx is currsets["ctrlm1x"][0]. // Initial X position on screen, overridden by a saved value.
	parameter aty is currsets["ctrlm1y"][0]. // Initial Y position on screen, overridden by a saved value.
	parameter pin is list(false,false). // Whether the pin button will be present and whether it will be pressed.
	parameter boxstyle is currsets["guibox"][0]. // Style of the GUI's header and main area, for example list(header,area), 1=box, 0=layout.
	parameter minbtn is true. // Whether the minimize button will be present.

	set atx to min(max(atx,0),currsets["mainx"][0]*.98).
	set aty to min(max(aty,0),currsets["mainy"][0]*.98).

	if guiid="popmsg" and guilex:haskey(guiid) {
		if scrposlex:haskey("popmsg") {
			local locid is guiid.
			until not guilex:haskey(guiid) {
				set popx to popx+popincrx.
				set popy to popy+popincry.
				set guiid to locid+popx:tostring()+popy:tostring().
			}
			set scrposlex[guiid] to lexicon().
			set scrposlex[guiid]["x"] to scrposlex["popmsg"]["x"]+popx.
			if scrposlex[guiid]["x"]>(currsets["mainx"][0]-200) or scrposlex[guiid]["x"]<(200) {set popincrx to -popincrx.}.
			set scrposlex[guiid]["y"] to scrposlex["popmsg"]["y"]+popy.
			if scrposlex[guiid]["y"]>(currsets["mainy"][0]-200) or scrposlex[guiid]["y"]<(200) {set popincry to -popincry.}.
		}
		else {

		}
	}
	else {
		if not scrposlex:haskey(guiid) {
			set scrposlex[guiid] to lexicon().
			set scrposlex[guiid]["x"] to atx.
			set scrposlex[guiid]["y"] to aty.
			set scrposlex[guiid]["pinned"] to pin[1].
		}
	}

	if guilex:haskey(guiid) {popmsg(list("ERROR: makegui(): id '"+guiid+"' already exists.","function terminated."),red,{},250). return false.}.

	set guilex[guiid] to gui(gwide).

	if (scrposlex[guiid]:haskey("pinned") and scrposlex[guiid]["pinned"]) {
		set guilex[guiid]:x to atx.
		set guilex[guiid]:y to aty.
	}
	else {
		set guilex[guiid]:x to scrposlex[guiid]["x"].
		set guilex[guiid]:y to scrposlex[guiid]["y"].
	}

	local headbox is 0.
	if boxstyle[0]=1 { // make visible box container for heading
		set headbox to guilex[guiid]:addhbox().
	}
	else { // make invisible layout container for heading
		set headbox to guilex[guiid]:addhlayout().
	}
	local headline is headbox:addlabel(gtitle).
	set headline:style:align to "center".

	if pin[0] {
		local pinbtn is headbox:addbutton("O").
		set pinbtn:style:hstretch to false.
		set pinbtn:style:align to "right".
		set pinbtn:toggle to true.
		set pinbtn:ontoggle to {
			parameter tog.
			set scrposlex[guiid]["pinned"] to tog.
			if tog {
				set pinbtn:text to "o".
			}
			else {
				set pinbtn:text to "O".
			}
		}.
		set pinbtn:pressed to scrposlex[guiid]["pinned"].
	}

	// tooltip box button
	if ttips {
		local ttbtn is headbox:addbutton("?").
		set ttbtn:style:hstretch to false.
		set ttbtn:style:align to "right".
		set ttbtn:toggle to true.
		set ttbtn:ontoggle to {
			parameter tog.
			if tog {
				ttfield:show.
			}
			else {
				ttfield:hide.
			}
		}.
	}

	// minimizing button
	if minbtn {
		local minbtn is headbox:addbutton("_").
		set minbtn:style:hstretch to false.
		set minbtn:style:align to "right".
		set minbtn:onclick to {
			mingui(guiid,gtitle).
		}.
	}

	local scrbox is 0.
	if boxstyle[1]=1 { // make visible box container for screen
		set scrbox to guilex[guiid]:addvbox().
	}
	else { // make invisible layout container for screen
		set scrbox to guilex[guiid]:addvlayout().
	}
	local ttfield is 0.
	if ttips {
		local ttbox is guilex[guiid]:addvlayout().
		set ttfield to ttbox:addhbox().
		local ttdisp is ttfield:addtipdisplay().
		ttfield:hide.
	}

	set glinlex[guiid] to list(). // establish lexicon for screen lines
	from {local lin is 1.} until lin > glines step {set lin to lin+1.} do { // create as many addressable lines as required
		local lx is scrbox:addlabel("").
		set lx:style:HEIGHT to 10.
		glinlex[guiid]:add(lx).
	}

	guilex[guiid]:show().
	return guiid.
}

// Minimize GUI, hide it and put a button with GUI's title on the basic control panel. Said button will restore (show) the GUI again.
// Usually called from the minimizing button, but can be called directly from within the main script when needed.
global minguilex is lexicon().
function mingui {
	parameter guiid.
	parameter gtitle is guilex[guiid]:widgets[0]:widgets[0]:text.
	guilex[guiid]:hide().
	set minguilex[guiid] to ctrlpan:addbutton(gtitle).
	set minguilex[guiid]:onclick to {
		guilex[guiid]:show().
		minguilex[guiid]:dispose().
	}.
}

// Kill GUI with a given ID, which means disposing of the GUI and cleaning all pertinent lexicons where applicable.
// This function also creates a record of the last GUI's screen position in the 'scrposlex' lexicon.
function killgui {
	parameter guiid. // ID of GUI to be killed

	set scrposlex[guiid]["x"] to guilex[guiid]:x.
	set scrposlex[guiid]["y"] to guilex[guiid]:y.

	guilex[guiid]:dispose().
	guilex:remove(guiid).
	glinlex[guiid]:clear().
	glinlex:remove(guiid).

	if ctrlpanlex:haskey(guiid) {
		set scrposlex[guiid]["selection"] to ctrlpanlex[guiid]["menu"]:options:indexof(ctrlpanlex[guiid]["selected"]).
		ctrlpanlex[guiid]:clear().
		ctrlpanlex:remove(guiid).
	}
	if mpCombolex:haskey(guiid) {
		mpCombolex[guiid]:clear().
		mpCombolex:remove(guiid).
	}
	if ctrlCombolex:haskey(guiid) {
		ctrlCombolex[guiid]:clear().
		ctrlCombolex:remove(guiid).
	}
	if setVallex:haskey(guiid) {
		setVallex[guiid]:clear().
		setVallex:remove(guiid).
	}
	if mchnrlex:haskey(guiid) {
		mchnrlex[guiid]:clear().
		mchnrlex:remove(guiid).
	}
	if valboxlex:haskey(guiid) {
		valboxlex[guiid]:clear().
		valboxlex:remove(guiid).
	}
	if msglex:haskey(guiid) {
		msglex[guiid]:clear().
		msglex:remove(guiid).
	}
	if minguilex:haskey(guiid) {
		minguilex[guiid]:dispose().
		minguilex:remove(guiid).
	}
	if guiid:startswith("popmsg") {
		if guiid="popmsg" {
			set popx to 0.
			set popy to 0.
		}
		else
		{
			set popx to popx-popincrx.
			set popy to popy-popincry.
			scrposlex:remove(guiid).
		}
	}
}

global popx is 0.
global popy is 0.
global popincrx is 20.
global popincry is 20.
// A simple popup message with text and an 'OK' button. Pressing 'OK' can execute code. The script does not wait until 'OK' is pressed.
function popmsg {
	parameter mtxt is list(). // Message text. List of strings, one item for each line. For example 'list("first message line","second line")'.
	parameter txtcol is currsets["popmsg:text:color"][0]. // Initial text color.
	parameter fnc is {}. // Function to be executed after 'OK' is pressed. If empty, pressing 'OK' will just dismiss the message.
	parameter wdth is currsets["popmw"][0]. // Message width.
	parameter atx is currsets["popmx"][0]. // Initial X position on screen, later overridden by a saved value.
	parameter aty is currsets["popmy"][0]. // Initial Y position on screen, later overridden by a saved value.
	parameter boxstyle is currsets["popbox"][0]. // Style of the message's header and main area, for example list(header,area), 1=box, 0=layout.

	local msgid is makegui("popmsg","",false,0,wdth,atx,aty,list(false,false),boxstyle,false).

	guilex[msgid]:widgets[0]:dispose().
	local msgpane is guilex[msgid]:widgets[0].

	for msgl in mtxt {
		set msgl to msgl:tostring().
		local msgtxt is msgpane:addlabel(msgl).
		set msgtxt:style:align to "center".
		set msgtxt:style:hstretch to true.
		set msgtxt:style:textcolor to txtcol.
	}
	local ok is msgpane:addbutton("OK").
	set ok:onclick to {
		killgui(msgid).
		fnc:call().
	}.
	msgpane:show().
}

// 'YES/NO' popup message. Each button can run its code and the message can wait for either button to be pressed (however, not in the script's loop!).
function ynmsg {
	parameter mtxt is list(). // Message text. List of strings, one item for each line. For example list("first message line","second line").
	parameter txtcol is currsets["ynmsg:text:color"][0]. // Initial text color.
	parameter fncy is {}. // Function to be executed after 'YES' is pressed. If empty, pressing it will just dismiss the message.
	parameter fncn is {}. // Function to be executed after 'NO' is pressed. If empty, pressing it will just dismiss the message.
	parameter ynwait is false. // Wait until either button press? IMPORTANT!: do not set to TRUE inside the script's loop, it will freeze the script. If set to FALSE, it can also be called from within the loop, but it will not stop/pause the script.
	parameter wdth is currsets["popmw"][0]. // Message width.
	parameter atx is currsets["popmx"][0]. // Initial X position on screen, later overridden by a saved value.
	parameter aty is currsets["popmy"][0]. // Initial Y position on screen, later overridden by a saved value.
	parameter boxstyle is currsets["ynbox"][0]. // Style of the message's header and main area, for example list(header,area), 1=box, 0=layout.

	local msgid is makegui("popmsg","",false,0,wdth,atx,aty,list(false,false),boxstyle,false).

	guilex[msgid]:widgets[0]:dispose().
	local msgpane is guilex[msgid]:widgets[0].

	for msgl in mtxt {
		set msgl to msgl:tostring().
		local msgtxt is msgpane:addlabel(msgl).
		set msgtxt:style:align to "center".
		set msgtxt:style:hstretch to true.
		set msgtxt:style:textcolor to txtcol.
	}
	local ynpane is msgpane:addhlayout().
	local ybtn is ynpane:addbutton("YES").
	set ybtn:onclick to {
		killgui(msgid).
		fncy:call().
		set ynwait to false.

	}.
	local nbtn is ynpane:addbutton("NO").
	set nbtn:onclick to {
		killgui(msgid).
		fncn:call().
		set ynwait to false.
	}.
	msgpane:show().
	wait until(not ynwait).
}

// Initial pane for script's input parameters. Allows saving/deleting input values specific for each vessel and script.
function inputpane {
	parameter goon is false. // If TRUE, the input pane does not wait for a 'START' press and starts the script with default values. Can also be set as a string value, in which case the input pane will load inputs from a file with that string identifier and automatically confirms the script's start. If 'goon' is set to TRUE as a boolean or as a non-zero number, 'default' inputs are loaded and the script's start is automatically confirmed.
	parameter sinput is true. // If TRUE, a simpler input pane variant is used without the possibility to load multiple inputs from files. Single file input functionality is used instead. This allows using the 'inputpane' function without the need to use the 'ldsv.lib.ks' library, making it suitable for simpler scripts.
	parameter clmns is 1. // Number of columns on input pane.
	parameter atx is currsets["inpx"][0]. // Initial X position on screen, later overridden by a saved value.
	parameter aty is currsets["inpy"][0]. // Initial Y position on screen, later overridden by a saved value.
	parameter ttips is false. // Whether tooltips button ('?') and tooltips display at the bottom should be present.

	local guiid is "inputpane".

	if not sinput {set clmns to max(clmns,2).}. // If the input pane is not simple, the minimum columns number is 2. This is to secure space for the more complex pane's bottom buttons line.

	makegui(guiid,"Input Parameters",ttips,1,100,atx,aty).
	glinlex[guiid][0]:dispose().
	glinlex[guiid]:clear().

	local dfltpath is choose "etc/"+shipdir+"/"+ship:name+"_"+scriptid+"_inDefaults.json" if sinput else "etc/"+shipdir+"/"+ship:name+"_"+scriptid+"_inDefs.save.".
	local scrbox is guilex[guiid]:widgets[1].
	local svbox is scrbox:addhlayout().
	local prmfld is lexicon().
	local clmnbox is list().

	local function fillvals {
		local maxwdth is 0.
		local txtsize is 0.

		for clm in clmnbox {
			clm:dispose().
		}
		clmnbox:clear().

		from {local c is 1.} until c>clmns step {set c to c+1.} do {
			clmnbox:add(svbox:addvlayout()).
		}

		local c1 is 0.
		local crw is 1.
		for prml in input_data:keys {
			if not prml:startswith("_") { // skip metadata
				local itemtxt is input_data[prml][0].
				local itemval is "".
				if input_data[prml][1]:typename<>"List" {
					set itemval to input_data[prml][1]:tostring().
				}
				local itemtyp is input_data[prml][1]:typename. // String, Boolean, Scalar, List, Lexicon
				local ttiptxt is "*no tooltip*".
				if input_data[prml]:length>2 {set ttiptxt to input_data[prml][2].}.
				if itemtyp = "Boolean" {
					local hbox is clmnbox[c1]:addhbox().
					set prmfld[prml] to hbox:addcheckbox(itemtxt,input_data[prml][1]).
					makettip(prml,prmfld[prml],ttiptxt).
				}
				else if itemtyp = "List" {
					local hbox is clmnbox[c1]:addhbox().
					local lbl is hbox:addlabel(itemtxt).
					set lbl:style:align to "left".
					makettip(prml,lbl,ttiptxt).
					set prmfld[prml] to hbox:addpopupmenu().
					set prmfld[prml]:options to input_data[prml][1].

					if input_fnc:haskey(prml) {
						set prmfld[prml]:options to input_fnc[prml]:call().
					}

					if input_data["_VALUE"]:haskey(prml) {
						set prmfld[prml]:index to prmfld[prml]:options:indexof(input_data["_VALUE"][prml]).
					}
					else {
						set prmfld[prml]:index to 0.
					}

					for listitem in input_data[prml][1] {
						if listitem:tostring():length() > itemval:length() {
							set itemval to listitem:tostring().
						}
					}
				}
				else {
					local hbox is clmnbox[c1]:addhbox().
					local lbl is hbox:addlabel(itemtxt).
					set lbl:style:align to "left".
					makettip(prml,lbl,ttiptxt).
					set prmfld[prml] to hbox:addtextfield(itemval).
					set prmfld[prml]:style:align to "right".
				}

				set crw to crw+1.
				if crw>round(input_data:length/clmns) {
					set c1 to c1+1.
					if c1>clmns-1 {set c1 to 0.}.
					set crw to 1.
				}
				set txtsize to (itemtxt:length()+itemval:length()).
				if maxwdth < txtsize { set maxwdth to txtsize.}.
			}
		}
		set guilex[guiid]:style:width to max(maxwdth*(guilex[guiid]:style:fontsize/2)*clmns,200).
	}

	local function makettip {
		parameter prml.
		parameter lbl.
		parameter ttxt.
		if ttips {
			set lbl:tooltip to ttxt.
		}
	}

	local function set_input {
		parameter isdflt is false.
		for prmv in input_data:keys {
			if not prmv:startswith("_") { // skip metadata
				local itemtyp is input_data[prmv][1]:typename. // String, Boolean, Scalar, List, Lexicon
				if itemtyp = "String" {
					set input_data[prmv][1] to prmfld[prmv]:text.
				}
				if itemtyp = "Scalar" {
					set input_data[prmv][1] to prmfld[prmv]:text:tonumber.
				}
				else if itemtyp = "Boolean" {
					set input_data[prmv][1] to prmfld[prmv]:pressed.
				}
				else if itemtyp = "List" {

					if isdflt {
						set input_data[prmv][1] to prmfld[prmv]:options.
						set input_data["_VALUE"][prmv] to prmfld[prmv]:value.
					}
					else {
						set input_data[prmv][1] to prmfld[prmv]:value.
					}
				}
			}
		}
	}

	local function makesave {
		parameter p.
		parameter f.

		set_input(true).
		writejson(input_data,f+p+".json").
		set savsel to p.
	}

	local function makeload {
		parameter p.
		parameter f.

		set input_data to readjson(f+p+".json").
		set savsel to p.
		fillvals().
	}

	fillvals().

	local defltbox is scrbox:addhlayout().

	if sinput {
		local deflt is defltbox:addbutton("Save as inputs").
		set deflt:onclick to {
			set_input(true).
			writejson(input_data,dfltpath).
			set rmdef:enabled to exists(dfltpath).
		}.

		local rmdef is defltbox:addbutton("Delete inputs").
		set rmdef:onclick to {
			deletepath(dfltpath).
			set rmdef:enabled to exists(dfltpath).
		}.
		set rmdef:enabled to exists(dfltpath).

		local ok is scrbox:addbutton("START").
		set ok:onclick to {
			set goon to true.
		}.
	}
	else {

		local saveloaddefs is svldbtn(defltbox,"Inputs: ").
		set saveloaddefs:ontoggle to {
			parameter tog.
			saveload(tog,guilex[guiid]:x-200,guilex[guiid]:y,false,"dfltsavld",shipdir,"default",dfltpath,makesave@,makeload@).
		}.

		local confset is savldconf(defltbox).

		local ok is defltbox:addbutton("START").
		set ok:onclick to {
			set saveloaddefs:pressed to false.
			set goon to true.
		}.

		if not exists(dfltpath+"default"+".json") {
			makesave("default",dfltpath).
		}
		else if not goon {
			makeload("default",dfltpath).
		}

		if goon {
			if not exists(dfltpath+goon+".json") {set goon to "default".}.
			makeload(goon,dfltpath).
		}

	}

	lexcleanup:add(input_data).
	lexcleanup:add(input_fnc).
	wait until goon.
	set_input().
	killgui(guiid).
}

global ctrlpanlex is lexicon(). // lexicon for multipanel panes.
global msglex is lexicon().
 // Multipanel, contains multiple stack widgets that can be switched via popup menu. Each stack can have its own control elements like buttons, combos, checkboxes etc.
 // Bottom of the panel can have messages line for displaying log messages made by calling 'statmsg' function.
function ctrlmpanel {
	parameter cpmid. // Unique GUI ID, reserved words (don't use): ctrlpan, popmsg, terminal:width, terminal:height, inputpane
	parameter cpmtitle. // Title label shown on the top of the panel.
	parameter pages is list("page1","page2"). // IDs (and names) of each stack page.
	parameter hasmsg is false. // Whether message line (for statmsg("message","panelID")) will be used on bottom of the panel
	parameter ttips is false. // Whether tooltips button ('?') and tooltips display at the bottom should be present.
	parameter pwidth is list(currsets["ctrlm1w"][0],currsets["ctrlm1w"][0]). // starting width of each stack page. If this parameter is entered as scalar, its value is considered to be character length of messages line.
	parameter atx is currsets["ctrlm1x"][0]. // Initial X position on screen, later overridden by a saved value.
	parameter aty is currsets["ctrlm1y"][0]. // Initial Y position on screen, later overridden by a saved value.
	parameter boxstyle is currsets["ctrlmbox"][0]. // Style of panel's header and main area, for example list(header,area), 1=box, 0=layout
	parameter minbtn is true. // Whether the minimize button will be present.

	local wide is 0.
	if pwidth:typename = "List" {
		set wide to pwidth[0].
	}

	makegui(cpmid,cpmtitle,ttips,1,wide,atx,aty,list(false,false),boxstyle,minbtn).

	glinlex[cpmid][0]:dispose().
	glinlex[cpmid]:clear().

	local cpmpane is guilex[cpmid]:widgets[1].
	set ctrlpanlex[cpmid] to lexicon().

	local cmenu is cpmpane:addvlayout().
	set ctrlpanlex[cpmid]["menu"] to cmenu:addpopupmenu().
	set ctrlpanlex[cpmid]["menu"]:options to pages.
	set ctrlpanlex[cpmid]["menu"]:text to pages[0].
	set ctrlpanlex[cpmid]["selected"] to pages[0].

	set ctrlpanlex[cpmid]["menu"]:onchange to {
		parameter sel.
		set ctrlpanlex[cpmid]["selected"] to sel.
		ctrlpanlex[cpmid]["stack"]:SHOWONLY(ctrlpanlex[cpmid][sel]).
	}.

	set ctrlpanlex[cpmid]["stack"] to cpmpane:addstack().
	for opt in pages {
		set ctrlpanlex[cpmid][opt] to ctrlpanlex[cpmid]["stack"]:addvlayout().
	}

	ctrlpanlex[cpmid]["stack"]:SHOWONLY(ctrlpanlex[cpmid][pages[0]]).
	cpmpane:show().

	if hasmsg {
		set msglex[cpmid] to lexicon().
		local msglineset is cpmpane:addhbox().
		set msglex[cpmid]["msg"] to msglineset:addtextfield("...").
		set msglex[cpmid]["msg"]:style:font to "Consolas".
		if wide<>0 {
			set msglex[cpmid]["length"] to round(pwidth[0]/msglex[cpmid]["msg"]:style:font:length,0).
		}
		else {
			set msglex[cpmid]["length"] to pwidth.
		}
	}

	set ctrlpanlex[cpmid]["width"] to wide.

	if scrposlex:haskey(cpmid) and scrposlex[cpmid]:haskey("selection") {
		set ctrlpanlex[cpmid]["menu"]:index to scrposlex[cpmid]["selection"].
	}

}

global mpCombolex is lexicon(). // Lexicon for minipanels and their elements.
// A minipanel is a simpler control panel that can be, for example, created/destroyed by pressing a button. Its control elements can be created using functions and later accessed (if necessary) via 'mpCombolex' lexicon.
function minipanel {
	parameter cpmid. // minipanel unique ID.
	parameter cpmtitle. // minipanel title.
	parameter ttips is false. // Whether tooltips button ('?') and tooltips display at the bottom should be present.
	parameter pwidth is currsets["minpw"][0]. // minipanel GUI width.
	parameter atx is currsets["minpx"][0]. // Initial X position on screen, overridden by a saved value.
	parameter aty is currsets["minpy"][0]. // Initial Y position on screen, overridden by a saved value.
	parameter pin is list(false,false). // Whether pin button will be present and whether it will be pressed. See README for more information.
	parameter boxstyle is currsets["mpbox"][0]. // Style of GUI's header and main area, for example list(header,area), 1=box, 0=layout.
	parameter minbtn is false. // Whether minimize button will be present. Usually not used with minipanels, but it's possible.

	set mpCombolex[cpmid] to lexicon().
	set mpCombolex[cpmid]["items"] to lexicon().

	makegui(cpmid,cpmtitle,ttips,0,pwidth,atx,aty,pin,boxstyle,minbtn). // create screen base

	set glinlex[cpmid] to list().
	set mpCombolex[cpmid]["vbox"] to guilex[cpmid]:widgets[1].

	guilex[cpmid]:show().
}

// Control element for minipanels, consists of LEFT button, RIGHT button and value label.
// To address particular combo's elements, use 'mpCombolex[cpmid]["items"][lindx][key], where:
// cpmid - ID of minipanel where combo belongs
// "items" - References to minipanel's elements, it's always there.
// lindx - Combo's ID (also used as descriptive label).
// key - Reference to particular combo's element (button, label, textfield etc.)
// Combo's addressable keys are:
// "lbl" - Combo's descriptive label.
// "lbtn" - Left '<' button.
// "rbtn" - Right '>' button.
// "vallbl" - Combo's value, in this case just as a non-editable text label.
function mpComboLR {
	parameter cpmid. // ID of minipanel where this combo belongs.
	parameter combolabel. // Descriptive label of combo's controlled variable and also combo's reference identifier.
	parameter val. // Initial value of combo's controlled variable.
	parameter valfncL. // Function for left ('<') button.
	parameter valfncR. // Function for right ('>') button.
	parameter unit is "". // Unit descriptive label (for example 'm/s').
	parameter ttip is "". // Tooltip text for this combo.
	parameter newbox is true. // If TRUE, combo will be created as new element vertically, on the bottom of the minipanel. If FALSE, it will be created horizontally, to the right of previous combo.

	set mpCombolex[cpmid]["items"][combolabel] to lexicon().
	local lindx is combolabel.

	if newbox {
		glinlex[cpmid]:add(mpCombolex[cpmid]["vbox"]:addhbox()).
	}

	local btnbox is glinlex[cpmid][glinlex[cpmid]:length-1].

	set mpCombolex[cpmid]["items"][lindx]["lbl"] to btnbox:addlabel(combolabel).
	set mpCombolex[cpmid]["items"][lindx]["lbl"]:tooltip to ttip.

	set mpCombolex[cpmid]["items"][lindx]["lbtn"] to btnbox:addbutton("<").
	set mpCombolex[cpmid]["items"][lindx]["lbtn"]:onclick to {
		local valLb is valfncL().
		set mpCombolex[cpmid]["items"][lindx]["vallbl"]:text to valLb:tostring().
	}.

	set mpCombolex[cpmid]["items"][lindx]["rbtn"] to btnbox:addbutton(">").
	set mpCombolex[cpmid]["items"][lindx]["rbtn"]:onclick to {
		local valRb is valfncR().
		set mpCombolex[cpmid]["items"][lindx]["vallbl"]:text to valRb:tostring().
	}.

	set mpCombolex[cpmid]["items"][lindx]["vallbl"] to btnbox:addlabel(val:tostring()).
	if unit<>"" {set mpCombolex[cpmid]["items"][lindx]["vallbl"]:style:align to "right".}.

	local unitlab is btnbox:addlabel(unit).
	set unitlab:style:font to "Consolas".
	set unitlab:style:width to max(1,unitlab:style:font:length*unitlab:text:length).
}

// Similar to 'mpComboLR', control element for minipanels, consists of LEFT button, RIGHT button and value textfield. In this case, the value can be changed directly by typing/confirming in the textfield.
// To address particular combo's elements, use 'mpCombolex[cpmid]["items"][lindx][key], where:
// cpmid - ID of minipanel where the combo belongs.
// "items" - References to minipanel's elements, it's always there.
// lindx - Combo's ID (also used as descriptive label).
// key - Reference to particular combo's element (button, label, textfield etc.)
// Combo's addressable keys are:
// "lbl" - Combo's descriptive label.
// "lbtn" - Left '<' button.
// "rbtn" - Right '>' button.
// "vallbl" - Combo's value, in this case editable textfield.
function mpComboLRN {
	parameter cpmid. // ID of minipanel where this combo belongs.
	parameter combolabel. // Descriptive label of combo's controlled variable and also combo's reference identifier.
	parameter val. // Initial value of combo's controlled variable.
	parameter valfncL. // Function for left ('<') button.
	parameter valfncR. // Function for Right ('>') button.
	parameter valfncT. // Function for textfield's 'onconfirm'.
	parameter unit is "". // Unit descriptive label (for example 'm/s')
	parameter ttip is "". // Tooltip text for this combo.
	parameter newbox is true. // If TRUE, combo will be created as new element vertically, on the bottom of the minipanel. If FALSE, it will be created horizontally, to the right of previous combo.

	set mpCombolex[cpmid]["items"][combolabel] to lexicon().
	local lindx is combolabel.

	if newbox {
		glinlex[cpmid]:add(mpCombolex[cpmid]["vbox"]:addhbox()).
	}

	local btnbox is glinlex[cpmid][glinlex[cpmid]:length-1].

	set mpCombolex[cpmid]["items"][lindx]["lbl"] to btnbox:addlabel(combolabel).
	set mpCombolex[cpmid]["items"][lindx]["lbl"]:tooltip to ttip.
	set mpCombolex[cpmid]["items"][lindx]["lbtn"] to btnbox:addbutton("<").
	set mpCombolex[cpmid]["items"][lindx]["lbtn"]:onclick to {
		local valLb is valfncL().
		set mpCombolex[cpmid]["items"][lindx]["vallbl"]:text to valLb:tostring().
	}.

	set mpCombolex[cpmid]["items"][lindx]["rbtn"] to btnbox:addbutton(">").
	set mpCombolex[cpmid]["items"][lindx]["rbtn"]:onclick to {
		local valRb is valfncR().
		set mpCombolex[cpmid]["items"][lindx]["vallbl"]:text to valRb:tostring().
	}.

	set mpCombolex[cpmid]["items"][lindx]["vallbl"] to btnbox:addtextfield(val:tostring()).
	if unit<>"" {set mpCombolex[cpmid]["items"][lindx]["vallbl"]:style:align to "right".}.
	set mpCombolex[cpmid]["items"][lindx]["vallbl"]:onconfirm to {
		parameter str.
		local valN is valfncT(str).
		if mpCombolex:haskey(cpmid) {set mpCombolex[cpmid]["items"][lindx]["vallbl"]:text to valN:tostring().}.
	}.

	local unitlab is btnbox:addlabel(unit).
	set unitlab:style:font to "Consolas".
	set unitlab:style:width to max(1,unitlab:style:font:length*unitlab:text:length).
}

// Control element for minipanels, toggle button. Button's text label can be changed by the return value of toggle function (for example ON/OFF).
// To address particular combo's elements, use 'mpCombolex[cpmid]["items"][lindx][key], where:
// cpmid - ID of minipanel where the combo belongs.
// "items" - References to minipanel's elements, it's always there.
// lindx - Combo's ID (also used as descriptive label).
// key - Reference to particular combo's element (button, label, textfield etc.)
// Combo's addressable keys are:
// "tbtn" - Combo's button itself. This combo consists only of toggleable button.
function mpComboTog {
	parameter cpmid. // ID of minipanel where this combo belongs.
	parameter combolabel. // Descriptive label of combo's controlled variable and also combo's reference identifier.
	parameter val. // Initial value of combo's controlled variable.
	parameter valfncT. // Function for button's 'ontoggle'. The function must return a string which will be displayed as button's text.
	parameter ttip is "". // Tooltip text for this combo.
	parameter newbox is true. // If TRUE, combo will be created as new element vertically, on the bottom of the minipanel. If FALSE, it will be created horizontally, to the right of previous combo.

	set mpCombolex[cpmid]["items"][combolabel] to lexicon().
	local lindx is combolabel.
	if newbox {
		glinlex[cpmid]:add(mpCombolex[cpmid]["vbox"]:addhbox()).
	}
	local btnbox is glinlex[cpmid][glinlex[cpmid]:length-1].
	set mpCombolex[cpmid]["items"][lindx]["tbtn"] to btnbox:addbutton(combolabel:tostring()).
	set mpCombolex[cpmid]["items"][lindx]["tbtn"]:tooltip to ttip.
	set mpCombolex[cpmid]["items"][lindx]["tbtn"]:toggle to true.
	set mpCombolex[cpmid]["items"][lindx]["tbtn"]:ontoggle to {
		parameter tog.
		local valT is valfncT(tog).
		if mpCombolex:haskey(cpmid) {set mpCombolex[cpmid]["items"][lindx]["tbtn"]:text to valT:tostring().}.
	}.
	set mpCombolex[cpmid]["items"][lindx]["tbtn"]:pressed to val.
}

// Similar to 'mpComboTog', but instead of a button it uses a checkbox.
// To address particular combo's elements, use 'mpCombolex[cpmid]["items"][lindx][key], where:
// cpmid - ID of minipanel where the combo belongs.
// "items" - References to minipanel's elements, it's always there.
// lindx - Combo's ID (also used as descriptive label).
// key - Reference to particular combo's element (button, label, textfield etc.)
// Combo's addressable keys are:
// "chbox" - Combo's checkbox itself. This combo consists only of a toggleable checkbox.
function mpComboChb {
	parameter cpmid. // ID of minipanel where the combo belongs.
	parameter combolabel. // Descriptive label of combo's controlled variable and also combo's reference identifier.
	parameter val. // Initial value of combo's controlled variable.
	parameter valfncT. // Function for checkbox's 'ontoggle'.
	parameter ttip is "". // Tooltip text for this combo.
	parameter newbox is true. // If TRUE, combo will be created as new element vertically, on the bottom of the minipanel. If FALSE, it will be created horizontally, to the right of previous combo.

	set mpCombolex[cpmid]["items"][combolabel] to lexicon().
	local lindx is combolabel.
	if newbox {
		glinlex[cpmid]:add(mpCombolex[cpmid]["vbox"]:addhbox()).
	}
	local btnbox is glinlex[cpmid][glinlex[cpmid]:length-1].
	set mpCombolex[cpmid]["items"][lindx]["chbox"] to btnbox:addcheckbox(combolabel:tostring()).
	set mpCombolex[cpmid]["items"][lindx]["chbox"]:tooltip to ttip.
	set mpCombolex[cpmid]["items"][lindx]["chbox"]:toggle to true.
	set mpCombolex[cpmid]["items"][lindx]["chbox"]:ontoggle to {
		parameter tog.
		local valT is valfncT(tog).
		if mpCombolex:haskey(cpmid) {set mpCombolex[cpmid]["items"][lindx]["chbox"]:text to valT:tostring().}.
	}.
	set mpCombolex[cpmid]["items"][lindx]["chbox"]:pressed to val.
}

// Control element for minipanels, a simple click button.
// To address particular combo's elements, use 'mpCombolex[cpmid]["items"][lindx][key], where:
// cpmid - ID of minipanel where the combo belongs.
// "items" - References to minipanel's elements, it's always there.
// lindx - Combo's ID (also used as descriptive label).
// key - Reference to particular combo's element (button, label, textfield etc.)
// Combo's addressable keys are:
// "pbtn" - Combo's button itself. This combo consists only of a clickable button.
function mpComboBtn {
	parameter cpmid. // ID of minipanel where this combo belongs.
	parameter combolabel. // Descriptive label of combo's controlled variable and also combo's reference identifier.
	parameter valfncT. // Function for button's 'onclick' function.
	parameter ttip is "". // Tooltip text for this combo.
	parameter newbox is true. // If TRUE, combo will be created as new element vertically, on the bottom of the minipanel. If FALSE, it will be created horizontally, to the right of previous combo.

	set mpCombolex[cpmid]["items"][combolabel] to lexicon().
	local lindx is combolabel.
	if newbox {
		glinlex[cpmid]:add(mpCombolex[cpmid]["vbox"]:addhbox()).
	}
	local btnbox is glinlex[cpmid][glinlex[cpmid]:length-1].
	set mpCombolex[cpmid]["items"][lindx]["pbtn"] to btnbox:addbutton(combolabel:tostring()).
	set mpCombolex[cpmid]["items"][lindx]["pbtn"]:tooltip to ttip.
	set mpCombolex[cpmid]["items"][lindx]["pbtn"]:onclick to {
		valfncT().
	}.
}

// Control element for minipanels, popup menu.
// To address particular combo's elements, use 'mpCombolex[cpmid]["items"][lindx][key], where:
// cpmid - ID of minipanel where the combo belongs.
// "items" - References to minipanel's elements, it's always there.
// lindx - Combo's ID (also used as descriptive label).
// key - Reference to particular combo's element (button, label, textfield etc.)
// Combo's addressable keys are:
// "menu" - Combo's popup menu itself. This combo consists only of a popup menu.
function mpComboMenu {
	parameter cpmid. // ID of minipanel where the combo belongs.
	parameter combolabel. // Not really a label, but must be present for the lexicon key.
	parameter valfncT. // Function for menu's 'onchange'.
	parameter opts is list(). // List of menu's options.
	parameter ttip is "". // Tooltip text for this combo.
	parameter newbox is true. // If TRUE, combo will be created as new element vertically, on the bottom of the minipanel. If FALSE, it will be created horizontally, to the right of previous combo.

	set mpCombolex[cpmid]["items"][combolabel] to lexicon().
	local lindx is combolabel.
	if newbox {
		glinlex[cpmid]:add(mpCombolex[cpmid]["vbox"]:addhbox()).
	}
	local btnbox is glinlex[cpmid][glinlex[cpmid]:length-1].
	set mpCombolex[cpmid]["items"][lindx]["menu"] to btnbox:addpopupmenu.
	set mpCombolex[cpmid]["items"][lindx]["menu"]:tooltip to ttip.
	set mpCombolex[cpmid]["items"][lindx]["menu"]:onchange to {
		parameter sel.
		local valT is valfncT(sel).
	}.
	set mpCombolex[cpmid]["items"][lindx]["menu"]:options to opts.
}

// Control element for minipanels, simple textfield.
// To address particular combo's elements, use 'mpCombolex[cpmid]["items"][lindx][key], where:
// cpmid - ID of minipanel where th combo belongs.
// "items" - References to minipanel's elements, it's always there.
// lindx - Combo's ID (also used as descriptive label).
// key - Reference to particular combo's element (button, label, textfield etc.)
// Combo's addressable keys are:
// "textfld" - Combo's textfield itself. This combo consists only of editable textfield.
function mpComboText {
	parameter cpmid. // ID of minipanel where the combo belongs.
	parameter combolabel. // Not really a label, but must be present for the lexicon key.
	parameter valfncT. // Function for textfield's 'onconfirm'.
	parameter unit is "". // Unit descriptive label (for example 'm/s')
	parameter newbox is true. // If TRUE, combo will be created as new element vertically, on the bottom of the minipanel. If FALSE, it will be created horizontally, to the right of previous combo.

	set mpCombolex[cpmid]["items"][combolabel] to lexicon().
	local lindx is combolabel.
	if newbox {
		glinlex[cpmid]:add(mpCombolex[cpmid]["vbox"]:addhbox()).
	}
	local btnbox is glinlex[cpmid][glinlex[cpmid]:length-1].
	set mpCombolex[cpmid]["items"][lindx]["textfld"] to btnbox:addtextfield(combolabel:tostring()).
	if unit<>"" {set mpCombolex[cpmid]["items"][lindx]["textfld"]:style:align to "right".}.
	set mpCombolex[cpmid]["items"][lindx]["textfld"]:onconfirm to {
		parameter str.
		local valT is valfncT(str).
	}.

	local unitlab is btnbox:addlabel(unit).
	set unitlab:style:font to "Consolas".
	set unitlab:style:width to max(1,unitlab:style:font:length*unitlab:text:length).
}

global ctrlCombolex is lexicon(). // Lexicon for 'ctrlLRCombo' function.
// Control element usually used in control multipanels. Consists of left button ('<<<'), descriptive label, textfield, increment control slider, right button ('>>>') and alternatively popup menu or checkbox.
// Combo's functions and other properties are controlled by referencing 'ctrlCombolex' items after calling this function in main script.
// NOTE: due to kOS 'onconfirm' function behavior, in case the value box was manually edited, first click on '<<<' or '>>>' button does not decrease or increase the value.
// Combo's addressable keys are:
// "leftbtn" - Click button left ('<<<')
// "label" - Descriptive label of controlled variable.
// "txtfield" - Editable text field, value of controlled variable.
// "units" - Units label displayed after the value.
// "chbox" - If created, this references checkbox next to value textfield.
// "popup" - If created, this references popup menu next to value textfield.
// "slider" - Increment slider.
// "steplab" - Descriptive label of current increment value (controlled by slider).
// "rightbtn" - Click button right ('>>>')
function ctrlLRCombo {
	parameter guiid. // ID of control multipanel's stack page where this combo belongs. Necessary for exit cleanup.
	parameter ctrlset. // Combo's container, hbox or hlayout created in main script before this function is called. If this parameter is of type 'Boolean', it is used for enabling/disabling of combo with this 'comboid'.
	parameter comboid. // Combo's ID, also used as descriptive label.
	parameter initval is "". // Initially displayed value in textfield.
	parameter unit is "".  // Unit descriptive label (for example 'm/s')
	parameter haschb is false. // Whether combo has checkbox.
	parameter haspopup is false. // Whether combo has popup menu.
	parameter slidparms is list(10,1,10). // Increment control slider's parameters (initial, min, max).
	parameter slround is 0. // Rounding decimal places for slider's value.

	if ctrlset:typename = "Boolean" {
		set ctrlCombolex[guiid][comboid]["leftbtn"]:enabled to ctrlset.
		set ctrlCombolex[guiid][comboid]["label"]:enabled to ctrlset.
		set ctrlCombolex[guiid][comboid]["txtfield"]:enabled to ctrlset.
		set ctrlCombolex[guiid][comboid]["units"]:enabled to ctrlset.
		if 	ctrlCombolex[guiid][comboid]:haskey("chbox") {set ctrlCombolex[guiid][comboid]["chbox"]:enabled to ctrlset.}.
		if 	ctrlCombolex[guiid][comboid]:haskey("popup") {set ctrlCombolex[guiid][comboid]["popup"]:enabled to ctrlset.}.
		set ctrlCombolex[guiid][comboid]["slider"]:enabled to ctrlset.
		set ctrlCombolex[guiid][comboid]["steplab"]:enabled to ctrlset.
		set ctrlCombolex[guiid][comboid]["rightbtn"]:enabled to ctrlset.
	}
	else {
		if not ctrlCombolex:haskey(guiid) {set ctrlCombolex[guiid] to lexicon().}.
		set ctrlCombolex[guiid][comboid] to lexicon().

		set ctrlCombolex[guiid][comboid]["leftbtn"] to ctrlset:addbutton("<<<").
		set ctrlCombolex[guiid][comboid]["leftbtn"]:style:width to 50.

		set ctrlCombolex[guiid][comboid]["label"] to ctrlset:addlabel(comboid).
		set ctrlCombolex[guiid][comboid]["label"]:style:align to "left".
		set ctrlCombolex[guiid][comboid]["label"]:style:width to 65.

		set ctrlCombolex[guiid][comboid]["txtfield"] to ctrlset:addtextfield(initval).
		set ctrlCombolex[guiid][comboid]["txtfield"]:style:align to "right".
		set ctrlCombolex[guiid][comboid]["txtfield"]:style:width to 60.

		set ctrlCombolex[guiid][comboid]["units"] to ctrlset:addlabel(unit).
		set ctrlCombolex[guiid][comboid]["units"]:style:font to "Consolas".
		set ctrlCombolex[guiid][comboid]["units"]:style:width to max(1,ctrlCombolex[guiid][comboid]["units"]:style:font:length*ctrlCombolex[guiid][comboid]["units"]:text:length).

		if haschb {
			set ctrlCombolex[guiid][comboid]["chbox"] to ctrlset:addcheckbox(">>",false).
			set ctrlCombolex[guiid][comboid]["chbox"]:toggle to true.
		}

		if haspopup {
			set ctrlCombolex[guiid][comboid]["popup"] to ctrlset:addpopupmenu().
			set ctrlCombolex[guiid][comboid]["popup"]:style:width to 50.
		}

		set ctrlCombolex[guiid][comboid]["slider"] to ctrlset:addhslider(slidparms[0],slidparms[1],slidparms[2]).
		set ctrlCombolex[guiid][comboid]["slider"]:onchange to {
			parameter slid.
			set ctrlCombolex[guiid][comboid]["steplab"]:text to round(ctrlCombolex[guiid][comboid]["slider"]:value, slround):tostring().
		}.
		set ctrlCombolex[guiid][comboid]["steplab"] to ctrlset:addlabel(round(ctrlCombolex[guiid][comboid]["slider"]:value,slround):tostring()).
		set ctrlCombolex[guiid][comboid]["steplab"]:style:width to 20.
		set ctrlCombolex[guiid][comboid]["steplab"]:style:align to "center".

		set ctrlCombolex[guiid][comboid]["rightbtn"] to ctrlset:addbutton(">>>").
		set ctrlCombolex[guiid][comboid]["rightbtn"]:style:width to 50.

		return ctrlCombolex[guiid][comboid].
	}
}

global setVallex is lexicon(). // Lexicon for 'setValCombo' function.
// Control element used in control multipanels as well as in basic control panel's 'IPU' button. Consists of descriptive label, value display/edit box, value trigger and apply ('set') button. Optionally it can have checkbox element between the slider and 'set' button.
// Combo's functions and other properties are controlled by referencing 'setVallex' items after calling this function in main script.
// Combo's addressable keys are:
// "label" - Descriptive label of controlled variable.
// "slidbtn" - Button part of variable's edit/display box.
// "slidtxt" - Textfield part of variable's edit/display box.
// "slider" - Slider itself, can be referenced for value get/set.
// "setbtn" - 'set' button, can be referenced for 'onclick()' call.
// "chbox" - If created, this references checkbox between slider and 'set' button. Can be referenced for example for 'ontoggle' function.
function setValCombo {
	parameter guiid. // ID of control multipanel's stack page where this combo belongs. Necessary for exit cleanup.
	parameter valset. // Combo's container, hbox or hlayout created in main script before this function is called. If this parameter is of type 'Boolean', it is used for enabling/disabling of combo with this 'comboid'.
	parameter setvalid. // Combo's ID, also used as descriptive label.
	parameter slidparms is list(100,0,100). // Initial slider's parameters, initial, minimal, maximal.
	parameter setvalfnc is {}. // Function used in 'set' button's 'onclick' function. Single input parameter takes slider's current value.
	parameter slround is 0. // Rounding decimal places for slider's value.
	parameter unit is "%". // Units label displayed in display/edit box.
	parameter haschb is false. // Whether checkbox will be present between slider and 'set' button.
	parameter chbfnc is false. // If defined as a function, the function will be used as checkbox's 'ontoggle'. If left as a FALSE boolean, checkbox (if created) will be used as an indicator of unset value (the same as red/green color for label).

	if valset:typename = "Boolean" {
		set setVallex[guiid][setvalid]["label"]:enabled to valset.
		set setVallex[guiid][setvalid]["slidbtn"]:enabled to valset.
		set setVallex[guiid][setvalid]["slider"]:enabled to valset.
		set setVallex[guiid][setvalid]["chbox"]:enabled to valset.
		set setVallex[guiid][setvalid]["setbtn"]:enabled to valset.
	}
	else {
		if not setVallex:haskey(guiid) {set setVallex[guiid] to lexicon().}.
		set setVallex[guiid][setvalid] to lexicon().

		set setVallex[guiid][setvalid]["label"] to valset:addlabel(setvalid).
		set setVallex[guiid][setvalid]["label"]:style:align to "center".
		set setVallex[guiid][setvalid]["label"]:style:width to 70.
		set setVallex[guiid][setvalid]["slidbtn"] to valset:addbutton(slidparms[0]:tostring()+unit).
		set setVallex[guiid][setvalid]["slidbtn"]:style:align to "center".
		set setVallex[guiid][setvalid]["slidbtn"]:style:width to 50.
		set setVallex[guiid][setvalid]["slidbtn"]:onclick to {
			set setVallex[guiid][setvalid]["slidtxt"]:text to round(setVallex[guiid][setvalid]["slider"]:value,slround):tostring().
			setVallex[guiid][setvalid]["slidbtn"]:hide.
			setVallex[guiid][setvalid]["slidtxt"]:show.
			set setVallex[guiid][setvalid]["slider"]:enabled to false.
		}.

		set setVallex[guiid][setvalid]["slidtxt"] to valset:addtextfield(slidparms[0]:tostring()).
		set setVallex[guiid][setvalid]["slidtxt"]:style:align to "center".
		set setVallex[guiid][setvalid]["slidtxt"]:style:width to 50.
		set setVallex[guiid][setvalid]["slidtxt"]:onconfirm to {
			parameter str.
			if setVallex:haskey(guiid) {
				local val is round(str:tonumber(setVallex[guiid][setvalid]["slider"]:value),slround).
				set setVallex[guiid][setvalid]["slider"]:value to min(max(val,slidparms[1]),slidparms[2]).
				set setVallex[guiid][setvalid]["slidbtn"]:text to setVallex[guiid][setvalid]["slider"]:value:tostring()+unit.
				setVallex[guiid][setvalid]["slidtxt"]:hide.
				setVallex[guiid][setvalid]["slidbtn"]:show.
				set setVallex[guiid][setvalid]["slider"]:enabled to true.
			}
		}.
		setVallex[guiid][setvalid]["slidtxt"]:hide.

		set setVallex[guiid][setvalid]["slider"] to valset:addhslider(slidparms[0],slidparms[1],slidparms[2]).
		set setVallex[guiid][setvalid]["slider"]:style:align to "right".
		set setVallex[guiid][setvalid]["slider"]:onchange to {
			parameter slid.
			set setVallex[guiid][setvalid]["slidbtn"]:text to round(slid,slround):tostring()+unit.
			set setVallex[guiid][setvalid]["slidbtn"]:style:textcolor to red.

			if haschb and chbfnc:typename <> "UserDelegate" {
				set setVallex[guiid][setvalid]["chbox"]:pressed to true.
			}

		}.

		if haschb {
			set setVallex[guiid][setvalid]["chbox"] to valset:addcheckbox("",false).
			set setVallex[guiid][setvalid]["chbox"]:toggle to true.
			set setVallex[guiid][setvalid]["chbox"]:enabled to false.
			set setVallex[guiid][setvalid]["chbox"]:pressed to false.
			if chbfnc:typename = "UserDelegate" {
				set setVallex[guiid][setvalid]["chbox"]:ontoggle to {
					parameter tog.
					chbfnc(tog).
				}.
			}
		}

		set setVallex[guiid][setvalid]["setbtn"] to valset:addbutton("set").
		set setVallex[guiid][setvalid]["setbtn"]:style:width to 50.
		set setVallex[guiid][setvalid]["setbtn"]:style:align to "center".

		set setVallex[guiid][setvalid]["setbtn"]:onclick to {
			set setVallex[guiid][setvalid]["slidbtn"]:style:textcolor to setVallex[guiid][setvalid]["label"]:style:normal:TEXTCOLOR.
			if haschb and chbfnc:typename <> "UserDelegate" {
				set setVallex[guiid][setvalid]["chbox"]:pressed to false.
			}
			setvalfnc(round(setVallex[guiid][setvalid]["slider"]:value,slround)).
		}.
	}

	return setVallex[guiid][setvalid].
}

global mchnrlex is lexicon(). // Lexicon for 'mchnrline' function.
// Control multipanel's combo typically used in 'machinery' section for altering initially entered input values.
// Tooltips for this combo are either read from 'input_data' lexicon, or defined in main script after calling this function.
// Combo's addressable keys are:
// "hlayout" - Horizontal layout of the combo.
// "label" - Combo's descriptive label. This label has also tooltip assigned.
// "txtfield" - Editable text field of the combo.
function mchnrline {
	parameter guiid. // ID of control multipanel's stack page where this combo belongs. Necessary for exit cleanup.
	parameter mchnrset. // Combo's container, vbox or vlayout created in main script before this function is called.
	parameter mchnrid. // ID of given variable as used in 'input_data' lexicon. Label string and tooltip are linked to corresponding values in 'input_data' lexicon.
	parameter mchnrfnc. // Function for textfield's 'onconfirm'.

	if not mchnrlex:haskey(guiid) {set mchnrlex[guiid] to lexicon().}.
	set mchnrlex[guiid][mchnrid] to lexicon().

	set mchnrlex[guiid][mchnrid]["hlayout"] to mchnrset:addhlayout().
	set mchnrlex[guiid][mchnrid]["label"] to  mchnrlex[guiid][mchnrid]["hlayout"]:addlabel(input_data[mchnrid][0]).
	if input_data[mchnrid]:length=3 {set  mchnrlex[guiid][mchnrid]["label"]:tooltip to input_data[mchnrid][2].}.
	set  mchnrlex[guiid][mchnrid]["label"]:style:align to "left".
	set  mchnrlex[guiid][mchnrid]["txtfield"] to mchnrlex[guiid][mchnrid]["hlayout"]:addtextfield(input_data[mchnrid][1]:tostring()).
	set  mchnrlex[guiid][mchnrid]["txtfield"]:style:align to "right".
	set  mchnrlex[guiid][mchnrid]["txtfield"]:onconfirm to mchnrfnc@.

	return mchnrlex[guiid][mchnrid].
}

global valboxlex is lexicon(). // Lexicon for 'valbox' function.
// Combo typically used in 'PID values' control panels. Can also be used for variables other than PIDs.
// Combo's addressable keys are:
// "label" - PID (or other variable's) descriptive label.
// "txtfield" - Editable text field, value of controlled variable.
function valbox {
	parameter guiid. // ID of control multipanel's stack page where this combo belongs. Necessary for exit cleanup.
	parameter valset. // Combo's container, hbox or hlayout created in main script before this function is called.
	parameter valid. // ID of given PID (or other variable), used for addressing this combo later, if necessary.
	parameter vallab. // Descriptive label of this combo.
	parameter valval. // Initial value displayed in textfield.
	parameter valfnc. // Function for textfield's 'onconfirm'.
	parameter valtooltip is "no tooltip". // Optional tooltip text for label.

	if not valboxlex:haskey(guiid) {set valboxlex[guiid] to lexicon().}.
	set valboxlex[guiid][valid] to lexicon().

	set valboxlex[guiid][valid]["label"] to valset:addlabel(vallab).
	set valboxlex[guiid][valid]["label"]:style:align to "left".
	set valboxlex[guiid][valid]["label"]:style:width to 66.
	set valboxlex[guiid][valid]["label"]:tooltip to valtooltip.
	set valboxlex[guiid][valid]["txtfield"] to valset:addtextfield(valval:tostring()).
	set valboxlex[guiid][valid]["txtfield"]:style:align to "right".
	set valboxlex[guiid][valid]["txtfield"]:style:width to 60.
	set valboxlex[guiid][valid]["txtfield"]:onconfirm to valfnc@.

	return valboxlex[guiid][valid].
}

// Turn off all buttons on a particular (parent) widget by popping them.
function btnsoff {
	parameter wdgt. // Parent widget.
	parameter exclstr. // String containing button text(s) to exclude from popping (space-delimited).
	for wg in wdgt:widgets {
		if wg:TYPENAME="button" {
			if not exclstr:contains(wg:text) {
				set wg:pressed to false.
			}
		}
		else if wg:TYPENAME="box" {
			btnsoff(wg,exclstr).
		}
	}
	return true.
}


// Links RCS on/off state in KSP with the 'RCS' button.
// For this trigger to work, 'rcsbtn' button must be created with appropriate function. If that button does not exist, the trigger is created and dismissed without any action after first RCS change.
// If an action other than what is defined here is needed for the 'on rcs' trigger, create your own 'on rcs' trigger in main script and (if necessary), create RCS button with different identifier (for example 'rcsbtn1').
on rcs {
	if defined rcsbtn {
		set rcsbtn:pressed to rcs.
		return true.
	}
}

// Links SAS on/off state in KSP with the 'SAS' button.
// For this trigger to work, 'sasbtn' button must be created with appropriate function. If that button does not exist, the trigger is created and dismissed without any action after first SAS change.
// If an action other than what is defined here is needed for the 'on sas' trigger, create your own 'on sas' trigger in main script and (if necessary), create SAS button with different identifier (for example 'sasbtn1').
on sas {
	if defined sasbtn {
		set sasbtn:pressed to sas.
		return true.
	}
}
