// ht3.ks by nxg

@lazyglobal off.

global scriptid is "ht3".
declare parameter goon to (not hastarget).
runoncepath("lib/settings.lib.ks").
runoncepath("lib/common.lib.ks").
runoncepath("lib/screen.lib.ks").
runoncepath("lib/ctrlpanel.lib.ks").
runoncepath("lib/ldsv.lib.ks").

clearscreen.
clearguis().
loadguipos().

global starttime is time:seconds.
lock curtime to time:seconds-starttime.
global scriptend is false.

ctrlpanel(true,true,true,currsets["ctrlw"][0],currsets["ctrlx"][0],currsets["ctrly"][0],1,0,1).
set trmbtn:pressed to true.

global input_data is lexicon(
"inhld",list("initial hold position",false,"If TRUE, the 'Hold Pos.' button will be pressed right after the script starts."),
"hldpoint",list("initial hold method",list("none","D Dist.","D Vel.","D both"),"Initial selection of the holding position method. See tooltips of individual buttons for details."),
"tgtwait",list("wait for target set (s)",1,"When switching targets in KSP, the vessel enters a 'no target' state for a short time. This value determines the script execution pause time during the switching process to prevent exit due to a 'no target' error."),
"arstpos",list("initial auto reset position",true,"If TRUE, 'auto reset position' will be enabled right after the script starts. See the checkbox tooltip for details."),
"intrns",list("initial translation enabled",false,"If TRUE, translation controls will be enabled right after the script starts."),
"trnincr",list("init. translate increment (m/s)",1,"Initial translation increment settings (see label tooltip for more details)."),
"inrots",list("initial rotation enabled",false,"If TRUE, rotation controls will be enabled right after the script starts."),
"rotincr",list("init. rotation increment (dg)",5,"Initial rotation increment settings (see label tooltip for more details)."),
"tdistl",list("tgt. distance low (m)",200,"Initial minimum target distance for the automatic translation stop ('Stop When') function."),
"tdistg",list("tgt. distance high (m)",1000,"Initial maximum target distance for the automatic translation stop ('Stop When') function."),
"vcmltp", list("vectors draw multiplier",15,"Multiplier for quick vector display size."),
"termlog",list("initial terminal log",false,"If TRUE, sending logs to another terminal window will be enabled right after the script starts."),
"cpuid",list("CPUID for messages",list(),"ID of the kOS log destination terminal window where script logs are sent. The destination terminal must be named (CPUID = kOS name tag) and must be running the 'getlogs.ks' script."),
"ldpres",list("load preset at start",false,"If TRUE, the script will load the selected preset right after it starts."),
"preset",list("initial preset",list(),"Saved preset that is automatically loaded at the start if enabled."),
"savepos",list("save gui positions on exit",true,"Saves or discards the last GUI positions after the script finishes."),
"areboot",list("auto reboot on exit",list("no","yes","ask"),"kOS CPU reboot behavior after the script finishes."),

// POPUP choice metadata
"_VALUE",lexicon()
).

global input_fnc is lexicon(
"cpuid",
{
	local lst is list().
	for lcpu in ship:modulesnamed("kOSProcessor") {
		lst:add(lcpu:tag).
	}
	return lst.
},
"preset",
{
	local lst is list().
	savrefresh(lst).
	return lst.
}
).

// set input_data to inputpane(input_data,goon,2,currsets["inpx"][0],currsets["inpy"][0],true).
inputpane(goon,false,2,currsets["inpx"][0],currsets["inpy"][0],true).

// input values globalized
global hldpoint is input_data["hldpoint"][1].
global tgtwait is input_data["tgtwait"][1].
global trnincr is input_data["trnincr"][1].
global rotincr is input_data["rotincr"][1].
global tdistl is input_data["tdistl"][1].
global tdistg is input_data["tdistg"][1].
global vcmltp is input_data["vcmltp"][1].
global termlog is input_data["termlog"][1].
global cpuid is input_data["cpuid"][1].
global preset is input_data["preset"][1].
global savepos is input_data["savepos"][1].
global areboot is input_data["areboot"][1].

// initial target settings; if no target, exit immediately
if hastarget {
	global mytgt is target.
	global prevtgt is target.
	global docktgt is 0.
}
else {
	set scriptend to true.
}

// GLOBALS & LOCKS
global pidfile is "etc/"+shipdir+"/"+ship:name+"_"+scriptid+"_PID.include.ks".
global templfile is "etc/templates/"+scriptid+"_PID.template.ks".

global tgtdx is 0.
global rvelx is 0.
global tgtdy is 0.
global rvely is 0.
global tgtdz is 0.
global rvelz is 0.

global coefc1 is 5.
global coefc2 is 1.
global coefc3 is 1.

global initdir is v(0,0,0).
global dockdir is v(0,0,0).

global distraw is true.
global velraw is true.

global shipfored is 0.
global shiptopd is 0.
global shipsidd is 0.
global shipforev is 0.
global shiptopv is 0.
global shipsidv is 0.

global dshipfored is 0.
global dshiptopd is 0.
global dshipsidd is 0.
global dshipforev is 0.
global dshiptopv is 0.
global dshipsidv is 0.

global trnsdist is v(0,0,0).
global trnsvel is v(0,0,0).

global trnfwbck is 0.
global trnlftrgh is 0.
global trnupdwn is 0.

global rotroll is 0.
global rotyaw is 0.
global rotpitch is 0.

global shornt is ship:facing.

global rawlx is lexicon(
true,"RAW",
false,"PID"
).
lexcleanup:add(rawlx).

global tdistlprs is false.
global tdistgprs is false.
global nllwhenactive is false.

lock yawdifang to round(vang(vxcl(ship:facing:topvector,ship:facing:forevector),vxcl(ship:facing:topvector,shornt:forevector)),0).
lock pitchdifang to round(vang(vxcl(ship:facing:starvector,ship:facing:forevector),vxcl(ship:facing:starvector,shornt:forevector)),0).
lock rolldifang to round(vang(ship:facing:topvector,shornt:topvector),0).

// monopropellant
global maxfuel is 0.
for res in ship:resources {
  if res:name = "monopropellant" {
	set maxfuel to maxfuel + res:capacity.
  }
}
lock fuelpct to 100*(ship:monopropellant/max(1,maxfuel)).

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

////////////////////// GUI STUFF ////////////////////

ctrlmpanel("controls1","Probe Control: "+ship:name,list("controls","switches"),true,true,60,currsets["ctrlm1x"][0],currsets["ctrlm1y"][0]).
ctrlmpanel("controls2","Probe Machinery",list("machinery settings","PID values"),false,true,list(400,600),currsets["ctrlm2x"][0],currsets["ctrlm2y"][0]).
mingui("controls2").

