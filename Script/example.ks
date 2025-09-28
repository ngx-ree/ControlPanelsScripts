// example.ks by nxg

@lazyglobal off.

global scriptid is "example". // Unique script ID string, used in naming of various configuration or saved files. It must be the script's filename without .ks extension (at least for 'mkl.ks' script to work).
declare parameter goon to false. // Optional input parameter for skipping initial input dialog and going on with default (or pre-saved) input values. If script is started without any parameter (or with parameter set to 'false'), it displays a dialog GUI where input values can be entered. If the script is run with any non-false value (for example run example(1).) it automatically confirms pre-filled values, which are either written in the script itself, or automatically loaded from saved inputs file. In cases where the extended input pane variant is used (where multiple named inputs can be chosen), 'goon' parameter can contain the name of particular saved inputs file.

// The following commands read and apply various library files containing commonly used functions applicable for current script. Functions in this library can be masked by defining them in main (this) script after this library is loaded.
runoncepath("lib/settings.lib.ks"). // Library for basic script's settings, functions for sending log messages and exit cleanup.
runoncepath("lib/common.lib.ks"). // Library containing some common functions used in scripts, usually not related to GUI functions. For example geo functions, checking for commonly used vessel's parts and so on. These functions are usually related to concrete vessel's operations, like identification of certain ship parts and their handling etc. Users will probably create their own variant of 'common.lib.ks' library, reflecting their approach to vessel's operations.
runoncepath("lib/ctrlpanel.lib.ks"). // Basic 'control panel' GUI, typically used for placing various buttons, like button for exiting script and displaying data on terminal screen. It also serves as a container for minimized GUIs, providing means for their restoration.
runoncepath("lib/screen.lib.ks"). // Library containing most of the GUI related functions, providing complex functional GUI elements.
runoncepath("lib/ldsv.lib.ks"). // Library containing functions and elements for saving and loading of presets (PIDs, inputs etc.)

clearscreen.
clearguis().
loadguipos(). // Load GUI positions from a saved file.

// Optional time related variables, 'curtime' contains current number of second elapsed from script's start. Can be used for example in logging messages.
global starttime is time:seconds.
lock curtime to time:seconds-starttime.

global scriptend is false. // Variable controlling script's loop. If TRUE, the script exits gracefully. NOTE that this variable must be defined before 'inputpane' function is called, so that the script could be cancelled (by 'Exit Script' button on basic control panel) before it actually runs, if needed. If you press 'Exit Script' before 'START' on input pane, script will exit right after 'START' is pressed.

// Basic control panel GUI element. Initially placed in top-right screen corner.
// Input parameters:
// true - IPU control button will be created
// true - GUI positions control button will be created
// true - Tooltips button and display field will be created
// currsets["ctrlw"][0] - Initial control panel width, read from current settings ('currsets') lexicon
// currsets["ctrlx"][0],currsets["ctrly"][0] - Initial X and Y position on screen, read from current settings ('currsets') lexicon
// true - When the exit script ('X') button is pressed, script asks for confirmation.
// 1 - 'Terminal Data' button ('global termbtn') will be created in single form. Other parameter form is '2' which provides three buttons: 'Terminal Data', 'Log' and 'X' (nothing).
// 1 - 'Verbose' button ('global verbosebtn') will be created
// 1 - 'Debug' button ('global debugbtn') will be created
// see 'ctrlpanel' function's description in 'ctrlpanel.lib.ks' library for more details
ctrlpanel(true,true,true,currsets["ctrlw"][0],currsets["ctrlx"][0],currsets["ctrly"][0],1,1,1).
set trmbtn:pressed to true. // initially, let's have terminal data turned on

// Here you could override buttons default functions defined in 'ctrlpanel.lib.ks' library. It's not needed now, so functions are commented out.
// 'ontoggle' function masking original 'Verbose' button's function
// set vrbbtn:ontoggle to {
	// parameter tog.
	// set showverbose to tog.
	// clearscreen.
// }.

// 'ontoggle' function masking original 'Debug' button's function
// set dbgbtn:ontoggle to {
	// parameter tog.
	// set showdebug to tog.
	// clearscreen.
// }.

// 'input_data' is a lexicon containing structure for 'inputpane' function, which creates a GUI for entering initial script's parameters (or save/use inputs). Lexicon's entries follow a certain structure depending on the particular input value type. Each lexicon's item format is as follows:
// "variable",list("description",initialvalue,"tooltip text"),
// "variable" - Name of future global variable that will be used. Could be anything, but it's good to have it set to actual variable's identifier string.
// "description" - Descriptive string (something like prompt).
// initialvalue - Initial (default) value of given variable. The variable can be of the following types: scalar, string, boolean and list. Scalar and string variables are entered via textfield, boolean type is represented by a checkbox and list type creates a popup menu.
// In case of popup menus, options are either entered as list's items, or are created dynamically by defined function (see '_VALUE' part below).
// Every particular variable is created as global variable after 'inputpane' function updates its values.
global input_data is lexicon(
"hovralt",list("hover height (m)",50,"The probe's intended initial hovering height."),

"ascdscvel",list("vertical velocity (m/s)",20,"The probe's intended initial ascent (+) or descent (–) velocity. This is only a pre-set value; the actual ascent/descent process is engaged or disengaged by a control button."),

"minvertvel",list("minimal hovr./land. velocity (m/s)",-15,"Minimum allowed descent velocity for hovering/landing (value < 0). If exceeded, the probe's descent velocity is reduced so it does not surpass this value."),

"maxvertvel",list("maximal hovr./land. velocity (m/s)",20,"Maximum allowed ascent velocity for hovering/landing. If exceeded, the probe's ascent velocity is reduced so it does not surpass this value."),

"normvvelcoef",list("hovr./land. vertical velocity coefficient",1,"Coefficient for probe's vertical velocity setpoint based on its altitude above the ground during normal flight (not landing). It serves to reduce vertical speed and avoid overshooting the planned altitude."),

"gimblck",list("initial gimbal lock",true,"If set, engine gimbals will be locked right after the script starts. Engines must have KOS name tag set to 'leng'."),

"autogear",list("initial automatic gear up/down",true,"If TRUE, the probe will automatically raise and lower gear during flight and landing. If landing in a low-fuel emergency, the gear is always lowered, regardless of this option."),

"guphght",list("auto. gear up height (m)",10,"Radar height at which automatic gear up during ascent should happen."),

"gdwnhght",list("auto. gear down height (m)",40,"Radar height at which automatic gear down during landing sequence should happen."),

"lfuellnd",list("initial land on low fuel ",true,"If TRUE, the probe will initiate landing when running on low fuel."),

"minfuel",list("minimum safe fuel (%)",5,"If fuel falls below this value, the landing procedure is automatically initiated."),

"mxlandv",list("max. landing velocity (-m/s)",-2,"Maximum vertical velocity for landing (negative value means descending)."),

"lndvelcoef",list("landing vertical velocity coefficient",10,"Coefficient for probe's landing velocity reduction. During landing, radar altitude divided by this value determines descent velocity (for example: if 10, descent velocity at 100 m will be 10 m/s, at 50 m will be 5 m/s, etc.) until maximum landing velocity is reached."),

"rdland",list("radar landed height (m)",7,"During landing sequence, if probe's radar altitude is less than this value, the probe is considered landed. Depends on probe's dimensions, so measure it before use."),

"vcmltp", list("vectors draw multiplier",15,"Multiplier for quick vector display size."),

"termlog",list("initial terminal log",false,"If TRUE, sending logs to another terminal window will be enabled right after the script starts."),

// The 'cpuid' variable will contain the ID of the KOS CPU, chosen from all available CPUs on the vessel. The list of CPUs is created dynamically, hence the initial list is empty.
"cpuid",list("CPUID for messages",list(),"ID of the KOS log destination terminal window where script logs are sent. The destination terminal must be named (CPUID = KOS name tag) and must be running 'getlogs.ks' script."),

"ldpres",list("load preset at start",false,"If TRUE, the script will load the selected preset right after it starts."),

// The 'preset' variable will contain a PID preset to be initially loaded from disk (in case 'ldpres' is TRUE). The list of presets is created dynamically, hence the initial list is empty. The function that fills this list is defined in 'input_fnc' lexicon below this section.
"preset",list("initial preset",list(),"Saved preset that is automatically loaded at the start if enabled."),

"savepos",list("save gui positions on exit",true,"Saves or discards the last GUI positions after the script finishes."),

"areboot",list("auto reboot on exit",list("no","yes","ask"),"kOS CPU reboot behavior after the script finishes."),


// Popup choice metadata.
"_VALUE",lexicon() // This item must be present here if popup menus will be used.
).


