// ctrlpanel.lib.ks by ngx

global termdata is false.
global logwindow is false.
global showverbose is false.
global showdebug is false.

// Function 'ctrlpanel' creates basic, single instance, globally accessible control panel, providing place for minimized GUIs and functional buttons.
// Basis for complex GUIs environment, but can be used (with some limitations) without the 'screen.lib.ks' library, where complex GUIs are not necessary.
// At minimum, it provides exit ('X') button which sets 'scriptend' variable to TRUE (exits script's 'until scriptend' loop).
// MAIN SCRIPT GLOBAL DEPENDENCIES:
// variable 'scriptend' - used for exiting main script loop
function ctrlpanel {
	parameter hasipu is false. // Whether IPU controls should be present. If set to true, main script must have 'screen.lib.ks' library included before calling 'ctrlpanel'.
	parameter hasguipos is false. // Whether GUI positions save controls should be present. If set to true, main script must have 'screen.lib.ks' library included before calling 'ctrlpanel'.
	parameter ttips is false. // Whether tooltips button '?' and tooltips display at the bottom should be present.
	parameter wdth is currsets["ctrlw"][0]. // control panel GUI width
	parameter atx is currsets["ctrlx"][0]. // initial X position on screen
	parameter aty is currsets["ctrly"][0]. // initial Y position on screen
	parameter isbtn_term to 0. // 1 or 2 - create terminal data button(s). See 'termbtn' function below for usage info.
	parameter isbtn_verb to 0. // 1  - 'Verbose' button will be created.
	parameter isbtn_debg to 0. // 1 - 'Debug' button will be created.
	parameter askexit to currsets["askexit"][0]. // Whether the script will ask for confirmation when exit ('X') is pressed.

	global ctrlbase is gui(wdth).
	local head1 is ctrlbase:addhlayout().
	local head2 is ctrlbase:addhlayout().
	local xitpane is ctrlbase:addhlayout().
	global ctrlpan is ctrlbase:addvlayout().

	if not scrposlex:haskey("ctrlpan") {
		set scrposlex["ctrlpan"] to lexicon().
		set scrposlex["ctrlpan"]["x"] to atx.
		set scrposlex["ctrlpan"]["y"] to aty.
	}

	set ctrlbase:x to scrposlex["ctrlpan"]["x"].
	set ctrlbase:y to scrposlex["ctrlpan"]["y"].

	local function compactpanel {
		parameter co.
		if co {
			set cmpbtn:text to "c".
			ipuset:hide.
			ctrlpan:hide.
		}
		else {
			set cmpbtn:text to "C".
			ipuset:show.
			ctrlpan:show.
		}
	}

	local cmpbtn is head1:addbutton("C").
	set cmpbtn:tooltip to "Switches the basic Control Panel between normal and compact mode. In compact mode, only the header and the ship's title are displayed.".
	set cmpbtn:style:hstretch to false.
	set cmpbtn:style:align to "left".
	set cmpbtn:toggle to true.
	set cmpbtn:ontoggle to {
		parameter tog.
		compactpanel(tog).
	}.

	local pantitle is head1:addlabel("Control Panel").
	set pantitle:style:align to "center".
	set pantitle:style:hstretch to true.

	if ttips {
		local ttbtn is head1:addbutton("?").
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

	// 'exitscript' function which sets 'scriptend' to TRUE, saves control panel GUI screen position into lexicon and clears basic Control Panel's GUI (which is not cleared within 'exit_cleanup').
	// Note that to save GUI position into file, main script must end with 'exit_cleanup' function.
	local function exitscript {
		set scriptend to true.
		set scrposlex["ctrlpan"]["x"] to ctrlbase:x.
		set scrposlex["ctrlpan"]["y"] to ctrlbase:y.
		ctrlbase:dispose().
	}

	// Exit button, calls 'exitscript' function.
	local xitbtn is head1:addbutton("X").
	set xitbtn:tooltip to "Ends the script in a consistent manner.".
	set xitbtn:style:hstretch to false.
	set xitbtn:style:align to "right".
	set xitbtn:style:textcolor to red.
	set xitbtn:onclick to {
		if askexit {
			compactpanel(true).
			xitpane:show.
		}
		else {
			exitscript().
		}
	}.

	local ttfield is 0.
	if ttips {
		local ttbox is ctrlbase:addvlayout().
		set ttfield to ttbox:addhbox().
		local ttdisp is ttfield:addtipdisplay().
		ttfield:hide.
	}

	local shiptitle is head2:addlabel(scriptid+": "+ship:name).
	set shiptitle:style:align to "center".
	set shiptitle:style:hstretch to true.

	local yxit is xitpane:addbutton("Exit").
	set yxit:style:textcolor to red.
	set yxit:onclick to {
		exitscript().
	}.
	local nxit is xitpane:addbutton("Cancel").
	// set nxit:style:textcolor to green.
	set nxit:onclick to {
		xitpane:hide.
		compactpanel(cmpbtn:pressed).
	}.
	xitpane:hide.

	local ipuset is ctrlpan:addhlayout().
	if hasipu {
		local blank is ipuset:addlabel(" ").
		local ipubtn is ipuset:addbutton("IPU:"+config:ipu).
		set ipubtn:tooltip to "'Instructions Per Update' settings. Use the slider or click the IPU value (sometimes twice due to odd kOS onconfirm callback behavior). The unapplied value is displayed in red. To apply the selected value, click the 'set' button.".
		set ipubtn:style:align to "center".
		set ipubtn:style:hstretch to true.
		set ipubtn:style:width to 66.
		if not hasguipos {local blank is ipuset:addlabel(" ").}.
		set ipubtn:toggle to true.
		set ipubtn:ontoggle to {
			parameter tog.
			if tog {
				minipanel("ipuctrl","IPU",false,400,ctrlbase:x-((400-wdth)/2),ctrlbase:y-50,list(true,true)).
				local mpipuset is mpCombolex["ipuctrl"]["vbox"]:addhlayout().
				local ipupane is setValCombo("ipuctrl",mpipuset,"IPU",list(config:ipu,50,2000),{
					parameter slidval.
					set config:ipu to round(slidval,0).
					set ipubtn:text to "IPU:"+config:ipu.
				},0,"i").
			}
			else {
				killgui("ipuctrl").
			}
		}.
	}

	if hasguipos {
		if not hasipu {local blank is ipuset:addlabel(" ").}.
		local guiposbtn is ipuset:addbutton("GUI pos.").
		set guiposbtn:style:align to "center".
		set guiposbtn:style:hstretch to true.
		set guiposbtn:style:width to 66.
		local blank is ipuset:addlabel(" ").
		set guiposbtn:toggle to true.
		set guiposbtn:tooltip to "Opens a minipanel for GUI position save settings. If 'Save on Exit' is checked, GUI positions will be saved when the script ends normally. The 'Save Positions' button saves the current GUI positions. The 'Delete Positions' button deletes the last saved GUI positions file, so the next script start uses defaults. Both 'Save' and 'Delete' disable 'Save on Exit', so positions will not be overwritten when the script exits.".
		set guiposbtn:ontoggle to {
			parameter tog.
			if tog {
				minipanel("guiposctrl","GUI positions",false,400,ctrlbase:x-((400-wdth)/2),ctrlbase:y-50,list(true,true)).
				mpComboChb("guiposctrl","Save on Exit", choose savepos if (defined savepos) else false,{
					parameter tog.
					set savepos to tog.
					return "Save on Exit".
				}).
				mpComboBtn("guiposctrl","Save Positions",{
					set scrposlex["ctrlpan"]["x"] to ctrlbase:x.
					set scrposlex["ctrlpan"]["y"] to ctrlbase:y.
					for gid in guilex:keys {
						set scrposlex[gid]["x"] to guilex[gid]:x.
						set scrposlex[gid]["y"] to guilex[gid]:y.
					}.
					set scrposlex["terminal:width"] to terminal:width.
					set scrposlex["terminal:height"] to terminal:height.
					statmsg("saving GUI positions to: "+guiposfile).
					writejson(scrposlex,guiposfile).
					set mpcombolex["guiposctrl"]["items"]["Save on Exit"]["chbox"]:pressed to false.
				},"",false).
				mpComboBtn("guiposctrl","Delete Positions",{
					statmsg("deleting GUI positions file: "+guiposfile).
					ynmsg(list("Delete GUI positions file?"),red,{
						deletepath(guiposfile).
						if mpcombolex:haskey("guiposctrl") and mpcombolex["guiposctrl"]["items"]:haskey("Save on Exit") {
							set mpcombolex["guiposctrl"]["items"]["Save on Exit"]["chbox"]:pressed to false.
						}
						else {
							set savepos to false.
						}
					}).

				},"",false).
			}
			else {
				killgui("guiposctrl").
			}
		}.
	}

	termbtn(isbtn_term).
	verbosebtn(isbtn_verb).
	debugbtn(isbtn_debg).

	ctrlbase:show().
}

// Function 'termbtn' toggles data printed on the KOS terminal window, where main script was started. Skipping terminal data display can reduce script's loop time and hence improves script's performance.
// Button bar contains either a single button (p = 1) or three buttons (p = 2) where it is possible to show either terminal data, log entries or no data at all.
// Button behavior in the main script is controlled by 'termdata' and 'logwindow' global variables and must be implemented within the main loop (usually at the end). See 'example.ks' for usage example.
function termbtn {
	parameter p is 0.
	if p<>0 {
		if p=1 {
			global trmbtn is ctrlpan:addbutton("Terminal Data").
			set trmbtn:tooltip to "Toggles displaying data in the terminal window. Turning it off can improve performance slightly.".
			set trmbtn:toggle to true.
			set trmbtn:ontoggle to {
				parameter tog.
				set termdata to tog. // global variable
				clearscreen.
			}.
		}
		else if p=2 {
			global termbox is ctrlpan:addhbox().
			global nonebtn is termbox:addbutton("X").
			set nonebtn:tooltip to "Completely toggles off displaying in the terminal window.".
			set nonebtn:style:width to 61.
			set nonebtn:exclusive to true.
			set nonebtn:toggle to true.
			set nonebtn:ontoggle to {
				parameter tog.
				clearscreen.
			}.
			global trmbtn is termbox:addbutton("Term.").
			set trmbtn:tooltip to "Toggles displaying data in the terminal window. Turning it off can improve performance slightly.".
			set trmbtn:style:width to 61.
			set trmbtn:exclusive to true.
			set trmbtn:toggle to true.
			set trmbtn:ontoggle to {
				parameter tog.
				set termdata to tog.
				clearscreen.
			}.
			global logwinbtn is termbox:addbutton("Log").
			set logwinbtn:tooltip to "Toggles the display of log messages in the terminal window.".
			set logwinbtn:style:width to 61.
			set logwinbtn:exclusive to true.
			set logwinbtn:toggle to true.
			set logwinbtn:ontoggle to {
				parameter tog.
				set logwindow to tog. // global variable
				clearscreen.
			}.
		}
	}
}

// Usually, 'verbosebtn' button is used for showing more verbose data on the terminal window, 'debugbtn' for showing even more data for debugging purposes.
// Buttons behavior in the main script is controlled by 'showverbose' and 'showdebug' global variables and must be implemented within the main loop (usually at the end, within 'termbtn' button's functionality). See 'example.ks' for usage example.
function verbosebtn {
	parameter p is 0.
	if p<>0 {
		global vrbbtn is ctrlpan:addbutton("Verbose").
		set vrbbtn:toggle to true.
		set vrbbtn:ontoggle to {
			parameter tog.
			set showverbose to tog. // global variable
			clearscreen.
		}.
	}
}

function debugbtn {
	parameter p is 0.
	if p<>0 {
		global dbgbtn is ctrlpan:addbutton("Debug").
		set dbgbtn:toggle to true.
		set dbgbtn:ontoggle to {
			parameter tog.
			set showdebug to tog. // global variable
			clearscreen.
		}.
	}
}