// GUI
{
//// CONTROLS ////
{
local tgtlabel is ctrlpanlex["controls1"]["controls"]:addhbox().
global labtarget is tgtlabel:addlabel("none").
set labtarget:style:align to "center".

local ctrlset010 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global rstposchb is ctrlset010:addcheckbox("Auto Reset Pos.").
set rstposchb:tooltip to "If enabled, the script resets the vessel's position after each 'Hold Pos.' button press, which means the vessel will stop right where it is positioned. If disabled, 'Hold Pos.' will make the vessel return to its last set position.".
set rstposchb:toggle to true.
set rstposchb:pressed to input_data["arstpos"][1].

local entrnbox is ctrlset010:addhbox().
global trnenaprs is false.
global trnenachb is entrnbox:addcheckbox("Enable
Translation").
set trnenachb:tooltip to "Enables translation controls by GUI buttons. Each transl. button press increases (or decreases) translation speed relative to target by given increment value (in m/s). 'Stop' button sets translation speed to 0. Recommended to use with SAS on.".
set trnenachb:toggle to true.
set trnenachb:ontoggle to {
	parameter tog.
	if tog {rcs on.}.
	trnena(tog).
	set trnenaprs to tog.
}.
set trnenachb:pressed to input_data["intrns"][1].
global shtransvchb is entrnbox:addcheckbox(">>",false).
set shtransvchb:tooltip to "Quick display of translation controls related vectors.".
set shtransvchb:toggle to true.
set shtransvchb:ontoggle to {
	parameter tog.
	transvects(tog,vcmltp).
}.

local enrotbox is ctrlset010:addhbox().
global rotenaprs is false.
global rotenachb is enrotbox:addcheckbox("Enable
Rotation").
set rotenachb:tooltip to "Enables rotation controls by GUI buttons. Each button press increases (or decreases) rotation relative to initial rotation (in degrees) by increment value.".
set rotenachb:toggle to true.
set rotenachb:ontoggle to {
	parameter tog.
	rotena(tog).
	set rotenaprs to tog.
	if tog {
		set shornt to ship:facing.
		sas off.
		lock steering to shornt.
	}
	else {
		unlock steering.
	}
}.
set rotenachb:pressed to input_data["inrots"][1].
global shrotvchb is enrotbox:addcheckbox(">>",false).
set shrotvchb:tooltip to "Quick display of rotation controls related vectors.".
set shrotvchb:toggle to true.
set shrotvchb:ontoggle to {
	parameter tog.
	rotvects(tog,vcmltp).
}.

local ctrlset020 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global hldonprs is false.
global hldonbtn is ctrlset020:addbutton("Hold Pos.").
set hldonbtn:tooltip to "Engages 'hold target' function, uses RCS to maintain current vessel distance to selected target. Must be used along with one of position holding methods ('D Dist.', 'D vel.' or 'D both').".
set hldonbtn:toggle to true.
set hldonbtn:ontoggle to {
	parameter tog.
	set hldonprs to tog.
	// statmsg("hold position:"+tog).
	if tog {
		rcs on.
		trnnulltbtn:onclick().
		set trnenachb:pressed to false.
	}
	else {
		setpos(false).
	}
}.
global hldposbtn is ctrlset020:addbutton("Reset Pos.").
set hldposbtn:tooltip to "Manually sets current vessel position as initial position for 'hold target' function.".
set hldposbtn:onclick to {
	setpos(true).
}.

local ctrlset030 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global hlddistprs is false.
global hlddistbtn is ctrlset030:addbutton("D Dist.").
set hlddistbtn:tooltip to "Use x,y,z target distance differences to hold position, maintain those diffs (close) to 0. Do not care about velocity difference.".
set hlddistbtn:toggle to true.
set hlddistbtn:ontoggle to {
	parameter tog.
	set hlddistprs to tog.
	if tog {
		set hldbothbtn:pressed to false.
		set hldvelbtn:pressed to false.
	}
}.
global hldvelprs is false.
global hldvelbtn is ctrlset030:addbutton("D Vel.").
set hldvelbtn:tooltip to "Use relative x,y,z target velocity differences to hold position, maintain those diffs (close) to 0. Do not care about distance difference.".
set hldvelbtn:toggle to true.
set hldvelbtn:ontoggle to {
	parameter tog.
	set hldvelprs to tog.
	if tog {
		set hldbothbtn:pressed to false.
		set hlddistbtn:pressed to false.
	}
}.
global hldbothprs is false.
global hldbothbtn is ctrlset030:addbutton("D both").
set hldbothbtn:tooltip to "Use both relative x,y,z target velocity and distance differences to hold position, maintain those diffs (close) to 0.".
set hldbothbtn:toggle to true.
set hldbothbtn:ontoggle to {
	parameter tog.
	set hldbothprs to tog.
	if tog {
		set hlddistbtn:pressed to false.
		set hldvelbtn:pressed to false.
	}
}.
global hldpointlex is lexicon(
"none","",
"D Dist.",hlddistbtn,
"D Vel.",hldvelbtn,
"D both",hldbothbtn
).
lexcleanup:add(hldpointlex).

local ctrlset040 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global drawbtn is ctrlset040:addbutton("Dist: "+rawlx[distraw]).
set drawbtn:tooltip to "Experimental, use either PID controllers or 'raw' method (correlate throttle values to differences) for distance method.".
set drawbtn:onclick to {
	set distraw to not distraw.
}.
on distraw {
	set drawbtn:text to "Dist: "+rawlx[distraw].
	return true.
}
global vrawbtn is ctrlset040:addbutton("Vel: "+rawlx[velraw]).
set vrawbtn:tooltip to "Experimental, use either PID controllers or 'raw' method (correlate throttle values to differences) for velocity method.".
set vrawbtn:onclick to {
	set velraw to not velraw.
}.
on velraw {
	set vrawbtn:text to "Vel: "+rawlx[velraw].
	return true.
}
global rcsbtn is ctrlset040:addbutton("RCS").
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
global sasbtn is ctrlset040:addbutton("SAS").
set sasbtn:toggle to true.
set sasbtn:pressed to sas.
set sasbtn:style:width to 70.
set sasbtn:ontoggle to {
	parameter tog.
	if tog {
		if not sas {sas on.}.
		set rotenachb:pressed to false.
	}
	else {
		if sas {sas off.}.
	}
}.

// unfortunately, sasmode to "target" doesn't work sometimes from kOS, even if vessel itself is capable of this mode.
// SAS to target must be selected in KSP navball
// global sastgt is ctrlset040:addbutton("SAS:TGT").
// set sastgt:style:width to 70.
// set sastgt:onclick to {
		// set sasmode to "TARGET".
// }.

local ctrlset050 is ctrlpanlex["controls1"]["controls"]:addvbox().
local trnincrset is ctrlset050:addhlayout().
global ctrltrninc is ctrlLRCombo("controls1",trnincrset,"Transl. increment:",round(trnincr,1):tostring(),"m/s",false,false,list(1,0.1,10),1).
set ctrltrninc["leftbtn"]:onclick to {
   set trnincr to chkvaltrninc(trnincr-trnincstep).
}.
set ctrltrninc["label"]:tooltip to "Increment value for translation control. Each transl. control button press increases velocity (relative to target) in given direction by this value. Current values are shown on control buttons.".
set ctrltrninc["label"]:style:width to 120.
set ctrltrninc["txtfield"]:style:width to 40.
set ctrltrninc["txtfield"]:onconfirm to {
	parameter str.
	set trnincr to chkvaltrninc(str:tonumber(trnincr)).
}.
lock trnincstep to round(ctrltrninc["slider"]:value,1).
set ctrltrninc["steplab"]:style:width to 35.
set ctrltrninc["rightbtn"]:onclick to {
	set trnincr to chkvaltrninc(trnincr+trnincstep).
}.
local function chkvaltrninc {
   parameter p.
   local val is p.
   if val<0.1 {set val to 0.1.}.
   set ctrltrninc["txtfield"]:text to val:tostring().
   return val.
}.

local rotincrset is ctrlset050:addhlayout().
global ctrlrotinc is ctrlLRCombo("controls1",rotincrset,"Rot. increment:",round(rotincr,0):tostring(),"dg",false,false,list(5,1,45)).
set ctrlrotinc["leftbtn"]:onclick to {
   set rotincr to chkvalrotinc(rotincr-rotincstep).
}.
set ctrlrotinc["label"]:tooltip to "Increment value for rotation control. Each rot. control button press increases rotation (relative to initial rotation) on given axis by this value. Current values are shown on control buttons. After desired rotation is reached, button labels are nullified.".
set ctrlrotinc["label"]:style:width to 120.
set ctrlrotinc["txtfield"]:style:width to 40.
set ctrlrotinc["txtfield"]:onconfirm to {
	parameter str.
	set rotincr to chkvalrotinc(str:tonumber(rotincr)).
}.
lock rotincstep to round(ctrlrotinc["slider"]:value,0).
set ctrlrotinc["steplab"]:style:width to 35.
set ctrlrotinc["rightbtn"]:onclick to {
   set rotincr to chkvalrotinc(rotincr+rotincstep).
}.
local function chkvalrotinc {
   parameter p.
   local val is p.
   if val<0 {set val to 0.}.
   set ctrlrotinc["txtfield"]:text to val:tostring().
   return val.
}

local trnrotset1 is ctrlset050:addhlayout().
global trnbackbtn is trnrotset1:addbutton("<<< Back").
set trnbackbtn:tooltip to "Start translation backwards. The number in brackets shows the planned velocity in m/s. Increase velocity by multiple presses.".
set trnbackbtn:onclick to {
	set trnfwbck to trnfwbck-trnincr.
	updtrnlabels().
	set hldonbtn:pressed to false.
}.
global trnfwdbtn is trnrotset1:addbutton("Fwd >>>").
set trnfwdbtn:tooltip to "Start translation forward. The number in brackets shows the planned velocity in m/s. Increase velocity by multiple presses.".
set trnfwdbtn:onclick to {
	set trnfwbck to trnfwbck+trnincr.
	updtrnlabels().
	set hldonbtn:pressed to false.
}.

local trnrotset2 is ctrlset050:addhlayout().
global rolleftbtn is trnrotset2:addbutton("v< LRoll").
set rolleftbtn:tooltip to "Roll vessel left. The number in brackets shows the planned rotation in degrees. Increase rotation by multiple presses. After the vessel is rotated, rotation automatically stops and degrees value is reset to 0.".
set rolleftbtn:toggle to true.
set rolleftbtn:ontoggle to {
	parameter tog.
	if tog {
		set rolleftbtn:pressed to false.
	}
	else {
		set rotroll to rotroll+rotincr.
		updrotlabels().
		set shornt to ANGLEAXIS(rotincr,SHIP:facing:forevector)*shornt.
	}
}.
global trnupbtn is trnrotset2:addbutton("^^^ Up").
set trnupbtn:tooltip to "Start translation upwards. The number in brackets shows the planned velocity in m/s. Increase velocity by multiple presses.".
set trnupbtn:onclick to {
	set trnupdwn to trnupdwn+trnincr.
	updtrnlabels().
	set hldonbtn:pressed to false.
}.
global rolrghtbtn is trnrotset2:addbutton("RRoll >v").
set rolrghtbtn:tooltip to "Roll vessel right. The number in brackets shows the planned rotation in degrees. Increase rotation by multiple presses. After the vessel is rotated, rotation automatically stops and degrees value is reset to 0.".
set rolrghtbtn:toggle to true.
set rolrghtbtn:ontoggle to {
	parameter tog.
	if tog {
		set rolrghtbtn:pressed to false.
	}
	else {
		set rotroll to rotroll-rotincr.
		updrotlabels().
		set shornt to ANGLEAXIS(-rotincr,SHIP:facing:forevector)*shornt.
	}
}.

local trnrotset3 is ctrlset050:addhlayout().
global yawleftbtn is trnrotset3:addbutton("< LYaw").
set yawleftbtn:tooltip to "Yaw vessel left. The number in brackets shows the planned rotation in degrees. Increase rotation by multiple presses. After the vessel is rotated, rotation automatically stops and degrees value is reset to 0.".
set yawleftbtn:toggle to true.
set yawleftbtn:ontoggle to {
	parameter tog.
	if tog {
		set yawleftbtn:pressed to false.
	}
	else {
		set rotyaw to rotyaw-rotincr.
		updrotlabels().
		set shornt to ANGLEAXIS(-rotincr,SHIP:facing:topvector)*shornt.
	}
}.
global trnleftbtn is trnrotset3:addbutton("<<< Left").
set trnleftbtn:tooltip to "Start translation left. The number in brackets shows the planned velocity in m/s. Increase velocity by multiple presses.".
set trnleftbtn:onclick to {
	set trnlftrgh to trnlftrgh-trnincr.
	updtrnlabels().
	set hldonbtn:pressed to false.
}.
global trnnulltbtn is trnrotset3:addbutton("Stop").
set trnnulltbtn:tooltip to "Resets all translation velocities to 0.".
set trnnulltbtn:onclick to {
	set trnfwbck to 0.
	set trnlftrgh to 0.
	set trnupdwn to 0.
	if rstposchb:pressed {
		setpos(true).
	}
	updtrnlabels().
	set nllwhenbtn:pressed to false.
	statmsg("transl. stopped").
}.
global trnrghtbtn is trnrotset3:addbutton("Right >>>").
set trnrghtbtn:tooltip to "Start translation right. The number in brackets shows the planned velocity in m/s. Increase velocity by multiple presses.".
set trnrghtbtn:onclick to {
	set trnlftrgh to trnlftrgh+trnincr.
	updtrnlabels().
	set hldonbtn:pressed to false.
}.
global yawrghtbtn is trnrotset3:addbutton("RYaw >").
set yawrghtbtn:tooltip to "Yaw vessel right. The number in brackets shows the planned rotation in degrees. Increase rotation by multiple presses. After the vessel is rotated, rotation automatically stops and degrees value is reset to 0.".
set yawrghtbtn:toggle to true.
set yawrghtbtn:ontoggle to {
	parameter tog.
	if tog {
		set yawrghtbtn:pressed to false.
	}
	else {
		set rotyaw to rotyaw+rotincr.
		updrotlabels().
		set shornt to ANGLEAXIS(rotincr,SHIP:facing:topvector)*shornt.
	}
}.

local trnrotset4 is ctrlset050:addhlayout().
global ptchupbtn is trnrotset4:addbutton("UPitch ^").
set ptchupbtn:tooltip to "Pitch vessel up. The number in brackets shows the planned rotation in degrees. Increase rotation by multiple presses. After the vessel is rotated, rotation automatically stops and degrees value is reset to 0.".
set ptchupbtn:toggle to true.

set ptchupbtn:ontoggle to {
	parameter tog.
	if tog {
		set ptchupbtn:pressed to false.
	}
	else {
		set rotpitch to rotpitch-rotincr.

		updrotlabels().
		set shornt to ANGLEAXIS(-rotincr,SHIP:facing:starvector)*shornt.
	}
}.
global trndwnbtn is trnrotset4:addbutton("vvv Down").
set trndwnbtn:tooltip to "Start translation downwards. The number in brackets shows the planned velocity in m/s. Increase velocity by multiple presses.".
set trndwnbtn:onclick to {
	set trnupdwn to trnupdwn-trnincr.
	updtrnlabels().
	set hldonbtn:pressed to false.
}.
global ptchdwnbtn is trnrotset4:addbutton("DPitch v").
set ptchdwnbtn:tooltip to "Pitch vessel down. The number in brackets shows the planned rotation in degrees. Increase rotation by multiple presses. After the vessel is rotated, rotation automatically stops and degrees value is reset to 0.".
set ptchdwnbtn:toggle to true.
set ptchdwnbtn:ontoggle to {
	parameter tog.
	if tog {
		set ptchdwnbtn:pressed to false.
	}
	else {
		set rotpitch to rotpitch+rotincr.

		updrotlabels().
		set shornt to ANGLEAXIS(rotincr,SHIP:facing:starvector)*shornt.
	}
}.

function updtrnlabels {
	set trnbackbtn:text to "<<< Back ("+convstr(-trnfwbck)+")".
	set trnfwdbtn:text to "Fwd >>> ("+convstr(trnfwbck)+")".
	set trnupbtn:text to "^^^ Up ("+convstr(trnupdwn)+")".
	set trnleftbtn:text to "<<< Left ("+convstr(-trnlftrgh)+")".
	set trnrghtbtn:text to "Right >>> ("+convstr(trnlftrgh)+")".
	set trndwnbtn:text to "vvv Down ("+convstr(-trnupdwn)+")".
}

global function updrotlabels {
	set rolleftbtn:text to "v< LRoll ("+convstr(rotroll)+")".
	set rolrghtbtn:text to "RRoll >v ("+convstr(-rotroll)+")".
	set yawleftbtn:text to "< LYaw ("+convstr(-rotyaw)+")".
	set yawrghtbtn:text to "RYaw > ("+convstr(rotyaw)+")".
	set ptchupbtn:text to "UPitch ^ ("+convstr(-rotpitch)+")".
	set ptchdwnbtn:text to "DPitch v ("+convstr(rotpitch)+")".
}

function convstr {
	parameter p.
	return round(p,1):tostring().
}

local ctrlset060 is ctrlpanlex["controls1"]["controls"]:addhbox().
global rstbtn is ctrlset060:addbutton("Reset Controls").
set rstbtn:tooltip to "Resets all control values and pops all buttons.".
set rstbtn:onclick to {
	wait until btnsoff(ctrlpanlex["controls1"]["controls"],"").
	ctrlreset(true).
}.
global nllwhenbtn is ctrlset060:addbutton("Stop When").
set nllwhenbtn:tooltip to "If translation is active, this minipanel provides a means to stop the vessel (automatically pressing the 'Stop' button) at a certain distance from the target. The minipanel must stay (in this case) open for the function to be active. At the stop point, the minipanel is closed automatically.".
set nllwhenbtn:toggle to true.
set nllwhenbtn:ontoggle to {
	parameter tog.
	if tog {
		minipanel("nullwhen","Stop When:",true,200,guilex["controls1"]:x+480,guilex["controls1"]:y,list(true,false)).
		mpComboTog("nullwhen","Tgt. dist. <",false,
		{
			parameter tog.
			set tdistlprs to tog.
			if tog {
				set mpCombolex["nullwhen"]["items"]["Tgt. dist. >"]["tbtn"]:pressed to false.
				set nllwhenactive to tog.
			}
			return "Tgt. dist. <".
		},"If pressed, target distance is checked and the vessel translation is stopped if the distance falls below the entered value. Note that the distance value is displayed in the terminal window as the 'tgt dist.' item. It does not need to correspond to the value displayed on the target marker.").

		mpComboText("nullwhen","tdistlthan",{
			parameter str.
			set tdistl to str:tonumber(tdistl).

		},"m",false).
		set mpCombolex["nullwhen"]["items"]["tdistlthan"]["textfld"]:text to tdistl:tostring().

		mpComboTog("nullwhen","Tgt. dist. >",false,
		{
			parameter tog.
			set tdistgprs to tog.
			if tog {
				set mpCombolex["nullwhen"]["items"]["Tgt. dist. <"]["tbtn"]:pressed to false.
				set nllwhenactive to tog.
			}
			return "Tgt. dist. >".
		},"If pressed, target distance is checked and the vessel translation is stopped if the distance exceeds the entered value. Note that the distance value is displayed in the terminal window as the 'tgt dist.' item. It does not need to correspond to the value displayed on the target marker.").

		mpComboText("nullwhen","tdistgthan",{
			parameter str.
			set tdistg to str:tonumber(tdistg).

		},"m",false).
		set mpCombolex["nullwhen"]["items"]["tdistgthan"]["textfld"]:text to tdistg:tostring().

		mpComboTog("nullwhen","Auto. hold",false,
		{
			parameter tog.
			return "Auto. hold".
		},"If pressed, 'Hold pos.' is automatically activated when the distance threshold is reached. Don't forget to set holding method ('D Dist./D Vel./D both) prior to using this.").

	}
	else {
		set mpCombolex["nullwhen"]["items"]["Tgt. dist. <"]["tbtn"]:pressed to false.
		set mpCombolex["nullwhen"]["items"]["Tgt. dist. >"]["tbtn"]:pressed to false.
		killgui("nullwhen").
	}
}.

updtrnlabels().
updrotlabels().
trnena(input_data["intrns"][1]).
rotena(input_data["inrots"][1]).

}
// switches
{
local swtset010 is ctrlpanlex["controls1"]["switches"]:addhbox().
global unstgtbtn is swtset010:addbutton("Unset Target").
set unstgtbtn:tooltip to "Unsets vessel's target and (obviously) exits the script.".
set unstgtbtn:onclick to {
	set target to "".
	wait until not hastarget.
}.

local swtset020 is ctrlpanlex["controls1"]["switches"]:addhbox().
global termlogchb is swtset020:addcheckbox("Terminal Logs",false).
set termlogchb:tooltip to "Send status messages also to other terminal.".
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

global solpanprs is false.
global solpanbtn is swtset020:addbutton("Ext./Retr. Solar Panels").
global prevtog is false.
set solpanbtn:tooltip to "Extends or retracts solar panels with the kOS name tag 'solpan'.".
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
// machinery settings
{
// ship title
local machtitle is ctrlpanlex["controls2"]["machinery settings"]:addlabel(ship:name).
set machtitle:style:align to "center".
set machtitle:style:hstretch to true.

local mchset010 is ctrlpanlex["controls2"]["machinery settings"]:addvbox().
global dlgtgtwt is
mchnrline("controls2",mchset010,"tgtwait",{
   parameter str.
   set tgtwait to str:tonumber(tgtwait).
}).
global dlgvcmltp is
mchnrline("controls2",mchset010,"vcmltp",{
   parameter str.
   set vcmltp to str:tonumber(vcmltp).
}).
}
}

// GUI END
///////////////////////////////////////////////////////////////////////////////////////////////

///////////// PID settings /////////////////
// https://www.csimn.com/CSI_pages/PIDforDummies.html
// http://www.engineers-excel.com/Apps/PID_Simulator/Description.htm


global haspids is false.
if exists(pidfile){
	statmsg(pidfile).
	set haspids to true.
}
else {
	statmsg("WARNING: missing include "+pidfile).
	if exists(templfile){
		statmsg("Using template "+templfile+"; PID file created.").
		copypath(templfile,pidfile).
		popmsg(list("Using template "+templfile,"PID file created"),green,{},250).
		set haspids to true.
	}
	else {
		print "ERROR: missing template "+templfile+"; file base created.".
		statmsg("ERROR: missing template "+templfile+"; file base created.").
		log "// "+ship:name+"; "+scriptid+"; PID include file" to pidfile.
		popmsg(list("ERROR: missing template "+templfile+"; file base created.","Edit "+pidfile+" file to add PID values."),red,{},250).
		print "Edit "+pidfile+" file to add PID values.".
	}
}

if haspids {
runoncepath(pidfile).

// distance diff., vertical part
global dtoppid is pidloop(dtopkp, dtopki, dtopkd, -0.5, 1, dtopeps).
global function upd_dtop {
	parameter spoint.
	parameter feedback.
	set dtoppid:setpoint to spoint.
	return dtoppid:update(time:seconds, feedback).
}

// velocity diff., vertical part
global vtoppid is pidloop(vtopkp, vtopki, vtopkd, -1, 1, vtopeps).
global function upd_vtop {
	parameter spoint.
	parameter feedback.
	set vtoppid:setpoint to spoint.
	return vtoppid:update(time:seconds, feedback).
}

// distance diff., fwd-bck part
global dforepid is pidloop(dforekp, dforeki, dforekd, -1, 1, dforeeps).
global function upd_dfore {
	parameter spoint.
	parameter feedback.
	set dforepid:setpoint to spoint.
	return dforepid:update(time:seconds, feedback).
 }

// velocity diff., fwd-bck part
global vforepid is pidloop(vforekp, vforeki, vforekd, -1, 1, vforeeps).
global function upd_vfore {
	parameter spoint.
	parameter feedback.
	set vforepid:setpoint to spoint.
	return vforepid:update(time:seconds, feedback).
 }

// distance diff., starboard part
global dsidpid is pidloop(dsidkp, dsidki, dsidkd, -1, 1, dsideps).
global function upd_dsid {
	parameter spoint.
	parameter feedback.
	set dsidpid:setpoint to spoint.
	return dsidpid:update(time:seconds, feedback).
 }

// velocity diff., starboard part
global vsidpid is pidloop(vsidkp, vsidki, vsidkd, -1, 1, vsideps).
global function upd_vsid {
	parameter spoint.
	parameter feedback.
	set vsidpid:setpoint to spoint.
	return vsidpid:update(time:seconds, feedback).
 }

// roll
global rllpid is pidloop(rllkp, rllki, rllkd, -1, 1, rlleps).
global function upd_rllpid {
	parameter spoint.
	parameter feedback.
	set rllpid:setpoint to spoint.
	return rllpid:update(time:seconds, feedback).
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
}

// PID gains control panel
{
local ldsvsset is ctrlpanlex["controls2"]["PID values"]:addhlayout().
local saveloadbtn1 is svldbtn(ldsvsset).
set saveloadbtn1:ontoggle to {
	parameter tog.
	saveload(tog,guilex["controls2"]:x,guilex["controls2"]:y-200).
}.

local confset is savldconf(ldsvsset).
global saveconfchb1 is confset[0].
global loadconfchb1 is confset[1].

local coefset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global coefc1dlg is valbox("controls2",coefset,"coefc1","c1:",coefc1,{
   parameter str.
   set coefc1 to str:tonumber(coefc1).
},
"Coeficient for velocity raw method.").
global coefc2dlg is valbox("controls2",coefset,"coefc2","c2:",coefc2,{
   parameter str.
   set coefc2 to str:tonumber(coefc2).
},
"Coeficient for distance raw method.").
global coefc3dlg is valbox("controls2",coefset,"coefc3","c3:",coefc3,{
   parameter str.
   set coefc3 to str:tonumber(coefc3).
},
"Coeficient for (nothing yet).").

local dtoppidset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global dtopkpdlg is valbox("controls2",dtoppidset,"dtopkp","dtop kp:",dtoppid:kp,{
   parameter str.
   set dtoppid:kp to str:tonumber(dtoppid:kp).
},
"distance diff., vertical part").
global dtopkidlg is valbox("controls2",dtoppidset,"dtopki","dtop ki:",dtoppid:ki,{
   parameter str.
   set dtoppid:ki to str:tonumber(dtoppid:ki).
}).
global dtopkddlg is valbox("controls2",dtoppidset,"dtopkd","dtop kd:",dtoppid:kd,{
   parameter str.
   set dtoppid:kd to str:tonumber(dtoppid:kd).
}).
global dtopepsdlg is valbox("controls2",dtoppidset,"dtopeps","dtop eps:",dtoppid:epsilon,{
   parameter str.
   set dtoppid:epsilon to str:tonumber(dtoppid:epsilon).
}).

local vtoppidset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global vtopkpdlg is valbox("controls2",vtoppidset,"vtopkp","vtop kp:",vtoppid:kp,{
   parameter str.
   set vtoppid:kp to str:tonumber(vtoppid:kp).
},
"velocity diff., vertical part").
global vtopkidlg is valbox("controls2",vtoppidset,"vtopki","vtop ki:",vtoppid:ki,{
   parameter str.
   set vtoppid:ki to str:tonumber(vtoppid:ki).
}).
global vtopkddlg is valbox("controls2",vtoppidset,"vtopkd","vtop kd:",vtoppid:kd,{
   parameter str.
   set vtoppid:kd to str:tonumber(vtoppid:kd).
}).
global vtopepsdlg is valbox("controls2",vtoppidset,"vtopeps","vtop eps:",vtoppid:epsilon,{
   parameter str.
   set vtoppid:epsilon to str:tonumber(vtoppid:epsilon).
}).

local dforepidset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global dforekpdlg is valbox("controls2",dforepidset,"dforekp","dfore kp:",dforepid:kp,{
   parameter str.
   set dforepid:kp to str:tonumber(dforepid:kp).
},
"distance diff., fwd-bck part").
global dforekidlg is valbox("controls2",dforepidset,"dforeki","dfore ki:",dforepid:ki,{
   parameter str.
   set dforepid:ki to str:tonumber(dforepid:ki).
}).
global dforekddlg is valbox("controls2",dforepidset,"dforekd","dfore kd:",dforepid:kd,{
   parameter str.
   set dforepid:kd to str:tonumber(dforepid:kd).
}).
global dforeepsdlg is valbox("controls2",dforepidset,"dforeeps","dfore eps:",dforepid:epsilon,{
   parameter str.
   set dforepid:epsilon to str:tonumber(dforepid:epsilon).
}).

local vforepidset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global vforekpdlg is valbox("controls2",vforepidset,"vforekp","vfore kp:",vforepid:kp,{
   parameter str.
   set vforepid:kp to str:tonumber(vforepid:kp).
},
"velocity diff., fwd-bck part").
global vforekidlg is valbox("controls2",vforepidset,"vforeki","vfore ki:",vforepid:ki,{
   parameter str.
   set vforepid:ki to str:tonumber(vforepid:ki).
}).
global vforekddlg is valbox("controls2",vforepidset,"vforekd","vfore kd:",vforepid:kd,{
   parameter str.
   set vforepid:kd to str:tonumber(vforepid:kd).
}).
global vforeepsdlg is valbox("controls2",vforepidset,"vforeeps","vfore eps:",vforepid:epsilon,{
   parameter str.
   set vforepid:epsilon to str:tonumber(vforepid:epsilon).
}).

local dsidpidset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global dsidkpdlg is valbox("controls2",dsidpidset,"dsidkp","dsid kp:",dsidpid:kp,{
   parameter str.
   set dsidpid:kp to str:tonumber(dsidpid:kp).
},
"distance diff., starboard part").
global dsidkidlg is valbox("controls2",dsidpidset,"dsidki","dsid ki:",dsidpid:ki,{
   parameter str.
   set dsidpid:ki to str:tonumber(dsidpid:ki).
}).
global dsidkddlg is valbox("controls2",dsidpidset,"dsidkd","dsid kd:",dsidpid:kd,{
   parameter str.
   set dsidpid:kd to str:tonumber(dsidpid:kd).
}).
global dsidepsdlg is valbox("controls2",dsidpidset,"dsideps","dsid eps:",dsidpid:epsilon,{
   parameter str.
   set dsidpid:epsilon to str:tonumber(dsidpid:epsilon).
}).

local vsidpidset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global vsidkpdlg is valbox("controls2",vsidpidset,"vsidkp","vsid kp:",vsidpid:kp,{
   parameter str.
   set vsidpid:kp to str:tonumber(vsidpid:kp).
},
"velocity diff., starboard part").
global vsidkidlg is valbox("controls2",vsidpidset,"vsidki","vsid ki:",vsidpid:ki,{
   parameter str.
   set vsidpid:ki to str:tonumber(vsidpid:ki).
}).
global vsidkddlg is valbox("controls2",vsidpidset,"vsidkd","vsid kd:",vsidpid:kd,{
   parameter str.
   set vsidpid:kd to str:tonumber(vsidpid:kd).
}).
global vsidepsdlg is valbox("controls2",vsidpidset,"vsideps","vsid eps:",vsidpid:epsilon,{
   parameter str.
   set vsidpid:epsilon to str:tonumber(vsidpid:epsilon).
}).

local rllpidset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global rllkpdlg is valbox("controls2",rllpidset,"rllkp","rll kp:",rllpid:kp,{
   parameter str.
   set rllpid:kp to str:tonumber(rllpid:kp).
},
"ship roll").
global rllkidlg is valbox("controls2",rllpidset,"rllki","rll ki:",rllpid:ki,{
   parameter str.
   set rllpid:ki to str:tonumber(rllpid:ki).
}).
global rllkddlg is valbox("controls2",rllpidset,"rllkd","rll kd:",rllpid:kd,{
   parameter str.
   set rllpid:kd to str:tonumber(rllpid:kd).
}).
global rllepsdlg is valbox("controls2",rllpidset,"rlleps","rll eps:",rllpid:epsilon,{
   parameter str.
   set rllpid:epsilon to str:tonumber(rllpid:epsilon).
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
}

// GLOBAL; resetting ALL* controls (to 0)
function ctrlreset {
	parameter msg.
	unlock throttle.
	set ship:control:mainthrottle to 0.
	set ship:control:pitch to 0.
	set ship:control:roll to 0.
	set ship:control:yaw to 0.
	set ship:control:fore to 0.
	set ship:control:starboard to 0.
	set ship:control:top to 0.
	set ship:control:neutralize to true.
	set ship:control:pilotmainthrottle to 0.
	if not rotenaprs {unlock steering.}.
	if msg {statmsg("controls rst.").}.
}

function trnena {
	parameter p.
	set trnbackbtn:enabled to p.
	set trnfwdbtn:enabled to p.
	set trnupbtn:enabled to p.
	set trnleftbtn:enabled to p.
	set trnnulltbtn:enabled to p.
	set trnrghtbtn:enabled to p.
	set trndwnbtn:enabled to p.
	set nllwhenbtn:enabled to p.
}

function rotena {
	parameter p.
	set rolleftbtn:enabled to p.
	set rolrghtbtn:enabled to p.
	set yawleftbtn:enabled to p.
	set yawrghtbtn:enabled to p.
	set ptchupbtn:enabled to p.
	set ptchdwnbtn:enabled to p.
}

function transvects {
	parameter d.
	parameter mltp is 15.
	if (d) {
		global trforv is vecdraw(
			V(0,0,0),
			SHIP:facing:forevector*mltp,
			RGB(1,1,1),
			"S:FOREV",
			1.0,
			true,
			0.2
		).
		set trforv:vecupdater to {return SHIP:facing:forevector*mltp.}.
		global trtopv is vecdraw(
			V(0,0,0),
			SHIP:facing:topvector*mltp,
			RGB(0,1,1),
			"S:TOPV",
			1.0,
			true,
			0.2
		).
		set trtopv:vecupdater to {return SHIP:facing:topvector*mltp.}.
		global trstarv is vecdraw(
			V(0,0,0),
			SHIP:facing:starvector*mltp,
			RGB(1,0,1),
			"S:STARV",
			1.0,
			true,
			0.2
		).
		set trstarv:vecupdater to {return SHIP:facing:starvector*mltp.}.
	}
	else {
		set trforv:vecupdater to DONOTHING.
		set trtopv:vecupdater to DONOTHING.
		set trstarv:vecupdater to DONOTHING.
		set trforv to 0.
		set trtopv to 0.
		set trstarv to 0.
	}
}

function rotvects {
	parameter d.
	parameter mltp is 15.
	if (d) {
		global shorntv is vecdraw(
			V(0,0,0),
			shornt:vector*mltp,
			RGB(1,1,1),
			"SHORNT",
			1.0,
			true,
			0.2
		).
		set shorntv:vecupdater to {return shornt:vector*mltp.}.
		global shptopv is vecdraw(
			V(0,0,0),
			SHIP:facing:topvector*mltp,
			RGB(0,1,1),
			"S:TOPV",
			1.0,
			true,
			0.2
		).
		set shptopv:vecupdater to {return SHIP:facing:topvector*mltp.}.
		global shortopv is vecdraw(
			V(0,0,0),
			shornt:topvector*mltp,
			RGB(1,0,1),
			"SHORNT:TOP",
			1.0,
			true,
			0.2
		).
		set shortopv:vecupdater to {return shornt:topvector*mltp.}.
	}
	else {
		set shorntv:vecupdater to DONOTHING.
		set shptopv:vecupdater to DONOTHING.
		set shortopv:vecupdater to DONOTHING.
		set shorntv to 0.
		set shptopv to 0.
		set shortopv to 0.
	}
}

function setpos {
	parameter p.
	if p {
		if hastarget {
			set tgtdx to ship:position:x-mytgt:position:x.
			set tgtdy to ship:position:y-mytgt:position:y.
			set tgtdz to ship:position:z-mytgt:position:z.
			statmsg("position set: "+round(tgtdx,1)+"; "+round(tgtdy,1)+"; "+round(tgtdz,1)).
		}
		else {
			// no target
			popmsg(list("No target set."),rgb(0.6,0.7,1)).
		}
	}
	else {
		ctrlreset(true).
	}
}

function savvalsload {
	set coefc1 to savvals["coefc1"].
	set coefc1dlg["txtfield"]:text to coefc1:tostring().
	set coefc2 to savvals["coefc2"].
	set coefc2dlg["txtfield"]:text to coefc2:tostring().
	set coefc3 to savvals["coefc3"].
	set coefc3dlg["txtfield"]:text to coefc3:tostring().

	set dtoppid:kp to savvals["dtopkp"].
	set dtopkpdlg["txtfield"]:text to dtoppid:kp:tostring().
	set dtoppid:ki to savvals["dtopki"].
	set dtopkidlg["txtfield"]:text to dtoppid:ki:tostring().
	set dtoppid:kd to savvals["dtopkd"].
	set dtopkddlg["txtfield"]:text to dtoppid:kd:tostring().
	set dtoppid:epsilon to savvals["dtopeps"].
	set dtopepsdlg["txtfield"]:text to dtoppid:epsilon:tostring().

	set dforepid:kp to savvals["dforekp"].
	set dforekpdlg["txtfield"]:text to dforepid:kp:tostring().
	set dforepid:ki to savvals["dforeki"].
	set dforekidlg["txtfield"]:text to dforepid:ki:tostring().
	set dforepid:kd to savvals["dforekd"].
	set dforekddlg["txtfield"]:text to dforepid:kd:tostring().
	set dforepid:epsilon to savvals["dforeeps"].
	set dforeepsdlg["txtfield"]:text to dforepid:epsilon:tostring().

	set dsidpid:kp to savvals["dsidkp"].
	set dsidkpdlg["txtfield"]:text to dsidpid:kp:tostring().
	set dsidpid:ki to savvals["dsidki"].
	set dsidkidlg["txtfield"]:text to dsidpid:ki:tostring().
	set dsidpid:kd to savvals["dsidkd"].
	set dsidkddlg["txtfield"]:text to dsidpid:kd:tostring().
	set dsidpid:epsilon to savvals["dsideps"].
	set dsidepsdlg["txtfield"]:text to dsidpid:epsilon:tostring().

	set vtoppid:kp to savvals["vtopkp"].
	set vtopkpdlg["txtfield"]:text to vtoppid:kp:tostring().
	set vtoppid:ki to savvals["vtopki"].
	set vtopkidlg["txtfield"]:text to vtoppid:ki:tostring().
	set vtoppid:kd to savvals["vtopkd"].
	set vtopkddlg["txtfield"]:text to vtoppid:kd:tostring().
	set vtoppid:epsilon to savvals["vtopeps"].
	set vtopepsdlg["txtfield"]:text to vtoppid:epsilon:tostring().

	set vforepid:kp to savvals["vforekp"].
	set vforekpdlg["txtfield"]:text to vforepid:kp:tostring().
	set vforepid:ki to savvals["vforeki"].
	set vforekidlg["txtfield"]:text to vforepid:ki:tostring().
	set vforepid:kd to savvals["vforekd"].
	set vforekddlg["txtfield"]:text to vforepid:kd:tostring().
	set vforepid:epsilon to savvals["vforeeps"].
	set vforeepsdlg["txtfield"]:text to vforepid:epsilon:tostring().
	set vsidpid:kp to savvals["vsidkp"].
	set vsidkpdlg["txtfield"]:text to vsidpid:kp:tostring().
	set vsidpid:ki to savvals["vsidki"].
	set vsidkidlg["txtfield"]:text to vsidpid:ki:tostring().
	set vsidpid:kd to savvals["vsidkd"].
	set vsidkddlg["txtfield"]:text to vsidpid:kd:tostring().
	set vsidpid:epsilon to savvals["vsideps"].
	set vsidepsdlg["txtfield"]:text to vsidpid:epsilon:tostring().

	set rllpid:kp to savvals["rllkp"].
	set rllkpdlg["txtfield"]:text to rllpid:kp:tostring().
	set rllpid:ki to savvals["rllki"].
	set rllkidlg["txtfield"]:text to rllpid:ki:tostring().
	set rllpid:kd to savvals["rllkd"].
	set rllkddlg["txtfield"]:text to rllpid:kd:tostring().
	set rllpid:epsilon to savvals["rlleps"].
	set rllepsdlg["txtfield"]:text to rllpid:epsilon:tostring().

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
}

function savvalssave {
	set savvals["coefc1"] to coefc1.
	set savvals["coefc2"] to coefc2.
	set savvals["coefc3"] to coefc3.

	set savvals["dtopkp"] to dtoppid:kp.
	set savvals["dtopki"] to dtoppid:ki.
	set savvals["dtopkd"] to dtoppid:kd.
	set savvals["dtopeps"] to dtoppid:epsilon.

	set savvals["dforekp"] to dforepid:kp.
	set savvals["dforeki"] to dforepid:ki.
	set savvals["dforekd"] to dforepid:kd.
	set savvals["dforeeps"] to dforepid:epsilon.

	set savvals["dsidkp"] to dsidpid:kp.
	set savvals["dsidki"] to dsidpid:ki.
	set savvals["dsidkd"] to dsidpid:kd.
	set savvals["dsideps"] to dsidpid:epsilon.

	set savvals["vtopkp"] to vtoppid:kp.
	set savvals["vtopki"] to vtoppid:ki.
	set savvals["vtopkd"] to vtoppid:kd.
	set savvals["vtopeps"] to vtoppid:epsilon.

	set savvals["vforekp"] to vforepid:kp.
	set savvals["vforeki"] to vforepid:ki.
	set savvals["vforekd"] to vforepid:kd.
	set savvals["vforeeps"] to vforepid:epsilon.

	set savvals["vsidkp"] to vsidpid:kp.
	set savvals["vsidki"] to vsidpid:ki.
	set savvals["vsidkd"] to vsidpid:kd.
	set savvals["vsideps"] to vsidpid:epsilon.

	set savvals["rllkp"] to rllpid:kp.
	set savvals["rllki"] to rllpid:ki.
	set savvals["rllkd"] to rllpid:kd.
	set savvals["rlleps"] to rllpid:epsilon.

	set savvals["ywkp"] to ywpid:kp.
	set savvals["ywki"] to ywpid:ki.
	set savvals["ywkd"] to ywpid:kd.
	set savvals["yweps"] to ywpid:epsilon.

	set savvals["ptchkp"] to ptchpid:kp.
	set savvals["ptchki"] to ptchpid:ki.
	set savvals["ptchkd"] to ptchpid:kd.
	set savvals["ptcheps"] to ptchpid:epsilon.
}

function gettarget {
	if hastarget {
		set prevtgt to target.
		if target:hassuffix("ship") {
			set docktgt to target.
			set mytgt to target:ship.
		}
		else {
			set mytgt to target.
		}
		set labtarget:text to target:typename+": "+target:name.
	}
	else {
		set labtarget:text to "none".
	}
}

on hastarget {
	statmsg("hastarget:"+hastarget).
	if not hastarget {wait tgtwait.}.
	setpos(true).
	set scriptend to not hastarget.
	return true.
}

chkpreset(input_data["ldpres"][1],input_data["preset"][1]).
gettarget().
ctrlreset(false).
setpos(true).
set hldonbtn:pressed to input_data["inhld"][1].
if hldpoint<>"none" {set hldpointlex[hldpoint]:pressed to true.}.

if hastarget {
	global tgtx is ship:position:x-mytgt:position:x.
	global tgty is ship:position:y-mytgt:position:y.
	global tgtz is ship:position:z-mytgt:position:z.

	global rtgtx is (tgtdx-tgtx).
	global rtgty is (tgtdy-tgty).
	global rtgtz is (tgtdz-tgtz).
}

statmsg("probe ready").
global looptime is 0.

global tclmn1 is currsets["tclmn1"][0].
global tclmn2 is currsets["tclmn2"][0].
global tclmn3 is currsets["tclmn3"][0].

until scriptend {
	set looptime to time:seconds.

	set rvelx to ship:velocity:orbit:x-mytgt:velocity:orbit:x.
	set rvely to ship:velocity:orbit:y-mytgt:velocity:orbit:y.
	set rvelz to ship:velocity:orbit:z-mytgt:velocity:orbit:z.

	set tgtx to ship:position:x-mytgt:position:x.
	set tgty to ship:position:y-mytgt:position:y.
	set tgtz to ship:position:z-mytgt:position:z.

	set rtgtx to (tgtdx-tgtx).
	set rtgty to (tgtdy-tgty).
	set rtgtz to (tgtdz-tgtz).

	set initdir to ship:facing:inverse.

	if distraw {
		set shipfored to rtgtz*coefc2.
		set shiptopd to rtgty*coefc2.
		set shipsidd to rtgtx*coefc2.
	}
	else {
		set shipfored to upd_dfore(tgtdz,tgtz).
		set shiptopd to upd_dtop(tgtdy,tgty).
		set shipsidd to upd_dsid(tgtdx,tgtx).
	}
	if velraw {
		set shipforev to -rvelz*coefc1.
		set shiptopv to -rvely*coefc1.
		set shipsidv to -rvelx*coefc1.
	}
	else {
		set shipforev to upd_vfore(0,-rvelx).
		set shiptopv to upd_vtop(0,rvely).
		set shipsidv to upd_vsid(0,rvelz).
	}

	if hastarget and (prevtgt<>target) {
		statmsg("target change: "+mytgt+" -> "+target).
		gettarget().
	}

	if trnenaprs {
		local tgtv is v(rvelx,rvely,rvelz).
		local forevang is vang(tgtv,ship:facing:forevector).
		local sidvang is vang(tgtv,ship:facing:starvector).
		local topvang is vang(tgtv,ship:facing:topvector).
		local forev is tgtv:mag*cos(forevang).
		local sidv is tgtv:mag*cos(sidvang).
		local topv is tgtv:mag*cos(topvang).

		set ship:control:fore to (trnfwbck-forev)*coefc1.
		set ship:control:starboard to (trnlftrgh-sidv)*coefc1.
		set ship:control:top to (trnupdwn-topv)*coefc1.

		if nllwhenactive {
			if tdistlprs {
				if mytgt:distance<tdistl {
					statmsg("distance from target < "+tdistl).
					if mpCombolex["nullwhen"]["items"]["Auto. hold"]["tbtn"]:pressed {
						set hldonbtn:pressed to true.
					}
					trnnulltbtn:onclick().
				}
			}
			if tdistgprs {
				if mytgt:distance>tdistg {
					statmsg("distance from target > "+tdistg).
					if mpCombolex["nullwhen"]["items"]["Auto. hold"]["tbtn"]:pressed {
						set hldonbtn:pressed to true.
					}
					trnnulltbtn:onclick().
				}
			}
		}
	}

	if rotenaprs {
		if rotyaw<>0 {
			if yawdifang=0 {
				set rotyaw to 0.
				updrotlabels().
			}
		}
		if rotpitch<>0 {
			if pitchdifang=0 {
				set rotpitch to 0.
				updrotlabels().
			}
		}
		if rotroll<>0 {
			if rolldifang=0 {
				set rotroll to 0.
				updrotlabels().
			}
		}
	}

	if hldonprs {
		set trnsdist to v(shipsidd,shiptopd,shipfored).
		set trnsvel to v(shipsidv,shiptopv,shipforev).

		if hlddistprs {
			set ship:control:translation to trnsdist+initdir.
		}
		if hldvelprs {
			set ship:control:translation to trnsvel+initdir.
		}
		if hldbothprs {
			set ship:control:translation to trnsdist+trnsvel+initdir.
		}
	}

	print "OPCODESLEFT: ["+OPCODESLEFT+"]   " at(tclmn1,0). print "curtime: ["+round(curtime,1)+"]   " at(tclmn2,0). print "loop:["+(time:seconds-looptime)+"]----------" at(tclmn3,0).

	if termdata {
		print "tgt dist.:["+round(mytgt:distance,15)+"]--------" at(0,3).

		print "tgtdx:["+round(tgtdx,15)+"]--------" at(0,5).
		print "posx:["+round(tgtx,15)+"]--------" at(0,6).
		print "diffx:["+round(rtgtx,15)+"]--------" at(0,7).
		print "cx(sbd):["+round(ship:control:starboard,15)+"]--------" at(0,8).
		print "rvelx:["+round(rvelx,15)+"]--------" at(0,9).

		print "tgtdy:["+round(tgtdy,15)+"]--------" at(0,11).
		print "posy:["+round(tgty,15)+"]--------" at(0,12).
		print "diffy:["+round(rtgty,15)+"]--------" at(0,13).
		print "cy(top):["+round(ship:control:top,15)+"]--------" at(0,14).
		print "rvely:["+round(rvely,15)+"]--------" at(0,15).

		print "tgtdz:["+round(tgtdz,15)+"]--------" at(0,17).
		print "posz:["+round(tgtz,15)+"]--------" at(0,18).
		print "diffz:["+round(rtgtz,15)+"]--------" at(0,19).
		print "cz(fore):["+round(ship:control:fore,15)+"]--------" at(0,20).
		print "rvelz:["+round(rvelz,15)+"]--------" at(0,21).

		print "dist raw:"+distraw+"; vel raw:"+velraw at (0,23).
		print "monopropellant: "+ship:monopropellant+" ["+round(fuelpct,2)+"%]" at(0,24).

		if showdebug {

			print "initdir: "+initdir at(0,26).
			print "facing (p,y,r):"+round(ship:facing:pitch,2)+","+round(ship:facing:yaw,2)+","+round(ship:facing:roll,2) at(0,27).
			print "rotenaprs (r,y,p):"+rotroll+" ; "+rotyaw+" ; "+rotpitch+" ; " at(0,28).
			print "shornt:["+shornt+"]--------" at(0,29).
			print "yawdif; pitchdif; rolldif:["+yawdifang+"; "+pitchdifang+"; "+rolldifang+"]--------" at(0,30).
		}

	}
	wait 0.
}.

ctrlreset(true).

if not hastarget {popmsg(list("No target set, exiting..."),red).statmsg("NO TARGET, exiting..."). print "No target set, exiting...". wait 1.}.

if areboot="yes" {exit_cleanup().reboot.}
else if areboot="ask" {ynmsg(list("Reboot CPU?"),red,{exit_cleanup().reboot.},{},true).}.
exit_cleanup(). // proper disposal of all GUIs, cleanup of all lexicons and saving of final GUIs positions.