// The lexicon 'input_fnc' contains functions for each dynamically created popup menu options. Each function must return a list containing all usable options (it can be empty if no option is available).
global input_fnc is lexicon(
"cpuid", // Key linking this function to 'cpuid' item.
{ // Anonymous function creating a list of all vessel's available CPUs.
	local lst is list().
	for lcpu in ship:modulesnamed("kOSProcessor") {
		lst:add(lcpu:tag).
	}.
	return lst.
},
"preset", // Key linking this function to 'preset' item.
{ // Anonymous function creating a list of available presets.
	local lst is list().
	savrefresh(lst).
	return lst.
}
).

// The function 'inputpane' updates the 'input_data' lexicon. The update is done either by interactive user input or by loading of saved inputs from file.
// See the 'inputpane' function's description in 'screen.lib.ks' library for more details.
// Input parameters:
// goon - The input parameter of the main script, allows faster script start without need to interact with input pane GUI.
// false - In this case, the non-simpler variant of input pane is used, allowing saving and loading of multiple input parameters presets.
// 2 - The number of the input pane's columns. NOTE that for the non-simple variant the minimum columns is 2, even if this parameter is set to 1.
// currsets["inpx"][0],currsets["inpy"][0] - Initial input pane's X and Y position.
// true - The input pane will have a button and display field for tooltips.
inputpane(goon,false,2,currsets["inpx"][0],currsets["inpy"][0],true).


// The following declarations create global variables for each input pane's entry. Note that some boolean type entries can be later accessed by addressing their status directly in 'input_data' lexicon without the need to create corresponding global variable.
global hovralt is input_data["hovralt"][1].
global ascdscvel is input_data["ascdscvel"][1].

global minvertvel is input_data["minvertvel"][1].
global maxvertvel is input_data["maxvertvel"][1].
global normvvelcoef is input_data["normvvelcoef"][1].

global guphght is input_data["guphght"][1].
global gdwnhght is input_data["gdwnhght"][1].
global minfuel is input_data["minfuel"][1].

global mxlandv is min(-1,input_data["mxlandv"][1]).
global lndvelcoef is input_data["lndvelcoef"][1].
global rdland is input_data["rdland"][1].

global vcmltp is input_data["vcmltp"][1].
global termlog is input_data["termlog"][1].
global cpuid is input_data["cpuid"][1].
global preset is input_data["preset"][1].
global savepos is input_data["savepos"][1].
global areboot is input_data["areboot"][1].


// GLOBALS & LOCKS

// The path to the 'pidfile' file, which contains declarations of variables related to kp, ki, kd and epsilon PID parameters used for PID-related functions defined later (for example 'upd_hovrpid', 'upd_vertvpid' etc.).
// Each ship+script combination can use its specific pidfile. The file secures the declaration of PID parameter variables, which can be edited and saved in different presets.
global pidfile is "etc/"+shipdir+"/"+ship:name+"_"+scriptid+"_PID.include.ks".

// If the pidfile does not exist for a given script+ship combination, it is initially created from a pre-existing template. Template names are linked to the given 'scriptid' and they are placed in 'etc/templates/' subdirectory.
global templfile is "etc/templates/"+scriptid+"_PID.template.ks".

global gupcancel is true.
global gdwncancel is true.
global rotvel is 0.
global set_alt is hovralt.
global mthr is 0.

global trslsbd is 0.
global trsltop is 0.
global trslena is false.
global orircs is rcs.

lock rdalt to alt:radar. // radar altitude
lock vertvel to ship:verticalspeed. // vertical speed

lock updyaw to vang(ship:up:vector,vxcl(ship:facing:upvector, ship:facing:starvector)).
lock updpitch to vang(ship:up:vector,ship:facing:upvector).

lock angdirv to choose 1 if round(vang(ship:angularvel,ship:facing:vector),0)>90 else -1.
lock angvel to round(ship:angularvel:mag,2).

lock slanded to (rdalt<rdland and vertvel<0.1).
lock emergland to (lowfuelprs and fuelpct<=minfuel and not slanded).

lock vectrsbd to vxcl(ship:facing:vector,vxcl(ship:facing:upvector,ship:velocity:surface)).
lock vectrtop to vxcl(ship:facing:vector,vxcl(ship:facing:starvector,ship:velocity:surface)).

/// RESOURCES & PARTS

// liquid fuel
global maxfuel is 0.
for res in ship:resources {
  if res:name = "LiquidFuel" {
	set maxfuel to maxfuel + res:capacity.
  }
}
lock fuelpct to 100*(ship:LiquidFuel/max(1,maxfuel)). //!!! TERM

// solar panels
global haspanels is false.
if not ship:partsdubbed("solpan"):empty {
	lock solpan to ship:partsdubbed("solpan").
	if not badpart(solpan,{
		parameter t.
		if t:hasmodule("ModuleDeployableSolarPanel") {
			return t:getmodule("ModuleDeployableSolarPanel"):hasaction("extend solar panel").
		}
		else {return false.}
	},"(ModuleDeployableSolarPanel):hasaction(extend solar panel)") {
		set haspanels to true.
	}
}
global spextracted is false.

// landing engines
global haslengs is false.
if not ship:partsdubbed("leng"):empty {
	lock lengs to ship:partsdubbed("leng").
	if not badpart(lengs,{
		parameter t.
		if t:hassuffix("hasgimbal") {
			return t:hasgimbal.
		}
		else {
			return false.
		}
	},"engine:hasgimbal") {
		set haslengs to true.
	}
}
else {
	popmsg(list("No engines dubbed 'leng'.","Gimbal lock controls will not be available."),rgb(0.6,0.7,1)).
}


////////////////////// GUI STUFF ////////////////////

// The function 'ctrlmpanel' creates a control multipanel, which can contain multiple independent stacks that can be switched using a popup menu. This multipanel can be hidden by minimizing to the basic control panel. Each stack can contain various GUI elements designed to display and control script functions.
// Input parameters:
// "controls1" - ID for the whole control multipanel. Can be used later for addressing various panel's elements.
// "Probe Control: "+ship:name - Title label.
// list("controls","switches") - This panel will contain two stacks with names (and IDs): 'controls' and 'switches'. These IDs are displayed as choices in the switching popup menu and can be used later for addressing various panel's elements.
// true - If TRUE, the panel will have a textbox on the bottom for displaying 'statmsg' messages.
// true - If TRUE, the panel will have a tooltips button (?) and tooltips display.
// 70 - The panel's width in number of characters. If this value is of 'list' type, it can contain the width of each stack in pixels (note that this value is used for 'gui(width)' creation). Stack with wider width overrides narrower width as soon as it is displayed.
// currsets["ctrlm1x"][0],currsets["ctrlm1y"][0] - Initial X and Y position on screen, read from current settings ('currsets') lexicon.
// See the 'ctrlmpanel' function's description in 'screen.lib.ks' library for more details.
ctrlmpanel("controls1","Probe Control: "+ship:name,list("controls","switches"),true,true,70,currsets["ctrlm1x"][0],currsets["ctrlm1y"][0]).
// The second control multipanel, initially minimized to the basic control panel as 'Probe Machinery' button.
ctrlmpanel("controls2","Probe Machinery",list("machinery settings","PID values"),false,true,list(400,600),currsets["ctrlm2x"][0],currsets["ctrlm2y"][0]).
mingui("controls2"). // This minimizes the 'Probe Machinery' control multipanel after it is created.

// GUI
// The following commands create the particular controlling elements placed on each control multipanel's stack. Note that they do not have to be surrounded by curly brackets, in this case they are used merely for better orientation in code, because they can be folded in most text editors (for example Notepad++). However, if they are used, it is necessary to be mindful of local vs. global declarations, as local variables will not be accessible outside the bracketed block.
{
//// CONTROLS ////
// 'controls' stack
{
// The 'controls' page (stack) usually contains buttons and other GUI elements used for real-time control of the vessel.

// The 'ctrlset010' is a layout for the first line of 'controls' stack (which is part of 'controls1' multipanel). This layout will contain new GUI elements horizontally placed, until the next layout within the stack is defined.
local ctrlset010 is ctrlpanlex["controls1"]["controls"]:addhlayout().

// The 'ctrlaltitude' is a set (combo) of GUI elements created by 'ctrlLRCombo' function. It consists of left ('<<<') button, description, value field, increment slider and right ('>>>') button.
// The combo is typically used for continuous changing of the value of a given variable. The change is done either by direct manual edit in the textfield or by clicking left/right buttons. The increment for changing by buttons can be set by slider. An optional checkbox can have its own function, as well as optional popup menu.
// Input parameters:
// "controls1" - ID of the parent GUI (control multipanel). Although the combo's placement is uniquely identified by 'ctrlset010' layout, this ID is used for later addressing and cleanup procedures.
// ctrlset010 - The GUI layout identifier where this combo is created.
// "Altitude:" - ID (and label) of the combo itself, used later for addressing.
// hovralt:tostring() - The initial displayed value.
// "m" - The used units, meters in this case (set "" if no units are needed).
// true - This combo will have a checkbox.
// See the 'ctrlLRCombo' function's description in 'screen.lib.ks' library for more details.
global ctrlaltitude is ctrlLRCombo("controls1",ctrlset010,"Hovr. height",hovralt:tostring(),"m",true).
// Overriding the label's default (70) width value.
set ctrlCombolex["controls1"]["Hovr. height"]["label"]:style:width to 90.
// The tooltip for the combo's label is referenced to the variable's input pane description in 'input_data' lexicon.
if input_data["hovralt"]:length=3 {set ctrlaltitude["label"]:tooltip to input_data["hovralt"][2].}.

// The 'onclick' function of the left ('<<<') button.
set ctrlaltitude["leftbtn"]:onclick to {
	set hovralt to chkvalalt(hovralt-altstep). // 'hovralt' is the variable which is controlled.
}.

// The combo's textfield 'onconfirm' action. Note that manually entered/edited value must be confirmed either by pressing ENTER or by clicking outside the box.
set ctrlaltitude["txtfield"]:onconfirm to {
	parameter str.
	set hovralt to chkvalalt(str:tonumber(hovralt)).
}.

// The 'ontoggle' function of the combo's checkbox.
set ctrlaltitude["chbox"]:ontoggle to {
	parameter tog.
	steervects(tog,vcmltp). // Show some vectors related to vessel's controls.
}.

// The increment step value taken from slider. Note that locks don't work across files (meaning that locks made in libraries are not available in the main script).
lock altstep to round(ctrlaltitude["slider"]:value,0).

// The 'onclick' function of the right ('>>>') button.
set ctrlaltitude["rightbtn"]:onclick to {
	set hovralt to chkvalalt(hovralt+altstep).
}.

// Evaluation function for the value of the controlled variable. It sets limits and discards invalid values.
local function chkvalalt {
	parameter p.
	local val is round(p,0).
	if val < 1 {set val to 1.}.
	set ctrlaltitude["txtfield"]:text to val:tostring().
	return val.
}.

// The second line (layout) on the control multipanel's stack.
local ctrlset020 is ctrlpanlex["controls1"]["controls"]:addhlayout().

// The 'setvvel' is a set (combo) of GUI elements created by 'setValCombo' function. It consists of descriptive label, value display/edit box, value trigger and apply ('set') button. Optionally it can have a checkbox element between the slider and 'set' button.
// The combo is typically used for changing the variable's value either by manual editing or by slider. However, the value is applied only after the 'set' button is pressed. The unapplied value is displayed in red color in the display/edit box.
// Input parameters:
// "controls1" - ID of the parent GUI (control multipanel). Although the combo's placement is uniquely identified by 'ctrlset020' layout, this ID is used for later addressing and cleanup procedures.
// ctrlset020 - The GUI layout identifier where this combo is created.
// "Vert. velocity" - ID (and label) of the combo itself, used later for addressing.
// list(ascdscvel,-100,100) - The slider parameters, initial value, min. value, max. value.
// {} - The 'set' button's 'onclick' function. The variable 'slidval' contains the slider's value.
// 0 - The rounding decimal places for the slider's value.
// " m/s" - The units, displayed in the display/edit box.
// See the 'setValCombo' function's description in 'screen.lib.ks' library for more details.
global setvvel is setValCombo("controls1",ctrlset020,"Vert. velocity",list(ascdscvel,-100,100),{
	parameter slidval.
	set ascdscvel to slidval. // 'ascdscvel' is the variable which is controlled. 'slidval' is the current value of the slider.
},0," m/s").
// Overriding the label's default (70) width value.
set setVallex["controls1"]["Vert. velocity"]["label"]:style:width to 100.

// The third line (layout) on the control multipanel's stack.
local ctrlset030 is ctrlpanlex["controls1"]["controls"]:addhlayout().

// The following GUI element combination is not frequently used, so it is not defined as a function in 'screen.lib.ks' library, but rather created directly in this main script.
global labrtct is ctrlset030:addlabel("Rotate"). // Descriptive label.
set labrtct:tooltip to "Probe's vertical rotation. This slider takes effect when the 'Enable Rotation' button is pressed.". // Tooltip text for the label.
set labrtct:style:align to "center".
set labrtct:style:width to 70.

global rtctslid is ctrlset030:addhslider(0,-5,5). // Slider controlling direction and angular velocity of vertical rotation. Rotation can gain a maximum of 5 rad/s of angular velocity, either clockwise (-) or counterclockwise (+).
set rtctslid:onchange to {
	parameter slid.
	set rotvel to round(slid,1).
	set rtctlab:text to rotvel:tostring().
}.

global rtctlab is ctrlset030:addlabel(""). // The label for displaying current angular velocity value.
set rtctlab:style:width to 30.
set rtctlab:style:align to "right".
set rtctlab:text to rotvel:tostring().

local rtctunit is ctrlset030:addlabel("rad/s"). // Units.
set rtctunit:style:font to "Consolas".
set rtctunit:style:width to 40.

global rtct0btn is ctrlset030:addbutton("zero"). // Sets the angular velocity slider to 0, stops the vertical rotation.
set rtct0btn:tooltip to "Resets the offset velocity to 0 and centers the offset slider.".
set rtct0btn:style:width to 50.
set rtct0btn:onclick to {
	set rtctslid:value to 0.
	rotcpid:reset().
}.

// The next container (line) for the first set of controlling buttons. This time it is a box instead of layout.
local ctrlset040 is ctrlpanlex["controls1"]["controls"]:addhbox().

// The button engaging/disengaging hovering function.
global thraltprs is false. // The variable 'thraltprs' is used in the main loop for checking whether the button is pressed. It is possible to directly check the button's status ('if thraltbtn:pressed {dosomething.}.'), but checking a global variable instead of the button's status is slightly more efficient performance-wise. It leaves more OPCODESLEFT after the loop (e.g., with IPU=500 and the same functions running, it is: 'example.ks' script 168 vs. 175, 'g66.ks' script 401 vs. 424, 'gtrn.ks' script 325 vs. 331). Also, it is easier to maintain and provides means to alter functionality without actually pressing the button if really necessary (not recommended though...).
global thraltbtn is ctrlset040:addbutton("Hover").
set thraltbtn:tooltip to "Gain or maintain altitude using the main throttle.".
set thraltbtn:toggle to true.
set thraltbtn:ontoggle to {
	parameter tog.
	set thraltprs to tog.
	hovrpid:reset(). // Reset PID status every time the hovering changes.
	if tog {
		statmsg("main throttle engaged"). // Send a log message to the message line (and to the other terminal window if enabled).
		set pitchbtn:pressed to true. // Engage pitch levelling to maintain vertical stability.
		set yawbtn:pressed to true. // Engage yaw levelling to maintain vertical stability.
		set ascdscbtn:pressed to false. // If the 'Asc./Desc.' function was active, turn it off.
		set landbtn:pressed to false. // If the 'Land' function was active, turn it off.
		doautogear("up"). // Prepare gear up at a certain height.
	}
	else {
		set mthr to 0. // If 'Hover' is disengaged, set the main throttle to 0.
	}
}.

global ascdscprs is false. // See the 'global thraltprs is false.' line comment for explanation.
global ascdscbtn is ctrlset040:addbutton("Asc./Desc.").
set ascdscbtn:tooltip to "Maintain ascent or descent velocity set by the 'Vert. velocity' slider using the main throttle.".
set ascdscbtn:toggle to true.
set ascdscbtn:ontoggle to {
	parameter tog.
	set ascdscprs to tog.
	vertvpid:reset().
	if tog {
		statmsg("main throttle engaged").
		set pitchbtn:pressed to true.
		set yawbtn:pressed to true.
		set thraltbtn:pressed to false.
		set landbtn:pressed to false.
		doautogear("up").
	}
	else {
		set mthr to 0.
	}
}.

global rotcprs is false. // See the 'global thraltprs is false.' line comment for explanation.
global rotcbtn is ctrlset040:addbutton("Enable Rotation").
set rotcbtn:tooltip to "Activate rotation control.".
set rotcbtn:toggle to true.
set rotcbtn:ontoggle to {
	parameter tog.
	set rotcprs to tog.
	if tog {
		statmsg("rotation control init.").
	}
	else {
		set SHIP:CONTROL:roll to 0.
	}
}.

global translbtn is ctrlset040:addbutton("Translate").
set translbtn:tooltip to "Probe's translation control minipanel.".
set translbtn:toggle to true.
set translbtn:ontoggle to {
	parameter tog.

	if tog {

		// The function 'minipanel' creates a basis for the minipanel which will serve as a panel for horizontal translation control.
		// Input parameters:
		// "translpan" - The minipanel's ID, its key in 'mpCombolex' lexicon.
		// "Horiz. translation" - The minipanel's title label.
		// true - The minipanel will have a tooltips button ('?') and display field at the bottom.
		// 200 - The base width.
		// guilex["controls1"]:x+550,guilex["controls1"]:y - Initial X and Y screen position relative to the main control panel's position.
		// list(true,true) - The first TRUE means that the minipanel will have a pin ('o') button, the second TRUE means this button will be initially pressed. The pressed pin button means that the minipanel will be always created on its initial position (relative to the main control panel's position). If the pin button is not pressed, the minipanel will remember its last position (as any other GUI element). NOTE that closing the minipanel (e.g., by toggleable button) means it is killed (deconstructed) rather than only hidden.
		// See 'screen.lib.ks' library for more details.
		minipanel("translpan","Horiz. translation",true,200,guilex["controls1"]:x+550,guilex["controls1"]:y,list(true,true)).

		// The function 'mpComboChb' creates a checkbox which serves as a switch for turning translation on/off.
		// Input parameters:
		// "translpan" - ID of the previously created minipanel within which this checkbox is created.
		// "Enable Transl." - The descriptive label as well as the reference ID of this element.
		// trslena - The initial value of the element, in this case it is the TRUE/FALSE state of the checkbox's toggle.
		// {} - The checkbox's 'ontoggle' function. Note that this function must return a string which will be used as the checkbox's descriptive label. This also enables changing the label based on some condition (e.g., ON/OFF based on the toggle).
		// "Enables/disables horizontal translation...." - The tooltip text.
		// See 'screen.lib.ks' library for more details.
		mpComboChb("translpan","Enable Translation",trslena,{
			parameter tog.
			set trslena to tog.
			local chblabel is "Translation: "+(choose "enabled" if trslena else "disabled").
			return chblabel. // Returns the checkbox's descriptive label. It can be changed according to conditions if needed. In this case, the label will show 'Translation: enabled' or 'Translation: disabled' respectively. If you don't want to change the original label, just use 'return "Enable Translation"' command instead.
		},"Enables or disables horizontal translation. Note that RCS must be turned ON for translation to work.").

		// The function 'mpComboLRN' creates a combination of left ('<') and right ('>') buttons and editable value text.
		// Input parameters:
		// "translpan" - ID of the previously created minipanel within which this combo is created.
		// "Starboard" - The descriptive label as well as the reference ID of this element.
		// trslsbd - The initial value of the element, displayed in the combo's textfield.
		// {} - The left button's 'onclick' function. The function must return a value which will be assigned to the combo's value displayed in the textfield.
		// {} - The right button's 'onclick' function. The function must return a value which will be assigned to the combo's value displayed in the textfield.
		// "m/s" - The units label for this combo, displayed at the end of the combo's textfield.
		// "Horizontal starboard translation." - The tooltip text.
		// See 'screen.lib.ks' library for more details.
		mpComboLRN("translpan","Starboard",trslsbd,
		{
			set trslsbd to trslsbd - 1.
			return trslsbd.
		},
		{
			set trslsbd to trslsbd + 1.
			return trslsbd.
		},
		{
			parameter str.
			set trslsbd to str:tonumber(trslsbd).
			return trslsbd.
		},"m/s","Horizontal starboard translation.").

		// The function 'mpComboBtn' creates a clickable button which sets 'trslsbd' (starboard horizontal translation) variable to 0.
		// Input parameters:
		// "translpan" - ID of the previously created minipanel within which this button is created.
		// "sbd zero" - The descriptive label as well as the reference ID of this element.
		// {} - The button's 'onclick' function.
		// "Set starboard translation to 0 m/s." - The combo's tooltip text.
		// false - This means that the combo will not be created below the previous combo, rather than be placed next to it on the right side. The default value of this parameter is TRUE, which means the combo will be created under the previous combo.
		// See 'screen.lib.ks' library for more details.
		mpComboBtn("translpan","sbd zero",{
			set trslsbd to 0.
			set mpCombolex["translpan"]["items"]["Starboard"]["vallbl"]:text to trslsbd:tostring(). // This references the textfield of the previously created 'mpComboLRN' combo and updates its value (0 in this case) with the changed 'trslsbd' variable.
		},"Reset starboard translation to 0 m/s.",false).

		// The following functions 'mpComboLRN' and 'mpComboBtn' work similarly as the previous function set, but for 'Top' translation type.
		mpComboLRN("translpan","Top",trsltop,
		{
			set trsltop to trsltop - 1.
			return trsltop.
		},
		{
			set trsltop to trsltop + 1.
			return trsltop.
		},
		{
			parameter str.
			set trsltop to str:tonumber(trsltop).
			return trsltop.
		},"m/s","Top-wise translation. Note that for the 'elisa 1.0' vessel type, this means horizontal movement perpendicular to starboard movement. In vector drawings, it is the 'facing:upvector' vector.").
		mpComboBtn("translpan","top zero",{
			set trsltop to 0.
			set mpCombolex["translpan"]["items"]["Top"]["vallbl"]:text to trsltop:tostring().
		},"Set top translation to 0 m/s.",false).

	}
	else
	{
		// Kill (deconstruct) the minipanel with "translpan" ID. NOTE that deconstruction of the minipanel means that its elements will not be available until created again.
		killgui("translpan").
	}
}.

local ctrlset050 is ctrlpanlex["controls1"]["controls"]:addhbox().

global rcsbtn is ctrlset050:addbutton("RCS").
set rcsbtn:toggle to true.
set rcsbtn:pressed to rcs.
set rcsbtn:style:width to 70.
set rcsbtn:ontoggle to {
	parameter tog.
	if tog {
		if not rcs {rcs on.}.
	}
	else {
		if rcs {rcs off.}.
	}
}.

global sasbtn is ctrlset050:addbutton("SAS").
set sasbtn:toggle to true.
set sasbtn:pressed to sas.
set sasbtn:style:width to 70.
set sasbtn:ontoggle to {
	parameter tog.
	if tog {
		if not sas {sas on.}.
	}
	else {
		if sas {sas off.}.
	}
}.

global pitchprs is false. // See the 'global thraltprs is false.' line comment for explanation.
global pitchbtn is ctrlset050:addbutton("Keep Pitch").
set pitchbtn:tooltip to "Keep the probe's pitch centered. Note that for the 'elisa 1.0' vessel type (facing upwards), a centered pitch means keeping the vessel vertical (assuming yaw is also centered).".
set pitchbtn:toggle to true.
set pitchbtn:ontoggle to {
	parameter tog.
	set pitchprs to tog.
	ptchpid:reset().
	if tog {
		// rcs on. // Uncomment, if you want to automatically engage RCS when 'Level Pitch' is pressed.
	}
	else
	{
		set ship:control:pitch to 0.
	}
}.

global yawprs is false. // See the 'global thraltprs is false.' line comment for explanation.
global yawbtn is ctrlset050:addbutton("Keep Yaw").
set yawbtn:tooltip to "Keep the probe's yaw centered. Note that for the 'elisa 1.0' vessel type (facing upwards), a centered yaw means keeping the vessel vertical (assuming pitch is also centered).".
set yawbtn:toggle to true.
set yawbtn:ontoggle to {
	parameter tog.
	set yawprs to tog.
	ywpid:reset().
	if tog {
		// rcs on. // Uncomment, if you want to automatically engage RCS when 'Level Pitch' is pressed.
	}
	else
	{
		set SHIP:CONTROL:yaw to 0.
	}
}.


// Resets all internal controls and pops up all buttons except some of them (see below).
local ctrlset060 is ctrlpanlex["controls1"]["controls"]:addhbox().
global rstbtn is ctrlset060:addbutton("Reset Controls").
set rstbtn:tooltip to "Resets all control values and releases all buttons.".
set rstbtn:onclick to {
	wait until btnsoff(ctrlpanlex["controls1"]["controls"],"RCS SAS"). // 'RCS' and 'SAS' buttons will not be popped up. See 'btnsoff' function in 'screen.lib.ks' library for details.
	ctrlreset(true). // Resets all controls. See the function in 'common.lib.ks' library for details.
}.

// Button engaging/disengaging the vessel's landing.
global landprs is false. // See the 'global thraltprs is false.' line comment for explanation.
global landbtn is ctrlset060:addbutton("Land").
set landbtn:tooltip to "Initiates the landing sequence.".
set landbtn:toggle to true.
set landbtn:ontoggle to {
	parameter tog.
	set landprs to tog.
	if tog {
		rtct0btn:onclick(). // Set vertical rotation to 0 by clicking the 'zero' button.
		set rotcbtn:pressed to true. // Engage rotation control to obtain the previously selected 0.
		set thraltbtn:pressed to false. // Disengage hovering if it was active.
		set ascdscbtn:pressed to false. // Disengage ascend/descend if it was active.
		doautogear("down"). // Prepare landing gear down.
		// Landing initiated, stop horizontal movement by setting translation to 0 in both ways.
		set trslsbd to 0.
		set trsltop to 0.
		set trslena to true.
		updtrpanel(). // Update the translation control minipanel's values in case it is opened.
		statmsg("landing init."). // Send a log message about landing initialization.
	}
	else {
		set set_alt to hovralt. // If the landing was disengaged (cancelled) mid-air, return to hovering.
	}
}.
}
// switches stack
{
// The 'switches' page (stack) usually contains controlling elements which are not always necessary for the vessel's control, but rather for some general settings for longer-term usage.

local swtset010 is ctrlpanlex["controls1"]["switches"]:addhbox().
global lckgimchb is swtset010:addcheckbox("Lock Gimbal",false).
set lckgimchb:tooltip to "Locks or unlocks the gimbals of engines with the kOS name tag 'leng'.".
set lckgimchb:toggle to true.
set lckgimchb:ontoggle to {
	parameter tog.
	lock_gimbal(tog).
}.
set lckgimchb:enabled to haslengs.
if haslengs {set lckgimchb:pressed to input_data["gimblck"][1].}.

global lowfuelprs is false. // See the 'global thraltprs is false.' line comment for explanation.
global lowfuelbtn is swtset010:addcheckbox("Land when low on fuel",false).
if input_data["lfuellnd"]:length=3 {set lowfuelbtn:tooltip to input_data["lfuellnd"][2].}.
set lowfuelbtn:toggle to true.
set lowfuelbtn:ontoggle to {
	parameter tog.
	set lowfuelprs to tog.
}.
set lowfuelbtn:pressed to input_data["lfuellnd"][1].


global agearbtn is swtset010:addcheckbox("Autom. gear",false).
if input_data["autogear"]:length=3 {set agearbtn:tooltip to input_data["autogear"][2].}.
set agearbtn:toggle to true.
set agearbtn:pressed to input_data["autogear"][1].


local swtset020 is ctrlpanlex["controls1"]["switches"]:addhbox().
global termlogchb is swtset020:addcheckbox("Terminal Logs",false).
set termlogchb:tooltip to "Send status mesages also to other terminal.".
set termlogchb:toggle to true.
set termlogchb:ontoggle to {
	parameter tog.
	set termlog to tog.
}.
local cpuopts is list().
for lcpu in SHIP:MODULESNAMED("kOSProcessor") {
	cpuopts:add(lcpu:tag).
}
global menucpu is swtset020:addpopupmenu().
if input_data["cpuid"]:length=3 {set menucpu:tooltip to input_data["cpuid"][2].}.
set menucpu:options to cpuopts.
set menucpu:onchange to {
	parameter sel.
	set cpuid to sel.
}.
set menucpu:index to menucpu:options:indexof(cpuid).
set termlogchb:pressed to input_data["termlog"][1] and hasmorecpu().
set termlogchb:enabled to hasmorecpu().
set menucpu:enabled to hasmorecpu().

global solpanprs is false. // See the 'global thraltprs is false.' line comment for explanation.
global solpanbtn is swtset020:addbutton("Ext./Retr. Solar Panels").
set solpanbtn:tooltip to "Extends or retracts solar panels with the kOS name tag 'solpan'.".
global prevtog is false.
set solpanbtn:toggle to true.
set solpanbtn:ontoggle to {
	parameter tog.
	set solpanprs to tog.
	if solpstat():contains("..") {
		if tog<>prevtog {
			statmsg("panels busy").
			set solpanbtn:pressed to prevtog.
		}
	}
	else {
		solpanels(tog).
		set prevtog to tog.
	}
}.
set solpanbtn:enabled to haspanels.
}
// machinery stack
{
// The 'machinery' page (stack), usually part of a different control multipanel than 'controls' and 'switches', contains variables which were, for example, set in the input and are not accessible in the 'controls' and 'switches' pages. Here they can be altered as needed.

// ship title
local machtitle is ctrlpanlex["controls2"]["machinery settings"]:addlabel(ship:name).
set machtitle:style:align to "center".
set machtitle:style:hstretch to true.

local mchset010 is ctrlpanlex["controls2"]["machinery settings"]:addvbox().

// The 'dlgminvertvel' is an identifier of a single machinery line containing the description and value of a given variable.
// Input parameters are:
// "controls2" - ID of the parent GUI (control multipanel).
// mchset010 - The GUI layout identifier where this combo is created.
// "minvertvel" - ID of a given variable as used in 'input_data' lexicon. The label string and tooltip are linked to corresponding values in 'input_data' lexicon.
// {} - The function for the textfield's 'onconfirm'.
// See 'mchnrline' in 'screen.lib.ks' library for more details.
global dlgminvertvel is
mchnrline("controls2",mchset010,"minvertvel",{
	parameter str.
	set minvertvel to str:tonumber(minvertvel).
}).
global dlgmaxvertvel is
mchnrline("controls2",mchset010,"maxvertvel",{
	parameter str.
	set maxvertvel to str:tonumber(maxvertvel).
}).
global dlgnormvvelcoef is
mchnrline("controls2",mchset010,"normvvelcoef",{
	parameter str.
	set normvvelcoef to str:tonumber(normvvelcoef).
}).

local mchset020 is ctrlpanlex["controls2"]["machinery settings"]:addvbox().

global dlgguphght is
mchnrline("controls2",mchset020,"guphght",{
	parameter str.
	set guphght to str:tonumber(guphght).
}).

global dlggdwnhght is
mchnrline("controls2",mchset020,"gdwnhght",{
	parameter str.
	set gdwnhght to str:tonumber(gdwnhght).
}).

global dlglimfuel is
mchnrline("controls2",mchset020,"minfuel",{
   parameter str.
   set minfuel to str:tonumber(minfuel).
}).

local mchset030 is ctrlpanlex["controls2"]["machinery settings"]:addvbox().
global dlglndvel is
mchnrline("controls2",mchset030,"mxlandv",{
	parameter str.
	set mxlandv to str:tonumber(mxlandv).
}).

global dlglndvelcoef is
mchnrline("controls2",mchset030,"lndvelcoef",{
	parameter str.
	set lndvelcoef to str:tonumber(lndvelcoef).
}).

global dlgrdland is
mchnrline("controls2",mchset030,"rdland",{
	parameter str.
	set rdland to str:tonumber(rdland).
}).

local mchset040 is ctrlpanlex["controls2"]["machinery settings"]:addvbox().
global dlgvcmltp is
mchnrline("controls2",mchset040,"vcmltp",{
	parameter str.
	set vcmltp to str:tonumber(vcmltp).
}).
}
}


solpanels(false).

// GUI END
///////////////////////////////////////////////////////////////////////////////////////////////

///////////// PID settings /////////////////
// https://www.csimn.com/CSI_pages/PIDforDummies.html
// http://www.engineers-excel.com/Apps/PID_Simulator/Description.htm

// The following condition checks the presence of the PID parameters file and secures its loading.
global haspids is false.
if exists(pidfile){
	statmsg(pidfile).
	set haspids to true. // The file exists, prepare its loading.
}
else {
	statmsg("WARNING: missing include "+pidfile).
	if exists(templfile){ // If the template for this script (identified by 'scriptid') exists, let's create a PID values file.
		statmsg("Using template "+templfile+"; PID file created.").
		copypath(templfile,pidfile).
		popmsg(list("Using template "+templfile,"PID file created"),green,{},250).
		set haspids to true. // The file was created from template, prepare its loading.
	}
	else { // The template for the current script was not found. The script will later fail on missing variable.
		print "ERROR: missing template "+templfile+"; file base created.".
		statmsg("ERROR: missing template "+templfile+"; file base created.").
		log "// "+ship:name+"; "+scriptid+"; PID include file" to pidfile. // The script creates an empty PID file base, which means it creates a file with correct path in the vessel's subdirectory, but without concrete PID values. These values must be added manually, otherwise the script will keep failing on missing variable.
		popmsg(list("ERROR: missing template "+templfile+"; file base created.","Edit "+pidfile+" file to add PID values."),red,{},250).
		print "Edit "+pidfile+" file to add PID values.".
	}
}

if haspids { // If the PID file is present, let's load it and prepare the PID functions.
runoncepath(pidfile).

// hovering
global hovrpid is pidloop(hovrkp, hovrki, hovrkd, -0.5, 1, hovreps).
global function upd_hovrpid {
	parameter spoint.
	parameter feedback.
	set hovrpid:setpoint to spoint.
	return hovrpid:update(time:seconds, feedback).
}

// vertical velocity, ascending / descending
global vertvpid is pidloop(vertvkp, vertvki, vertvkd, -1, 1, vertveps).
global function upd_vertvpid {
	parameter spoint.
	parameter feedback.
	set vertvpid:setpoint to spoint.
	return vertvpid:update(time:seconds, feedback).
 }

// yaw
global ywpid is pidloop(ywkp, ywki, ywkd, -1, 1, yweps).
global function upd_ywpid {
	parameter spoint.
	parameter feedback.
	set ywpid:setpoint to spoint.
	return ywpid:update(time:seconds, feedback).
}

// pitch
global ptchpid is pidloop(ptchkp, ptchki, ptchkd, -1, 1, ptcheps).
global function upd_ptchpid {
	parameter spoint.
	parameter feedback.
	set ptchpid:setpoint to spoint.
	return ptchpid:update(time:seconds, feedback).
}

// vertical rotation
global rotcpid is pidloop(rotckp, rotcki, rotckd, -1, 1, rotceps).
global function upd_rotcpid {
	parameter spoint.
	parameter feedback.
	set rotcpid:setpoint to spoint.
	return rotcpid:update(time:seconds, feedback).
}
}

// The PID parameters control panel. Usually set up as the second page (stack) of machinery control multipanel.
// The following elements create display/edit GUI for PID parameters values. In general, scalar variables can be added here, not only PID-related.
// This GUI uses a lot of repeating GUI elements, to simplify its building, 'valbox' function was created in 'screen.lib.ks' library.
{
// First, save/load combo is created.
// 'ldsvsset' is a layout identifier, created in the 'controls2' control multipanel, on 'PID values' stack.
local ldsvsset is ctrlpanlex["controls2"]["PID values"]:addhlayout().

// The 'svldbtn' is a function in 'ldsv.lib.ks' library which creates a typically used GUI elements combo for save/load-related operations.
local saveloadbtn1 is svldbtn(ldsvsset).
set saveloadbtn1:ontoggle to { // The 'ontoggle' function must be here, in the main script, due to the initial combo's position relative to the parent GUI position.
	parameter tog.
	saveload(tog,guilex["controls2"]:x,guilex["controls2"]:y-200).
}.

// The function 'savldconf' creates checkboxes for save overwrite confirmation and load confirmation.
local confset is savldconf(ldsvsset).
global saveconfchb1 is confset[0]. // Index 0 refers to 'Confirm save overwrite' checkbox.
global loadconfchb1 is confset[1]. // Index 1 refers to 'Confirm load' checkbox.

// The 'hovrpidset' is a layout for the first line of 'PID values' stack (which is part of the 'controls2' multipanel). This layout will contain boxes for hovering PID parameters.
local hovrpidset is ctrlpanlex["controls2"]["PID values"]:addhbox().

// The function 'valbox' is used to create a display/edit box for a given scalar variable.
// Input parameters:
// "controls2" - ID of the parent GUI (control multipanel).
// hovrpidset - The GUI layout identifier where this combo is created.
// "hovrkp" - The PID parameter identifier, used for addressing later (for example in save/load functions or for updating of displayed value).
// "hovr kp:" - The displayed descriptive label string.
// hovrpid:kp - The initially displayed value.
// {} - The anonymous 'onconfirm' function assigning edited and confirmed string to actual PID parameter (or other variable if needed).
// "vertical velocity, hovering, landing" - The tooltip for the combo's label.
// See the 'valbox' function in 'screen.lib.ks' library for more details.
global hovrkpdlg is valbox("controls2",hovrpidset,"hovrkp","hovr kp:",hovrpid:kp,{
   parameter str.
   set hovrpid:kp to str:tonumber(hovrpid:kp).
},
"vertical velocity, hovering, landing").
// Subsequently, the rest of PID display/edit boxes are added to the line.
global hovrkidlg is valbox("controls2",hovrpidset,"hovrki","hovr ki:",hovrpid:ki,{
   parameter str.
   set hovrpid:ki to str:tonumber(hovrpid:ki).
}).
global hovrkddlg is valbox("controls2",hovrpidset,"hovrkd","hovr kd:",hovrpid:kd,{
   parameter str.
   set hovrpid:kd to str:tonumber(hovrpid:kd).
}).
global hovrepsdlg is valbox("controls2",hovrpidset,"hovreps","hovr eps:",hovrpid:epsilon,{
	parameter str.
	set hovrpid:epsilon to str:tonumber(hovrpid:epsilon).
}).

// The next line, 'vertvpidset' layout is created for the ascend/descend vertical velocity, and boxes are created similarly to the previous line.
local vertvpidset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global vertvkpdlg is valbox("controls2",vertvpidset,"vertvkp","vertv kp:",vertvpid:kp,{
   parameter str.
   set vertvpid:kp to str:tonumber(vertvpid:kp).
},
"Ascend/descend vertical velocity").
global vertvkidlg is valbox("controls2",vertvpidset,"vertvki","vertv ki:",vertvpid:ki,{
   parameter str.
   set vertvpid:ki to str:tonumber(vertvpid:ki).
}).
global vertvkddlg is valbox("controls2",vertvpidset,"vertvkd","vertv kd:",vertvpid:kd,{
   parameter str.
   set vertvpid:kd to str:tonumber(vertvpid:kd).
}).
global vertvepsdlg is valbox("controls2",vertvpidset,"vertveps","vertv eps:",vertvpid:epsilon,{
	parameter str.
	set vertvpid:epsilon to str:tonumber(vertvpid:epsilon).
}).

local ywpidset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global ywkpdlg is valbox("controls2",ywpidset,"ywkp","yw kp:",ywpid:kp,{
   parameter str.
   set ywpid:kp to str:tonumber(ywpid:kp).
},
"ship yaw").
global ywkidlg is valbox("controls2",ywpidset,"ywki","yw ki:",ywpid:ki,{
   parameter str.
   set ywpid:ki to str:tonumber(ywpid:ki).
}).
global ywkddlg is valbox("controls2",ywpidset,"ywkd","yw kd:",ywpid:kd,{
   parameter str.
   set ywpid:kd to str:tonumber(ywpid:kd).
}).
global ywepsdlg is valbox("controls2",ywpidset,"yweps","yw eps:",ywpid:epsilon,{
	parameter str.
	set ywpid:epsilon to str:tonumber(ywpid:epsilon).
}).

local ptchpidset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global ptchkpdlg is valbox("controls2",ptchpidset,"ptchkp","ptch kp:",ptchpid:kp,{
   parameter str.
   set ptchpid:kp to str:tonumber(ptchpid:kp).
},
"ship pitch").
global ptchkidlg is valbox("controls2",ptchpidset,"ptchki","ptch ki:",ptchpid:ki,{
   parameter str.
   set ptchpid:ki to str:tonumber(ptchpid:ki).
}).
global ptchkddlg is valbox("controls2",ptchpidset,"ptchkd","ptch kd:",ptchpid:kd,{
   parameter str.
   set ptchpid:kd to str:tonumber(ptchpid:kd).
}).
global ptchepsdlg is valbox("controls2",ptchpidset,"ptcheps","ptch eps:",ptchpid:epsilon,{
	parameter str.
	set ptchpid:epsilon to str:tonumber(ptchpid:epsilon).
}).

local rotcpidset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global rotckpdlg is valbox("controls2",rotcpidset,"rotckp","rotc kp:",rotcpid:kp,{
   parameter str.
   set rotcpid:kp to str:tonumber(rotcpid:kp).
},
"rotation").
global rotckidlg is valbox("controls2",rotcpidset,"rotcki","rotc ki:",rotcpid:ki,{
   parameter str.
   set rotcpid:ki to str:tonumber(rotcpid:ki).
}).
global rotckddlg is valbox("controls2",rotcpidset,"rotckd","rotc kd:",rotcpid:kd,{
   parameter str.
   set rotcpid:kd to str:tonumber(rotcpid:kd).
}).
global rotcepsdlg is valbox("controls2",rotcpidset,"rotceps","rotc eps:",rotcpid:epsilon,{
	parameter str.
	set rotcpid:epsilon to str:tonumber(rotcpid:epsilon).
}).

local trncoefset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global csbddlg is valbox("controls2",trncoefset,"csbd","sbd coef.:",csbd,{
   parameter str.
   set csbd to str:tonumber(csbd).
},"transl. multiplier, starboard").
global ctopdlg is valbox("controls2",trncoefset,"ctop","top coef.:",ctop,{
   parameter str.
   set ctop to str:tonumber(ctop).
},"transl. multiplier, top").
}

// FUNCTIONS

// This function is defined in 'common.lib.ks' library, but the library version does not fit for 'elisa' vehicle type. It returns a list of two values, indicating the vehicle's horizontal direction (forward, backward, left, right).
function vdir {
	local veldir is list(0,0).

	if vang(vectrsbd,ship:facing:starvector)<90 {

		set veldir[0] to 1.
	}
	else {
		set veldir[0] to -1.
	}
	if vang(vectrtop,ship:facing:upvector)<90 {
		set veldir[1] to 1.
	}
	else {
		set veldir[1] to -1.
	}
	return veldir.
}

// Update vertical velocity setpoint based on the intended height.
// This is also used for the landing procedure (value -1).
function vvelset {
	local retval is 0.
	if set_alt = -1 { //landing
		set retval to min(mxlandv,((-rdalt)/lndvelcoef)).
	}
	else {
		set retval to ((set_alt-rdalt)/normvvelcoef).
	}
	set retval to min(maxvertvel,max(retval,minvertvel)).
	return retval.
}

// The function 'doautogear' handles triggers related to automatic gear functionality.
// Of course this could also be done in the main loop, but we will save a tiny bit of performance by checking the condition only when the trigger exists, instead of in every loop.
function doautogear {
	parameter p.

	if p="up" {
		if agearbtn:pressed {
			if rdalt<guphght {
				set gupcancel to false.
				when rdalt>=guphght or gupcancel then {
					if gupcancel {
						statmsg("auto gear up cancelled").
					}
					else {
						gear off.
						statmsg("auto gear up executed at "+round(rdalt,2)+" m").
					}
				}
				statmsg("auto gear up trigger created for "+guphght+" m").
			}
			else {
				gear off.
			}
		}
	}
	else if p="down" {
		if agearbtn:pressed or emergland {
			set gdwncancel to false.
			when rdalt<=gdwnhght or gdwncancel then {
				if gdwncancel {
					statmsg("auto gear down cancelled").
				}
				else {
					gear on.
					statmsg("auto gear down executed at "+round(rdalt,2)+" m").
				}
			}
			statmsg("auto gear down trigger created for "+gdwnhght+" m").
		}
	}
}

// Function 'updtrpanel' updates translation control minipanel's values.
function updtrpanel {
	if defined mpCombolex and mpCombolex:haskey("translpan") { // Does minipanel for translation control exist (is it opened)?
		set mpCombolex["translpan"]["items"]["Enable Translation"]["chbox"]:pressed to trslena. // Press checkbox accordingly ('trslena' variable can be automatically set to 0 when landing is initiated).
		// Next, update values of both numerical combos (for Starboard and Top movements).
		set mpCombolex["translpan"]["items"]["Starboard"]["vallbl"]:text to trslsbd:tostring().
		set mpCombolex["translpan"]["items"]["Top"]["vallbl"]:text to trsltop:tostring().

	}
}

// The function 'steervects' draws some vectors related to the vessel's movement.
function steervects {
	parameter d.
	parameter mltp is 15.
	if (d) {

		global shtopvec is vecdraw(
			V(0,0,0),
			vectrtop*mltp,
			RGB(1,0,1),
			"vectrtop",
			1.0,
			true,
			0.2
		).
		set shtopvec:vecupdater to {return vectrtop*mltp.}.

		global shsbdvec is vecdraw(
			V(0,0,0),
			vectrsbd*mltp,
			RGB(1,0,1),
			"vectrsbd",
			1.0,
			true,
			0.2
		).
		set shsbdvec:vecupdater to {return vectrsbd*mltp.}.

		global shfacup is vecdraw(
			V(0,0,0),
			ship:facing:upvector*mltp,
			RGB(0,1,1),
			"facing:upvector",
			1.0,
			true,
			0.2
		).
		set shfacup:vecupdater to {return ship:facing:upvector*mltp.}.

		global shfacstar is vecdraw(
			V(0,0,0),
			ship:facing:starvector*mltp,
			RGB(0,1,1),
			"facing:starvector",
			1.0,
			true,
			0.2
		).
		set shfacstar:vecupdater to {return ship:facing:starvector*mltp.}.

		global shfacvec is vecdraw(
			V(0,0,0),
			ship:facing:vector*mltp,
			RGB(0,0,1),
			"facing:vector",
			1.0,
			true,
			0.2
		).
		set shfacvec:vecupdater to {return ship:facing:vector*mltp.}.

		global shangvel is vecdraw(
			V(0,0,0),
			ship:angularvel*mltp,
			RGB(0,0,1),
			"angularvel",
			1.0,
			true,
			0.2
		).
		set shangvel:vecupdater to {return ship:angularvel*mltp.}.

		global velvect is vecdraw(
			V(0,0,0),
			ship:velocity:surface*mltp,
			RGB(1,1,1),
			"velocity",
			1.0,
			true,
			0.2
		).
		set velvect:vecupdater to {return ship:velocity:surface*mltp.}.

	}
	else {
		set shtopvec:vecupdater to DONOTHING.
		set shsbdvec:vecupdater to DONOTHING.
		set shfacup:vecupdater to DONOTHING.
		set shfacstar:vecupdater to DONOTHING.
		set shfacvec:vecupdater to DONOTHING.
		set shangvel:vecupdater to DONOTHING.
		set velvect:vecupdater to DONOTHING.
		set shtopvec to 0.
		set shsbdvec to 0.
		set shfacup to 0.
		set shfacstar to 0.
		set shfacvec to 0.
		set shangvel to 0.
		set velvect to 0.
	}
}

// The function 'savvalsload' processes values in 'savvals' lexicon that was loaded from a .json file. The function is called in the loading process after 'readjson' command and ensures that the lexicon's values will be assigned to the corresponding script's variables. Of course, other processing for the loaded values can be performed here, if necessary.
function savvalsload {

	set hovrpid:kp to savvals["hovrkp"]. // The value of the "hovrkp" key of 'savvals' lexicon is assigned to 'hovrpid:kp' variable. The lexicon was previously loaded from a .json file.
	set hovrkpdlg["txtfield"]:text to hovrpid:kp:tostring(). // The text value in the PID control panel showing/editing 'hovrpid:kp' parameter is updated by the currently loaded and assigned value.
	set hovrpid:ki to savvals["hovrki"]. // Similar to the previous commands, continues for all the loaded PID properties below.
	set hovrkidlg["txtfield"]:text to hovrpid:ki:tostring().
	set hovrpid:kd to savvals["hovrkd"].
	set hovrkddlg["txtfield"]:text to hovrpid:kd:tostring().
	set hovrpid:epsilon to savvals["hovreps"].
	set hovrepsdlg["txtfield"]:text to hovrpid:epsilon:tostring().

	set vertvpid:kp to savvals["vertvkp"].
	set vertvkpdlg["txtfield"]:text to vertvpid:kp:tostring().
	set vertvpid:ki to savvals["vertvki"].
	set vertvkidlg["txtfield"]:text to vertvpid:ki:tostring().
	set vertvpid:kd to savvals["vertvkd"].
	set vertvkddlg["txtfield"]:text to vertvpid:kd:tostring().
	set vertvpid:epsilon to savvals["vertveps"].
	set vertvepsdlg["txtfield"]:text to vertvpid:epsilon:tostring().

	set ywpid:kp to savvals["ywkp"].
	set ywkpdlg["txtfield"]:text to ywpid:kp:tostring().
	set ywpid:ki to savvals["ywki"].
	set ywkidlg["txtfield"]:text to ywpid:ki:tostring().
	set ywpid:kd to savvals["ywkd"].
	set ywkddlg["txtfield"]:text to ywpid:kd:tostring().
	set ywpid:epsilon to savvals["yweps"].
	set ywepsdlg["txtfield"]:text to ywpid:epsilon:tostring().

	set ptchpid:kp to savvals["ptchkp"].
	set ptchkpdlg["txtfield"]:text to ptchpid:kp:tostring().
	set ptchpid:ki to savvals["ptchki"].
	set ptchkidlg["txtfield"]:text to ptchpid:ki:tostring().
	set ptchpid:kd to savvals["ptchkd"].
	set ptchkddlg["txtfield"]:text to ptchpid:kd:tostring().
	set ptchpid:epsilon to savvals["ptcheps"].
	set ptchepsdlg["txtfield"]:text to ptchpid:epsilon:tostring().

	set rotcpid:kp to savvals["rotckp"].
	set rotckpdlg["txtfield"]:text to rotcpid:kp:tostring().
	set rotcpid:ki to savvals["rotcki"].
	set rotckidlg["txtfield"]:text to rotcpid:ki:tostring().
	set rotcpid:kd to savvals["rotckd"].
	set rotckddlg["txtfield"]:text to rotcpid:kd:tostring().
	set rotcpid:epsilon to savvals["rotceps"].
	set rotcepsdlg["txtfield"]:text to rotcpid:epsilon:tostring().

	set csbd to savvals["csbd"].
	set csbddlg["txtfield"]:text to csbd:tostring().
	set ctop to savvals["ctop"].
	set ctopdlg["txtfield"]:text to ctop:tostring().

}

// The function 'savvalssave' fills 'savvals' lexicon with the values of variables to be saved. The function is called before the 'writejson' command in the saving process.
function savvalssave {

	set savvals["hovrkp"] to hovrpid:kp. // Assign 'hovrpid:kp' value to "hovrkp" key of 'savvals' lexicon. The lexicon will be then saved in .json format.
	set savvals["hovrki"] to hovrpid:ki. // Similar to previous commands, continues for all PID properties below to be saved.
	set savvals["hovrkd"] to hovrpid:kd.
	set savvals["hovreps"] to hovrpid:epsilon.

	set savvals["vertvkp"] to vertvpid:kp.
	set savvals["vertvki"] to vertvpid:ki.
	set savvals["vertvkd"] to vertvpid:kd.
	set savvals["vertveps"] to vertvpid:epsilon.

	set savvals["ywkp"] to ywpid:kp.
	set savvals["ywki"] to ywpid:ki.
	set savvals["ywkd"] to ywpid:kd.
	set savvals["yweps"] to ywpid:epsilon.

	set savvals["ptchkp"] to ptchpid:kp.
	set savvals["ptchki"] to ptchpid:ki.
	set savvals["ptchkd"] to ptchpid:kd.
	set savvals["ptcheps"] to ptchpid:epsilon.

	set savvals["rotckp"] to rotcpid:kp.
	set savvals["rotcki"] to rotcpid:ki.
	set savvals["rotckd"] to rotcpid:kd.
	set savvals["rotceps"] to rotcpid:epsilon.

	set savvals["csbd"] to csbd.
	set savvals["ctop"] to ctop.

}

// TRIGGERS

// Turn RCS on when horizontal translation is enabled and return RCS to its original state when translation is disabled.
on trslena {
	local msgtxt is "".

	if trslena {
		set orircs to rcs.
		rcs on.
		set msgtxt to "enabled".
	}
	else {
		set rcs to orircs.
		set msgtxt to "disabled".
		set ship:control:starboard to 0.
		set ship:control:top to 0.

	}
	updtrpanel(). // Update translation control minipanel's values in case it is opened.
	statmsg ("horizontal translation "+msgtxt).
	return true.
}

chkpreset(input_data["ldpres"][1],input_data["preset"][1]). // Load the initial preset if selected.
ctrlreset(false). // Reset all control values, just in case some locks remained from previous actions.


// Check if the IPU is sufficient.
if config:ipu<500 {
	// If the IPU is below 500, show a Yes/No message offering IPU increase.
	// The function 'ynmsg' pops a message with text and YES/NO buttons.
	// Input parameters:
	// list("line1","line2") - The message box text lines.
	// red - The message text color.
	// {} - The first function is called when the 'YES' button is pressed.
	// {} - The second function is for the 'NO' button, doing nothing in this case.
	// true - Whether the script should wait for 'YES' or 'NO' button press. DO NOT USE 'true' WITHIN THE LOOP!
	ynmsg(list("Current IPU ("+config:ipu+") is too low.","Script will not run correctly.","","Increase IPU to 500?","(use kOS settings or 'IPU' button on Control Panel for even higher values.)"),red,
	{
		set config:ipu to 500.
	},
	{
	},true).
}

global looptime is 0.
statmsg("probe ready").

// Terminal window columns declared as global variables.
// Global variable lookup is significantly faster than lexicon key lookup, which is particulary noticeable in loops.!!! test
global tclmn1 is currsets["tclmn1"][0].
global tclmn2 is currsets["tclmn2"][0].
global tclmn3 is currsets["tclmn3"][0].

until scriptend {
	set looptime to time:seconds.

	if ship:control:pilotmainthrottle>0 {set ship:control:pilotmainthrottle to 0.}. // block accidental throttle input

	if set_alt>-1 {set set_alt to hovralt.}.

	if pitchprs {set ship:control:pitch to upd_ptchpid(90,updpitch).}.
	if yawprs {set ship:control:yaw to upd_ywpid(90,updyaw).}.
	if rotcprs {set ship:control:roll to (min(1,upd_rotcpid(rotvel,angvel*angdirv))).}.

	// Landing
	if landprs {
		if set_alt>-1 and (vectrsbd:mag*vdir()[0]+vectrtop:mag*vdir()[1]) < 0.1 { // If translation is stopped,
			set set_alt to -1. // initiate landing.
		}
		if slanded { // vessel is on the ground
			if ship:angularvel:mag < 0.1 { // If it is not moving, turn everything off.
				wait until btnsoff(ctrlpanlex["controls1"]["controls"],"RCS SAS").
				statmsg("landed").
				ctrlreset(true).
				set gupcancel to true.
				set gdwncancel to true.
				set trslena to false.
			}
			else { // If it is still moving, press it against the ground (if RCS is on).
				set ship:control:fore to -1.
			}
		}
	}
	else {
		if emergland {
			statmsg("fuel running out, landing...").
			set landbtn:pressed to true.
		}
	}

	// hovering/landing
	if thraltprs or landprs {
		set mthr to upd_hovrpid(vvelset(),vertvel).
	}

	// ascend/descend
	if ascdscprs {
		set mthr to upd_vertvpid(ascdscvel,vertvel).
	}

	// horizontal translation
	if trslena {
		set ship:control:starboard to (trslsbd-(vectrsbd:mag*vdir()[0]))*csbd.
		set ship:control:top to (trsltop-(vectrtop:mag*vdir()[1]))*ctop.
	}

	set ship:control:mainthrottle to mthr.

	print "OPCODESLEFT: ["+OPCODESLEFT+"]   " at(tclmn1,0). print "curtime: ["+round(curtime,1)+"]   " at(tclmn2,0). print "loop:["+(time:seconds-looptime)+"]----------" at(tclmn3,0).

	if termdata {
		print "radar alt.: ["+round(rdalt,1)+"]   " at(tclmn1,2). print "vertical vel.: ["+round(vertvel,1)+"]   " at(tclmn2,2).
		print "angular vel.: ["+round(angvel,2)+"]   " at(tclmn1,3). print "ang. vel. direction: ["+angdirv+"]   " at(tclmn2,3).
		print "main throttle: ["+round(mthr,1)+"]   " at(tclmn1,4). print "fuel left: ["+round(fuelpct,1)+"%]   " at(tclmn2,4).
		print "pid preset: ["+savsuffix+"]   " at(tclmn1,5).

		if showverbose {
			print "pitch: ["+round(ship:control:pitch,1)+"]   " at(tclmn1,7). print "yaw: ["+round(ship:control:yaw,1)+"]   " at(tclmn2,7). print "roll: ["+round(ship:control:roll,1)+"]   " at(tclmn3,7).
			print "angularvel:x: ["+round(ship:angularvel:x,2)+"]    " at (tclmn1,9).
			print "trns:sbd: ["+round(vectrsbd:mag*vdir()[0],2)+"]    " at (tclmn2,9).
			print "angularvel:y: ["+round(ship:angularvel:y,2)+"]    " at (tclmn1,10).
			print "trns:top: ["+round(vectrtop:mag*vdir()[1],2)+"]    " at (tclmn2,10).
			print "angularvel:z: ["+round(ship:angularvel:z,2)+"]    " at (tclmn1,11).
			print "landed: "+slanded at (0,13).
		}
		if showdebug {
			print "hovrpid: ["+hovrpid+"]--------" at(tclmn1,15).
			print "vertvpid: ["+vertvpid+"]--------" at(tclmn1,16).
			print "ywpid: ["+ywpid+"]--------" at(tclmn1,17).
			print "ptchpid: ["+ptchpid+"]--------" at(tclmn1,18).
			print "rotcpid: ["+rotcpid+"]--------" at(tclmn1,19).
		}
	}

	wait 0.
}

if haslengs {lock_gimbal(false).}.
ctrlreset(true).

if areboot="yes" {exit_cleanup().reboot.}
else if areboot="ask" {ynmsg(list("Reboot CPU?"),red,{exit_cleanup().reboot.},{},true).}.
exit_cleanup(). // The proper disposal of all GUIs, cleaning up all lexicons and saving the final GUIs' positions.