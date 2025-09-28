// gtrn.ks by ngx

@lazyglobal off.

global scriptid is "gtrn".
declare parameter goon to false.
runoncepath("lib/settings.lib.ks").
runoncepath("lib/common.lib.ks").
runoncepath("lib/ctrlpanel.lib.ks").
runoncepath("lib/screen.lib.ks").
runoncepath("lib/ldsv.lib.ks").
runoncepath("lib/orbital.lib.ks").

clearscreen.
clearguis().
loadguipos().

global starttime is time:seconds.
lock curtime to time:seconds-starttime.
global scriptend is false.

ctrlpanel(true,true,true,currsets["ctrlw"][0],currsets["ctrlx"][0],currsets["ctrly"][0],2,1,0).

global input_data is lexicon(
"toApoapsis", list("orbit apoapsis (km)",150,"Planned orbit apoapsis."),
"startTurnVelocity",list("turning start velocity (m/s)",100,"Ship's velocity after liftoff at which the gravity turn begins."),
"finTurnAltitude",list("turning finish altitude (m)",12000,"Altitude at which the ship will finish its turn."),
"finTurnAngleDelta",list("turning final angle (dg)",45,"Final rocket gravity turn angle (0 dg = vertical, 90 dg = horizontal)."),
"turnStep",list("turning step (dg)",0.1,"Turning step in dg for each height increase. The increase is calculated from this step and the final turn altitude."),
"finRollAngleDelta",list("final roll angle (dg)",0,"Final intended roll angle from 0 dg. BETA, better leave default (don't roll unless necessary)."),
"startRollVelocity",list("rolling start velocity (m/s)",10,"Rocket velocity when rolling starts. BETA, better leave default."),
"finRollAltitude",list("final rolling altitude (m)",500,"Rocket altitude when rolling finishes. BETA, better leave default."),
"rollIncStep",list("rolling step (dg)",1,"Rolling in dg for each height increase. BETA, better leave default."),
"steer",list("initial steering (dg)",90,"Ship's compass steering direction for the gravity turn. If 90, the ship will turn east; if 0, the ship will turn north, etc."),
"corrptch",list("initial pitch correction",true,"Pitch correction is used to maintain the vessel's angle of attack close to 0 when engine thrust becomes insufficient. This means the ship's turn can continue beyond the planned final turn angle. It can save a significant amount of delta v after circularization, at the cost of a longer ascent to apoapsis. However, if correction flattens the flight too soon in the atmosphere, aerodynamic forces and friction heating can destroy the mission."),
"ptchdev",list("pitch deviation tolerance (dg)",0.1,"Tolerance between intended and actual pitch during correction. If exceeded, pitch will be corrected if pitch correction is active."),
"maxcorr",list("max. pitch correction (dg)",80,"Maximum turning angle to which pitch correction will proceed. (Note: 0 dg = vertical, 90 dg = horizontal flight)."),
"Qcheck",list("check dynamic pressure",false,"Ship's thrust will be adjusted so as not to exceed a certain value of Q."),
"maxQ",list("initial maximum dynamic pressure (hPa)",500,"Maximum Q value beyond which ship's thrust is adjusted."),
"Acheck",list("check acceleration",false,"Ship's thrust will be adjusted so as not to exceed a certain acceleration."),
"maxA",list("initial maximum acceleration (m.s-2)",15,"Maximum acceleration value beyond which ship's thrust is adjusted."),
"Tcheck",list("check temperature",false,"Ship's thrust will be adjusted so as not to exceed the temperature of the reference part."),
"Tpart",list("temperature check part dubbing","","kOS name tag of the part whose skin temperature will be used as the reference for the temperature check."),
"maxT",list("initial maximum temperature (K)",700,"Maximum temperature value beyond which ship's thrust is adjusted."),
"deployFairing",list("automatic fairing deploy",true,"Fairing (kOS name tag 'fairing') will be automatically deployed when dynamic pressure drops below the selected value."),
"deployPress",list("fairing deploy pressure (hPa)",2,"Dynamic pressure value for automatic fairing deployment."),
"gimblock",list("initial gimbal lock",false,"If TRUE, gimbals of 'leng'-tagged engines are locked."),
"gimblim",list("initial gimbal limit (-1: get current avg.)",-1,"Value of gimbal limit for 'leng'-tagged engines."),
"autoStage",list("automatic stage when dV0",false,"(Semi)automatic staging. Staging relies on a zero delta v value for the given stage, so it does not work for stages with combined engines (for example, it will not automatically jettison boosters if the main engine still has power)."),
"finDeltaV",list("manvr. delta v remains (m/s)",0.5,"Target remaining delta v value in maneuver node execution."),
"brakeDeltaV",list("brake delta v",100,"In node execution, the remaining delta v at which throttle-down initiates. Until this value, the ship uses full throttle."),
"remnThrottle",list("remain throttle dv",5,"In node execution, the delta v at which throttle-down stops and holds its value until the maneuver node is finished."),
"autocirc",list("init. circularize",true,"Perform orbit circularization automatically."),
"autogimb",list("auto circ. gimbal",true,"Automatically limit gimbal before the circularization burn."),
"mangimb",list("circ. gimbal lim. (%)",20,"Gimbal limitation during the circularization burn."),
"redgofst",list("reentry offset (dg)",110,"Angular distance from KSC on an equatorial orbit where the reentry burn should start."),
"realt",list("reentry altitude (km)",20,"Periapsis of the reentry maneuver node; should end up in the atmosphere."),
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
}).

inputpane(goon,false,2,currsets["inpx"][0],currsets["inpy"][0],true).

global toApoapsis is input_data["toApoapsis"][1].
global startTurnVelocity is input_data["startTurnVelocity"][1].
global finTurnAltitude is input_data["finTurnAltitude"][1].
global finTurnAngleDelta is input_data["finTurnAngleDelta"][1].
global turnStep is input_data["turnStep"][1].
global finRollAngleDelta is input_data["finRollAngleDelta"][1].
global startRollVelocity is input_data["startRollVelocity"][1].
global finRollAltitude is input_data["finRollAltitude"][1].
global rollIncStep is input_data["rollIncStep"][1].
global steer is input_data["steer"][1].
global ptchdev is input_data["ptchdev"][1].
global maxcorr is input_data["maxcorr"][1].
global maxQ is input_data["maxQ"][1].
global Acheck is input_data["Acheck"][1].
global maxA is input_data["maxA"][1].
global Tcheck is input_data["Tcheck"][1].
global Tpart is input_data["Tpart"][1].
global maxT is input_data["maxT"][1].
global deployPress is input_data["deployPress"][1].
if deployPress < 0.01 {set deployPress to 0.01.}.
global gimblim is input_data["gimblim"][1].
global finDeltaV is input_data["finDeltaV"][1].
global brakeDeltaV is input_data["brakeDeltaV"][1].
global remnThrottle is input_data["remnThrottle"][1].
global mangimb is input_data["mangimb"][1].
global redgofst is input_data["redgofst"][1].
global realt is input_data["realt"][1].
global vcmltp is input_data["vcmltp"][1].
global termlog is input_data["termlog"][1].
global cpuid is input_data["cpuid"][1].
global preset is input_data["preset"][1].
global savepos is input_data["savepos"][1].
global areboot is input_data["areboot"][1].

///////////////////////////////////////////////////////////////////////////////////////////

// GLOBALS & LOCKS

global pidfile is "etc/"+shipdir+"/"+ship:name+"_"+scriptid+"_PID.include.ks".
global templfile is "etc/templates/"+scriptid+"_PID.template.ks".

global hdgptch is 90.
global nodfin is false.

global turning is false.
global turned is 0.
global startTurnAltitude is 0.
global turnAltIncr is 0.
global cnt1 is 0.

global rolling is false.
global rolled is 0.
global startRollAltitude is 0.
global rollAltIncr is 0.
global cnt0 is 0.

global joyvector is ship:up:vector.
lock mvvector to ship:velocity:surface:normalized.
lock mvvf to vxcl(ship:facing:starvector,vxcl(ship:facing:upvector,mvvector)).
lock mvvs to vxcl(ship:facing:upvector,vxcl(ship:facing:forevector,mvvector)).
lock mvvt to vxcl(ship:facing:forevector,vxcl(ship:facing:starvector,mvvector)).
lock velface to vxcl(ship:facing:upvector,mvvector).
lock velplane to vxcl(ship:up:vector,mvvector).
lock steerv to heading(steer,0):vector.
lock trnvector to steerv-velplane.

lock updpitch to vang(joyvector,ship:facing:upvector).
lock rlla1 to vang(vxcl(ship:up:vector,ship:facing:starvector),ship:north:vector).
lock rllv1 to vang(vxcl(ship:up:vector,ship:facing:starvector),vcrs(ship:up:vector,ship:north:vector)).
lock updyaw to vang(joyvector,vxcl(ship:facing:upvector, ship:facing:starvector)).

lock shangl to vang(velface,ship:facing:forevector).
lock srangl to vang(velface,ship:facing:starvector).
lock stangl to vang(velplane, steerv).
lock shiplon to ship:geoposition:lng.

lock currQ to ship:dynamicpressure*1000.
lock bradius to ship:body:radius.
lock apkm to ship:apoapsis/1000.

global maneuverNode is node(0, 0, 0, 0).
global ksclon is -74.5.
lock redg to ksclon-redgofst.

global thrQ is 1.
global thrA is 1.
global thrT is 1.
lock thrott to min(thrQ,min(thrA,thrT)).

global doNode is false.

lock devmv to vang(ship:up:vector,mvvector).
lock devjoy to vang(ship:up:vector,joyvector).
lock devia to (devmv-devjoy).

global slist is list().
list sensors in slist.
global hasaccpart is false.
for s in slist {
	if s:type = "ACC" {
		set hasaccpart to true.
		lock currA to ship:sensors:acc:mag.
	}
}

global hastermpart is false.
if Tpart<>"" and not ship:partsdubbed(Tpart):empty {
	if not badpart(ship:partsdubbed(Tpart),{
		parameter t.
		if t:hasmodule("PartTemperatureState") {
			return t:getmodule("PartTemperatureState"):hasfield("skin temperature").
		}
		else {
			return false.
		}
	},"getmodule(PartTemperatureState):hasfield(skin temperature)") {
		set hastermpart to true.
		lock currT to ship:partsdubbed(Tpart)[0]:getmodule("PartTemperatureState"):getfield("skin temperature"):trim():split(" ")[0]:tonumber().
	}
}

// (landing) engines
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
		if gimblim < 0 {set gimblim to get_gimbal().} else {set_gimbal(gimblim).}.
	}
}

// fairing
global hasfairing is false.
if not ship:partsdubbed("fairing"):empty {
	lock fairs to ship:partsdubbed("fairing").
	if not badpart(fairs,{
		parameter t.
		if t:hasmodule("ModuleProceduralFairing") {
			return t:getmodule("ModuleProceduralFairing"):hasaction("deploy").
		}
		else {
			return false.
		}
	},"(ModuleProceduralFairing):hasaction(deploy)") {
		set hasfairing to true.
		global fairingdeploy is ship:partsdubbed("fairing")[0]:getmodule("ModuleProceduralFairing").
	}
}

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

// GLOBALS & LOCKS END
///////////////// GUI STUFF ////////////////////

ctrlmpanel("controls1","Rocket Control: "+ship:name,list("controls","switches"),true,true,70,currsets["ctrlm1x"][0],currsets["ctrlm1y"][0]).
ctrlmpanel("controls2","Rocket Machinery",list("machinery settings","PID values"),false,true,list(400,600),currsets["ctrlm2x"][0],currsets["ctrlm2y"][0]).
mingui("controls2").

{
// CONTROLS
{
local ctrlset010 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global ctrlapoapsis is ctrlLRCombo("controls1",ctrlset010, "Apoapsis:", round(toApoapsis,0):tostring(),"km", false, false, list(10,1,100)).

if input_data["toApoapsis"]:length=3 {set ctrlapoapsis["label"]:tooltip to input_data["toApoapsis"][2].}.

set ctrlapoapsis["leftbtn"]:onclick to {
	set toApoapsis to chkvalapoap(toApoapsis - apoapstep).
}.
set ctrlapoapsis["txtfield"]:style:width to 40.
set ctrlapoapsis["txtfield"]:onconfirm to {
	parameter str.
	set toApoapsis to chkvalapoap(str:tonumber(toApoapsis)).
}.
lock apoapstep to round(ctrlapoapsis["slider"]:value, 0).
set ctrlapoapsis["steplab"]:style:width to 35.
set ctrlapoapsis["steplab"]:style:align to "center".
set ctrlapoapsis["rightbtn"]:onclick to {
	set toApoapsis to chkvalapoap(toApoapsis + apoapstep).
}.
local function chkvalapoap {
	parameter p.
	local val is round(p, 0).
	set val to max(0, val).
	set ctrlapoapsis["txtfield"]:text to val:tostring().
	return val.
}

local ctrlset020 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global ctrlfinang is ctrlLRCombo("controls1",ctrlset020, "Fin. Ang.:", finTurnAngleDelta:tostring(),"dg", true, false, list(5,1,10)).
if input_data["finTurnAngleDelta"]:length=3 {set ctrlfinang["label"]:tooltip to input_data["finTurnAngleDelta"][2].}.
set ctrlfinang["leftbtn"]:onclick to {
	set finTurnAngleDelta to chkvalfinang(finTurnAngleDelta - estangstep).
}.

set ctrlfinang["txtfield"]:style:width to 50.
set ctrlfinang["txtfield"]:onconfirm to {
	parameter str.
	set finTurnAngleDelta to chkvalfinang(str:tonumber(finTurnAngleDelta)).

}.
set ctrlfinang["chbox"]:ontoggle to {
	parameter tog.
	angvects(tog,vcmltp).
}.
lock estangstep to round(ctrlfinang["slider"]:value, 0).

set ctrlfinang["rightbtn"]:onclick to {
	set finTurnAngleDelta to chkvalfinang(finTurnAngleDelta + estangstep).
}.
local function chkvalfinang {
	parameter p.
	local val is round(p, 0).
	set val to max(0, min(180, val)).
	set ctrlfinang["txtfield"]:text to val:tostring().
	return val.
}

local ctrlset030 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global ctrlestalt is ctrlLRCombo("controls1",ctrlset030,"Fin. Alt.:",finTurnAltitude:tostring(),"m",false,false,list(500,1,1000)).
if input_data["finTurnAltitude"]:length=3 {set ctrlestalt["label"]:tooltip to input_data["finTurnAltitude"][2].}.
set ctrlestalt["leftbtn"]:onclick to {
   set finTurnAltitude to chkvalestalt(finTurnAltitude - estaltstep).
}.

set ctrlestalt["label"]:style:width to 55.
set ctrlestalt["txtfield"]:style:width to 50.
set ctrlestalt["txtfield"]:onconfirm to {
	parameter str.
	set finTurnAltitude to chkvalestalt(str:tonumber(finTurnAltitude)).
}.
lock estaltstep to round(ctrlestalt["slider"]:value,0).
set ctrlestalt["steplab"]:style:width to 35.
set ctrlestalt["rightbtn"]:onclick to {
   set finTurnAltitude to chkvalestalt(finTurnAltitude + estaltstep).
}.
local function chkvalestalt {
	parameter p.
	local val is round(p,0).
	if val < 0 { set val to 0. }.
	set ctrlestalt["txtfield"]:text to val:tostring().
	return val.
}

local ctrlset040 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global ctrlsteer is ctrlLRCombo("controls1",ctrlset040,"Steering:",round(steer,0):tostring(),"dg",true,false,list(10,1,45)).
if input_data["steer"]:length=3 {set ctrlsteer["label"]:tooltip to input_data["steer"][2].}.
set ctrlsteer["leftbtn"]:onclick to {
	set steer to chkvalsteer(steer-steerstep).
	specsteer(steer).
}.
set ctrlsteer["txtfield"]:style:width to 40.
set ctrlsteer["txtfield"]:onconfirm to {
	parameter str.
	set steer to chkvalsteer(str:tonumber(steer)).
	specsteer(steer).
}.
set ctrlsteer["chbox"]:ontoggle to {
	parameter tog.
	steervects(tog,vcmltp).
}.
lock steerstep to round(ctrlsteer["slider"]:value,0).
set ctrlsteer["rightbtn"]:onclick to {
	set steer to chkvalsteer(steer+steerstep).
	specsteer(steer).
}.
local function chkvalsteer {
	parameter p.
	local val is round(p,0).
	if val<0 {set val to choose 360+mod(val,360) if val<-360 else 360+val.}.
	if val>360 {set val to mod(val,360).}.
	set ctrlsteer["txtfield"]:text to val:tostring().
	return val.
}

local ctrlset050 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global ctrlroll is ctrlLRCombo("controls1",ctrlset050,"Rolling:",round(finRollAngleDelta,0):tostring(),"dg",true,false,list(10,1,45)).
if input_data["finRollAngleDelta"]:length=3 {set ctrlroll["label"]:tooltip to input_data["finRollAngleDelta"][2].}.
set ctrlroll["leftbtn"]:onclick to {
	set finRollAngleDelta to chkvalroll(finRollAngleDelta-rollstep).
}.
set ctrlroll["txtfield"]:style:width to 40.
set ctrlroll["txtfield"]:onconfirm to {
	parameter str.
	set finRollAngleDelta to chkvalroll(str:tonumber(finRollAngleDelta)).
}.
set ctrlroll["chbox"]:ontoggle to {
	parameter tog.
	rollvects(tog,vcmltp).
}.
lock rollstep to round(ctrlroll["slider"]:value,0).

set ctrlroll["rightbtn"]:onclick to {
	set finRollAngleDelta to chkvalroll(finRollAngleDelta+rollstep).
}.
local function chkvalroll {
	parameter p.
	local val is round(p,0).
	if val<=-180{set val to -180.}.
	if val>=180{set val to 180.}.
	set ctrlroll["txtfield"]:text to val:tostring().
	return val.
}

local ctrlset060 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global ctrlmxq is ctrlLRCombo("controls1",ctrlset060,"Max Q:",round(maxQ,0):tostring(),"hPa",false,false,list(10,1,100)).
if input_data["maxQ"]:length=3 {set ctrlmxq["label"]:tooltip to input_data["maxQ"][2].}.
set ctrlmxq["leftbtn"]:onclick to {
	set maxQ to chkvalmxq(maxQ-mxqstep).
}.
set ctrlmxq["txtfield"]:style:width to 40.
set ctrlmxq["txtfield"]:onconfirm to {
	parameter str.
	set maxQ to chkvalmxq(str:tonumber(maxQ)).
}.
lock mxqstep to round(ctrlmxq["slider"]:value,0).
set ctrlmxq["steplab"]:style:width to 35.
set ctrlmxq["rightbtn"]:onclick to {
	set maxQ to chkvalmxq(maxQ+mxqstep).
}.
local function chkvalmxq {
	parameter p.
	local val is round(p,0).
	if val<0{set val to 0.}.
	if val>10000{set val to 10000.}.
	set ctrlmxq["txtfield"]:text to val:tostring().
	return val.
}

local ctrlset070 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global ctrlmxa is ctrlLRCombo("controls1",ctrlset070,"Max a:",round(maxA,0):tostring(),"m.s-1",false,false,list(1,1,10)).
if input_data["maxA"]:length=3 {set ctrlmxa["label"]:tooltip to input_data["maxA"][2].}.
set ctrlmxa["leftbtn"]:onclick to {
	set maxA to chkvalmxa(maxA-mxastep).
}.
set ctrlmxa["txtfield"]:style:width to 40.
set ctrlmxa["txtfield"]:onconfirm to {
	parameter str.
	set maxA to chkvalmxa(str:tonumber(maxA)).
}.
lock mxastep to round(ctrlmxa["slider"]:value,0).
set ctrlmxa["steplab"]:style:width to 20.
set ctrlmxa["rightbtn"]:onclick to {
	set maxA to chkvalmxa(maxA+mxastep).
}.
local function chkvalmxa {
	parameter p.
	local val is round(p,0).
	if val<0{set val to 0.}.
	set ctrlmxa["txtfield"]:text to val:tostring().
	return val.
}

ctrlLRCombo("controls1",hasaccpart,"Max a:").

local ctrlset080 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global ctrlmxt is ctrlLRCombo("controls1",ctrlset080,"Max T:",round(maxT,0):tostring(),"K",false,false,list(10,1,100)).
if input_data["maxT"]:length=3 {set ctrlmxt["label"]:tooltip to input_data["maxT"][2].}.
set ctrlmxt["leftbtn"]:onclick to {
	set maxT to chkvalmxt(maxT-mxtstep).
}.
set ctrlmxt["txtfield"]:style:width to 40.
set ctrlmxt["txtfield"]:onconfirm to {
	parameter str.
	set maxT to chkvalmxt(str:tonumber(maxT)).
}.
lock mxtstep to round(ctrlmxt["slider"]:value,0).
set ctrlmxt["steplab"]:style:width to 35.
set ctrlmxt["rightbtn"]:onclick to {
	set maxT to chkvalmxt(maxT+mxtstep).
}.
local function chkvalmxt {
	parameter p.
	local val is round(p,0).
	if val<0{set val to 0.}.
	set ctrlmxt["txtfield"]:text to val:tostring().
	return val.
}

ctrlLRCombo("controls1",hastermpart,"Max T:").

local ctrlset090 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global setgimbal is setValCombo("controls1",ctrlset090,"Gimbal",list(gimblim,0,100),{
	parameter slidval.
	set_gimbal(slidval).
},0,"%",true).
if input_data["gimblim"]:length=3 {set setgimbal["label"]:tooltip to input_data["gimblim"][2].}.
setValCombo("controls1",haslengs,"Gimbal").

local ctrlset100 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global thrtprs is false.
global setthrottle is setValCombo("controls1",ctrlset100,"Throttle",list(0,0,100),{
	parameter slidval.
	set ship:control:MAINTHROTTLE to slidval/100.
},0,"%",true,{
	parameter tog.
	set thrtprs to tog.
	setValCombo("controls1",thrtprs,"Throttle").
	set setVallex["controls1"]["Throttle"]["chbox"]:enabled to true.
}).
set setVallex["controls1"]["Throttle"]["label"]:tooltip to "If the checkbox of this slider is ON, the slider's value can override throttle controls when the 'Engage' button is pressed.".

setValCombo("controls1",thrtprs,"Throttle").
set setVallex["controls1"]["Throttle"]["chbox"]:enabled to true.

local ctrlset110 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global chqprs is false.
global chqtglbtn is ctrlset110:addbutton("Check Q").
if input_data["Qcheck"]:length=3 {set chqtglbtn:tooltip to input_data["Qcheck"][2].}.
set chqtglbtn:toggle to true.
set chqtglbtn:ontoggle to {
	parameter tog.
	set chqprs to tog.
	if tog {

	}
	else {
		set thrQ to 1.
		qpid:reset.
	}
}.
set chqtglbtn:pressed to input_data["Qcheck"][1].

global chaprs is false.
global chatglbtn is ctrlset110:addbutton("Check a").
if input_data["Acheck"]:length=3 {set chatglbtn:tooltip to input_data["Acheck"][2].}.
set chatglbtn:toggle to true.
set chatglbtn:ontoggle to {
	parameter tog.
	set chaprs to tog.
	if tog {

	}
	else {
		set thrA to 1.
		apid:reset.
	}
}.

set chatglbtn:pressed to hasaccpart.
set chatglbtn:enabled to hasaccpart.

global chtprs is false.
global chttglbtn is ctrlset110:addbutton("Check T").
if input_data["Tcheck"]:length=3 {set chttglbtn:tooltip to input_data["Tcheck"][2].}.
set chttglbtn:toggle to true.
set chttglbtn:ontoggle to {
	parameter tog.
	set chtprs to tog.
	if tog {

	}
	else {
		set thrT to 1.
		tpid:reset.
	}
}.
set chttglbtn:pressed to hastermpart.
set chttglbtn:enabled to hastermpart.

local ctrlset120 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global lkgimbbtn is ctrlset120:addbutton("Lock Gimbal").
if input_data["gimblock"]:length=3 {set lkgimbbtn:tooltip to input_data["gimblock"][2].}.
set lkgimbbtn:toggle to true.
set lkgimbbtn:ontoggle to {
	parameter tog.
	lock_gimbal(tog).
}.
if haslengs {
	set lkgimbbtn:pressed to input_data["gimblock"][1].
}
else {
	set lkgimbbtn:enabled to false.
}

global ptchcrprs is false.
global ptchcrrbtn is ctrlset120:addbutton("Pitch correction").
if input_data["corrptch"]:length=3 {set ptchcrrbtn:tooltip to input_data["corrptch"][2].}.
set ptchcrrbtn:toggle to true.
set ptchcrrbtn:ontoggle to {
	parameter tog.
	set ptchcrprs to tog.
}.
set ptchcrrbtn:pressed to input_data["corrptch"][1].

global rcsbtn is ctrlset120:addbutton("RCS").
set rcsbtn:toggle to true.
set rcsbtn:pressed to rcs.
set rcsbtn:ontoggle to {
	parameter tog.
	if tog {
		if not rcs {rcs on.}.
	}
	else {
		if rcs {rcs off.}.
	}
}.

global sasbtn is ctrlset120:addbutton("SAS").
set sasbtn:toggle to true.
set sasbtn:pressed to sas.
set sasbtn:ontoggle to {
	parameter tog.
	if tog {
		if not sas {sas on.}.
	}
	else {
		if sas {sas off.}.
	}
}.

local ctrlset130 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global fdeplprs is false.
global fdeplchb is ctrlset130:addcheckbox("auto fairing deploy",false).
if input_data["deployFairing"]:length=3 {set fdeplchb:tooltip to input_data["deployFairing"][2].}.
set fdeplchb:toggle to true.
set fdeplchb:ontoggle to {
	parameter tog.
	set fdeplprs to tog.
}.
set fdeplchb:pressed to input_data["deployFairing"][1].
set fdeplprs to false.

global fdepllckbtn is ctrlset130:addbutton("Fairing deploy lock").
set fdepllckbtn:tooltip to "Unlocks the 'Deploy Fairing' button.".
set fdepllckbtn:toggle to true.
set fdepllckbtn:ontoggle to {
	parameter tog.
	set fdeplbtn:enabled to tog.
}.

global fdeplbtn is ctrlset130:addbutton("Deploy Fairing").
set fdeplbtn:tooltip to "Deploys the fairing, assuming the actual fairing is kOS tagged as 'fairing'.".
set fdeplbtn:onclick to {
	fairingdeploy:doaction("deploy",true).
	set fdepllckbtn:enabled to false.
	set fdepllckbtn:pressed to false.
	set fdeplbtn:enabled to false.
	set fdeplchb:pressed to false.
	set fdeplchb:enabled to false.
	statmsg("fairing deployed").
}.

set fdeplchb:enabled to hasfairing.
set fdepllckbtn:enabled to hasfairing.
set fdeplbtn:enabled to hasfairing.
if not hasfairing {
	set fdeplchb:pressed to false.
}
set fdeplbtn:enabled to false.

local ctrlset140 is ctrlpanlex["controls1"]["controls"]:addhbox().
global acircprs is false.
global acircchb is ctrlset140:addcheckbox("auto circ.",false).
if input_data["autocirc"]:length=3 {set acircchb:tooltip to input_data["autocirc"][2].}.
set acircchb:toggle to true.
set acircchb:ontoggle to {
	parameter tog.
	set acircprs to tog.
}.
set acircchb:pressed to input_data["autocirc"][1].

global agimbprs is false.
global agimbchb is ctrlset140:addcheckbox("auto gimb.",false).
if input_data["autogimb"]:length=3 {set agimbchb:tooltip to input_data["autogimb"][2].}.
set agimbchb:toggle to true.
set agimbchb:ontoggle to {
	parameter tog.
	set agimbprs to tog.
}.
set agimbchb:pressed to input_data["autogimb"][1].

global circapbtn is ctrlset140:addbutton("Circ. at AP").
set circapbtn:tooltip to "Computes a circularization maneuver node at apoapsis".
set circapbtn:toggle to true.
set circapbtn:ontoggle to {
	parameter tog.
	set nodfin to not tog.
	if tog {
		set circpebtn:pressed to false.
		set renodbtn:pressed to false.
		set circpebtn:enabled to false.
		set renodbtn:enabled to false.
		set execnodbtn:enabled to true.
		set getnodbtn:enabled to false.

		set maneuverNode to node(time:seconds+eta:apoapsis, 0, 0, 0).
		set maneuverNode:prograde to orbit_circ_dv(ship,ship:apoapsis+ship:body:radius).
		add maneuverNode.

	}
	else {
		set execnodbtn:pressed to false.
		remove maneuverNode.
		set execnodbtn:enabled to false.
		set getnodbtn:enabled to true.
		set renodbtn:enabled to true.
		set circpebtn:enabled to true.
	}
}.

global circpebtn is ctrlset140:addbutton("Circ. at PE").
set circpebtn:tooltip to "Computes a circularization maneuver node at periapsis".
set circpebtn:toggle to true.
set circpebtn:ontoggle to {
	parameter tog.
	set nodfin to not tog.
	if tog {
		set circapbtn:pressed to false.
		set renodbtn:pressed to false.
		set circapbtn:enabled to false.
		set renodbtn:enabled to false.
		set execnodbtn:enabled to true.
		set getnodbtn:enabled to false.

		set maneuverNode to node(time:seconds+eta:periapsis, 0, 0, 0).
		set maneuverNode:prograde to orbit_circ_dv(ship,ship:periapsis+ship:body:radius).
		add maneuverNode.

	}
	else {
		set execnodbtn:pressed to false.
		remove maneuverNode.

		set execnodbtn:enabled to false.
		set getnodbtn:enabled to true.
		set renodbtn:enabled to true.
		set circapbtn:enabled to true.
	}
}.

global renodbtn is ctrlset140:addbutton("Reentry").
set renodbtn:tooltip to "Computes a maneuver node for approximate reentry. Reentry values can be adjusted in the machinery settings.".
set renodbtn:toggle to true.
set renodbtn:ontoggle to {
	parameter tog.
	set nodfin to not tog.
	if tog {
		set circapbtn:enabled to false.
		set circpebtn:enabled to false.

		local orbangv is ship:orbit:period/360.
		statmsg("ship:orbit:period: "+ship:orbit:period).
		statmsg("orbangv: "+orbangv).
		statmsg("ship dg: "+geotodg(shiplon)).
		statmsg("re dg: "+geotodg(redg)).
		statmsg("redgdist: "+redgdist()).
		statmsg("time to re: "+redgdist()*orbangv).

		set maneuverNode to node(time:seconds+redgdist()*orbangv, 0, 0, 0).
		set maneuverNode:prograde to orbit_dv(ship,bradius+ship:apoapsis,bradius+(realt*1000)).
		add maneuverNode.

		set execnodbtn:enabled to true.
		set getnodbtn:enabled to false.
	}
	else {
		set execnodbtn:pressed to false.
		remove maneuverNode.

		set execnodbtn:enabled to false.
		set getnodbtn:enabled to true.
		set circapbtn:enabled to true.
	}
}.

global getnodbtn is ctrlset140:addbutton("Get Node").
set getnodbtn:tooltip to "Retrieves a maneuver node created outside this script (for example, manually) to perform 'Execute Node'.".
set getnodbtn:toggle to true.
set getnodbtn:ontoggle to {
	parameter tog.
	if tog {
		set circapbtn:enabled to false.
		set circpebtn:enabled to false.
		set renodbtn:enabled to false.
		if hasnode {
			set maneuverNode to nextnode.
			set execnodbtn:enabled to true.
		}
		else {
			statmsg("no node available").
			set getnodbtn:pressed to false.
		}
	}
	else {

		set execnodbtn:pressed to false.
		remove maneuverNode.
		set execnodbtn:enabled to false.
		set circapbtn:enabled to true.
		set circpebtn:enabled to true.
		set renodbtn:enabled to true.
	}
}.

global execnodbtn is ctrlset140:addbutton("Execute Node").
set execnodbtn:tooltip to "Executes the planned maneuver node. Does not use automatic warp.".
set execnodbtn:toggle to true.
set execnodbtn:ontoggle to {
	parameter tog.

	prepnodex(tog).
	set doNode to tog.
	if tog {
		ctrlreset(true).
	}
	else {
		ctrlreset(true).
		set agimbchb:enabled to true.
	}
}.
set execnodbtn:enabled to false.

local ctrlset150 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global engagprs is false.
global engagpbtn is ctrlset150:addbutton("Engage").
set engagpbtn:tooltip to "Enables the part of the loop that actually controls the ship, such as steering and throttle control. Throttle controls can be overridden using the 'Throttle' slider by clicking the slider's checkbox. This button should be toggled ON before the first stage.".
set engagpbtn:toggle to true.
set engagpbtn:ontoggle to {
	parameter tog.
	set engagprs to tog.
	if tog {

	}
	else {
		ctrlreset(true).
		set ptchcrrbtn:pressed to false.
		set setVallex["controls1"]["Throttle"]["slider"]:value to ship:control:pilotmainthrottle.
	}
}.


local ctrlset160 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global astgprs is false.
global astgchb is ctrlset160:addcheckbox("auto stage",false).
if input_data["autoStage"]:length=3 {set astgchb:tooltip to input_data["autoStage"][2].}.
set astgchb:toggle to true.
set astgchb:ontoggle to {
	parameter tog.
	set astgprs to tog.
}.
set astgchb:pressed to input_data["autoStage"][1].

global stagelckbtn is ctrlset160:addbutton("Stage lock").
set stagelckbtn:tooltip to "Unlocks the 'Stage' button.".
set stagelckbtn:toggle to true.
set stagelckbtn:ontoggle to {
	parameter tog.
	set stagebtn:enabled to tog.
}.

global stagebtn is ctrlset160:addbutton("Stage").
set stagebtn:tooltip to "Performs the 'stage' command.".
set stagebtn:onclick to {
	stage.
	set stagelckbtn:pressed to false.
	statmsg("stage").
}.
set stagebtn:enabled to false.

}
// switches
{

local swtset010 is ctrlpanlex["controls1"]["switches"]:addhbox().
global termlogchb is swtset010:addcheckbox("Terminal Logs",false).
set termlogchb:tooltip to "Sends status messages also to the other terminal.".
set termlogchb:toggle to true.
set termlogchb:ontoggle to {
	parameter tog.
	set termlog to tog.
}.
local cpuopts is list().
for lcpu in SHIP:MODULESNAMED("kOSProcessor") {
	cpuopts:add(lcpu:tag).
}
global menucpu is swtset010:addpopupmenu().
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
global solpanbtn is swtset010:addbutton("Ext./Retr. Solar Panels").
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

// machinery settings
{
// ship title
local machtitle is ctrlpanlex["controls2"]["machinery settings"]:addlabel(ship:name).
set machtitle:style:align to "center".
set machtitle:style:hstretch to true.

local mchset010 is ctrlpanlex["controls2"]["machinery settings"]:addvbox().
global dlgptchdv is
mchnrline("controls2",mchset010,"ptchdev",{
	parameter str.
	set ptchdev to str:tonumber(ptchdev).
}).

global dlgmxcorr is
mchnrline("controls2",mchset010,"maxcorr",{
	parameter str.
	set maxcorr to str:tonumber(maxcorr).
}).

global dlgtrnvel is
mchnrline("controls2",mchset010,"startTurnVelocity",{
	parameter str.
	set startTurnVelocity to str:tonumber(startTurnVelocity).
}).

global dlgtrnistp is
mchnrline("controls2",mchset010,"turnStep",{
	parameter str.
	set turnStep to str:tonumber(turnStep).
}).

global dlgrllfalt is
mchnrline("controls2",mchset010,"finRollAltitude",{
	parameter str.
	set finRollAltitude to str:tonumber(finRollAltitude).
}).

global dlgrllistp is
mchnrline("controls2",mchset010,"rollIncStep",{
	parameter str.
	set rollIncStep to str:tonumber(rollIncStep).
}).

global dlgtdplprs is
mchnrline("controls2",mchset010,"deployPress",{
	parameter str.
	set deployPress to str:tonumber(deployPress).
}).

local mchset020 is ctrlpanlex["controls2"]["machinery settings"]:addvbox().
global dlgfndv is
mchnrline("controls2",mchset020,"finDeltaV",{
	parameter str.
	set finDeltaV to str:tonumber(finDeltaV).
}).

global dlgbrkdv is
mchnrline("controls2",mchset020,"brakeDeltaV",{
	parameter str.
	set brakeDeltaV to str:tonumber(brakeDeltaV).
}).

global dlgrmthr is
mchnrline("controls2",mchset020,"remnThrottle",{
	parameter str.
	set remnThrottle to str:tonumber(remnThrottle).
}).

local mchset030 is ctrlpanlex["controls2"]["machinery settings"]:addvbox().
global dlgmangimb is
mchnrline("controls2",mchset030,"mangimb",{
	parameter str.
	set mangimb to str:tonumber(mangimb).
}).

global dlgreoff is
mchnrline("controls2",mchset030,"redgofst",{
	parameter str.
	set redgofst to str:tonumber(redgofst).
}).

global dlgrealt is
mchnrline("controls2",mchset030,"realt",{
	parameter str.
	set realt to str:tonumber(realt).
}).

local mchset040 is ctrlpanlex["controls2"]["machinery settings"]:addvbox().
global dlgmltp is
mchnrline("controls2",mchset040,"vcmltp",{
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

global qpid is pidloop(qkp, qki, qkd, 0.1, 1, qeps).
global function upd_qpid {
	parameter spoint.
	parameter feedback.
	set qpid:setpoint to spoint.
	return qpid:update(time:seconds, feedback).
}
global apid is pidloop(akp, aki, akd, 0.1, 1, aeps).
global function upd_apid {
	parameter spoint.
	parameter feedback.
	set apid:setpoint to spoint.
	return apid:update(time:seconds, feedback).
}
global tpid is pidloop(tkp, tki, tkd, 0.1, 1, teps).
global function upd_tpid {
	parameter spoint.
	parameter feedback.
	set tpid:setpoint to spoint.
	return tpid:update(time:seconds, feedback).
}
}

if hasaccpart {set chatglbtn:pressed to input_data["Acheck"][1].}.
if hastermpart {set chttglbtn:pressed to input_data["Tcheck"][1].}.

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

local qchkpidset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global qkpdlg is valbox("controls2",qchkpidset,"qkp","qchk kp:",qpid:kp,{
	parameter str.
	set qpid:kp to str:tonumber(qpid:kp).
},
"ship dyn. press.").
global qkidlg is valbox("controls2",qchkpidset,"qki","qchk ki:",qpid:ki,{
	parameter str.
	set qpid:ki to str:tonumber(qpid:ki).
}).
global qkddlg is valbox("controls2",qchkpidset,"qkd","qchk kd:",qpid:kd,{
	parameter str.
	set qpid:kd to str:tonumber(qpid:kd).
}).
global qepsdlg is valbox("controls2",qchkpidset,"qeps","qchk eps:",qpid:epsilon,{
	parameter str.
	set qpid:epsilon to str:tonumber(qpid:epsilon).
}).

local achkpidset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global akpdlg is valbox("controls2",achkpidset,"akp","achk kp:",apid:kp,{
	parameter str.
	set apid:kp to str:tonumber(apid:kp).
},
"ship acceleration.").
global akidlg is valbox("controls2",achkpidset,"aki","achk ki:",apid:ki,{
	parameter str.
	set apid:ki to str:tonumber(apid:ki).
}).
global akddlg is valbox("controls2",achkpidset,"akd","achk kd:",apid:kd,{
	parameter str.
	set apid:kd to str:tonumber(apid:kd).
}).
global aepsdlg is valbox("controls2",achkpidset,"akeps","achk eps:",apid:epsilon,{
	parameter str.
	set apid:epsilon to str:tonumber(apid:epsilon).
}).

local tchkpidset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global tkpdlg is valbox("controls2",tchkpidset,"tkp","tchk kp:",tpid:kp,{
	parameter str.
	set tpid:kp to str:tonumber(tpid:kp).
},
"ship temperature").
global tkidlg is valbox("controls2",tchkpidset,"tki","tchk ki:",tpid:ki,{
	parameter str.
	set tpid:ki to str:tonumber(tpid:ki).
}).
global tkddlg is valbox("controls2",tchkpidset,"tkd","tchk kd:",tpid:kd,{
	parameter str.
	set tpid:kd to str:tonumber(tpid:kd).
}).
global tepsdlg is valbox("controls2",tchkpidset,"tkeps","tchk eps:",tpid:epsilon,{
	parameter str.
	set tpid:epsilon to str:tonumber(tpid:epsilon).
}).
}

// FUNCTIONS

function updroll {
	if rlla1<=90 {
		return rllv1.
	}
	else {
		return -rllv1.
	}
}

function redgdist {
	local redgdelta is (geotodg(redg)-geotodg(shiplon)).
	if redgdelta<0 {
		return (360+redgdelta).
	}
	else {
		return (redgdelta).
	}
}

function angvects {
	parameter d.
	parameter mltp is 15.
	if (d) {
		global joyv is vecdraw(
			V(0,0,0),
			joyvector*mltp,
			RGB(1,0,1),
			"JOYVECTOR",
			1.0,
			true,
			0.2
		).
		set joyv:vecupdater to {return joyvector*mltp.}.
		global angvelvector is vecdraw(
			V(0,0,0),
			mvvector*mltp,
			RGB(0,1,1),
			"VELOCITY",
			1.0,
			true,
			0.2
		).
		set angvelvector:vecupdater to {return mvvector*mltp.}.
	}
	else {
		set joyv:vecupdater to DONOTHING.
		set angvelvector:vecupdater to DONOTHING.

		set joyv to 0.
		set angvelvector to 0.

	}
}

function steervects {
	parameter d.
	parameter mltp is 15.
	if (d) {
		global lstrv is vecdraw(
			V(0,0,0),
			steerv*mltp,
			RGB(1,0,1),
			"STEER",
			1.0,
			true,
			0.2
		).
		set lstrv:vecupdater to {return steerv*mltp.}.
		global lmvvector is vecdraw(
			V(0,0,0),
			mvvector*mltp,
			RGB(0,1,1),
			"VELOCITY",
			1.0,
			true,
			0.2
		).
		set lmvvector:vecupdater to {return mvvector*mltp.}.
		global lvelplanev is vecdraw(
			V(0,0,0),
			velplane*mltp,
			RGB(0,1,1),
			"VEL-PLANE",
			1.0,
			true,
			0.2
		).
		set lvelplanev:vecupdater to {return velplane*mltp.}.
	}
	else {
		set lstrv:vecupdater to DONOTHING.
		set lmvvector:vecupdater to DONOTHING.
		set lvelplanev:vecupdater to DONOTHING.
		set lstrv to 0.
		set lmvvector to 0.
		set lvelplanev to 0.
	}
}

function rollvects {
	parameter d.
	parameter mltp is 15.
	if (d) {
		global shfavec is vecdraw(
			V(0,0,0),
			ship:up:vector*mltp,
			RGB(1,0,1),
			"up:vector",
			1.0,
			true,
			0.2
		).
		set shfavec:vecupdater to {return ship:up:vector*mltp.}.

		global shevec is vecdraw(
			V(0,0,0),
			vcrs(ship:up:vector,ship:north:vector)*mltp,
			RGB(0,1,1),
			"EAST",
			1.0,
			true,
			0.2
		).
		set shevec:vecupdater to {return vcrs(ship:up:vector,ship:north:vector)*mltp.}.

		global shnovec is vecdraw(
			V(0,0,0),
			ship:north:vector*mltp,
			RGB(0,1,1),
			"north:vector",
			1.0,
			true,
			0.2
		).
		set shnovec:vecupdater to {return ship:north:vector*mltp.}.

		global shxstarv is vecdraw(
			V(0,0,0),
			vxcl(ship:up:vector,ship:facing:starvector)*mltp,
			RGB(0,0,1),
			"x:starvector",
			1.0,
			true,
			0.2
		).
		set shxstarv:vecupdater to {return vxcl(ship:up:vector,ship:facing:starvector)*mltp.}.
	}
	else {
		set shfavec:vecupdater to DONOTHING.
		set shevec:vecupdater to DONOTHING.
		set shnovec:vecupdater to DONOTHING.
		set shxstarv:vecupdater to DONOTHING.
		set shfavec to 0.
		set shevec to 0.
		set shnovec to 0.
		set shxstarv to 0.
	}
}

function screeninit {
	if not logwindow {
		clearscreen.
	}
}

function roll_init {
	set startRollAltitude to ship:altitude.
	if finRollAngleDelta=0 {set rollAltIncr to 0.}
	else {
		set rollAltIncr to (finRollAltitude-ship:altitude)/(abs(finRollAngleDelta)/rollIncStep).
	}
	if finRollAngleDelta<0 {set rollIncStep to -rollIncStep.}.
	return true.
}

function turn_init {
	set startTurnAltitude to ship:altitude.
	set turnAltIncr to get_turnAltIncr.
	return true.
}

function get_turnAltIncr {
	if finTurnAngleDelta=0 {return 0.}.
	return (finTurnAltitude-ship:altitude)/(finTurnAngleDelta/turnStep).
}

function specsteer {
	parameter s.
	if ship=kuniverse:activevessel {SET NAVMODE TO "surface".}.
	set steer to s.
	set steer to round(steer,0).
	set ctrlsteer["txtfield"]:text to steer:tostring().
}

// save load

function savvalsload {

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

	set qpid:kp to savvals["qkp"].
	set qkpdlg["txtfield"]:text to qpid:kp:tostring().
	set qpid:ki to savvals["qki"].
	set qkidlg["txtfield"]:text to qpid:ki:tostring().
	set qpid:kd to savvals["qkd"].
	set qkddlg["txtfield"]:text to qpid:kd:tostring().
	set qpid:epsilon to savvals["qeps"].
	set qepsdlg["txtfield"]:text to qpid:epsilon:tostring().

	set apid:kp to savvals["akp"].
	set akpdlg["txtfield"]:text to apid:kp:tostring().
	set apid:ki to savvals["aki"].
	set akidlg["txtfield"]:text to apid:ki:tostring().
	set apid:kd to savvals["akd"].
	set akddlg["txtfield"]:text to apid:kd:tostring().
	set apid:epsilon to savvals["aeps"].
	set aepsdlg["txtfield"]:text to apid:epsilon:tostring().

	set tpid:kp to savvals["tkp"].
	set tkpdlg["txtfield"]:text to tpid:kp:tostring().
	set tpid:ki to savvals["tki"].
	set tkidlg["txtfield"]:text to tpid:ki:tostring().
	set tpid:kd to savvals["tkd"].
	set tkddlg["txtfield"]:text to tpid:kd:tostring().
	set tpid:epsilon to savvals["teps"].
	set tepsdlg["txtfield"]:text to tpid:epsilon:tostring().

}

function savvalssave {

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

	set savvals["qkp"] to qpid:kp.
	set savvals["qki"] to qpid:ki.
	set savvals["qkd"] to qpid:kd.
	set savvals["qeps"] to qpid:epsilon.

	set savvals["akp"] to apid:kp.
	set savvals["aki"] to apid:ki.
	set savvals["akd"] to apid:kd.
	set savvals["aeps"] to apid:epsilon.

	set savvals["tkp"] to tpid:kp.
	set savvals["tki"] to tpid:ki.
	set savvals["tkd"] to tpid:kd.
	set savvals["teps"] to tpid:epsilon.

}

// FUNCTIONS END

// TRIGGERS

when ship:velocity:surface:mag >= startRollVelocity then {
	set rolling to roll_init().
	statmsg("started rolling ship to "+finRollAngleDelta).
}

when ship:velocity:surface:mag >= startTurnVelocity then {
	set turning to turn_init().
	statmsg("started turning ship to "+finTurnAngleDelta).
	//prepare fairing deploy
	set fdeplprs to fdeplchb:pressed.
}

on (finTurnAngleDelta) {
	if ship:velocity:surface:mag >= startTurnVelocity {
		set turning to turn_init().
		set ctrlfinang["txtfield"]:text to finTurnAngleDelta:tostring().
	}
	return true.
}

on (finTurnAltitude) {
	set turnAltIncr to get_turnAltIncr.
	return true.
}

if hastermpart {
	when ship:partsdubbed(Tpart):empty then {
		set hastermpart to false.
		set chttglbtn:pressed to hastermpart.
		set chttglbtn:enabled to hastermpart.
		ctrlLRCombo("controls1",hastermpart,"Max T:").
	}
}

// MAIN START

chkpreset(input_data["ldpres"][1],input_data["preset"][1]).
screeninit().
set trmbtn:pressed to true.
rcs on.

global looptime is 0.
statmsg("rocket ready").

// lock vertvel to ship:verticalspeed.
// lock srfvel to ship:groundspeed.
// lock allvel to sqrt(srfvel^2+vertvel^2)*(vertvel/abs(vertvel)). // overal velocity
// global prevspeed is ship:verticalspeed.
// global acctim is time:seconds.
// global myacc is 0.
global tclmn1 is currsets["tclmn1"][0].
global tclmn2 is currsets["tclmn2"][0].
global tclmn3 is currsets["tclmn3"][0].

until scriptend {
	set looptime to time:seconds.

	// if (time:seconds-acctim)>=0.001 {
		// set myacc to (allvel-prevspeed)/(time:seconds-acctim).
		////if myacc <=0 {set myacc to 0.}.
		// set prevspeed to allvel.
		// set acctim to time:seconds.
	// }

	if chqprs {
		if currQ > 1 {
			set thrQ to upd_qpid(maxQ,currQ).
		}
	}

	if chaprs {
		set thrA to upd_apid(maxA,currA).
	}

	if chtprs {
		set thrT to upd_tpid(maxT,currT).
	}

	if rolling {
		if abs(rolled) >= abs(finRollAngleDelta) {
			set rolled to finRollAngleDelta.
			set rolling to false.
		}
		if rolling and ship:altitude >= startRollAltitude+(rollAltIncr*cnt0) {
			set rolled to rolled+rollIncStep.
			set cnt0 to cnt0+1.
		}
	}

	if turning {
		if turned >= finTurnAngleDelta {
			set turned to finTurnAngleDelta.
			set turning to false.
		}
		if turning and ship:altitude >= startTurnAltitude+(turnAltIncr*cnt1) {
			set turned to turned+turnStep.
			set hdgptch to 90-turned.
			set cnt1 to cnt1+1.
		}
	}

	if ptchcrprs {
		if devia >= ptchdev and turned >= finTurnAngleDelta { // devmv > input_data["finTurnAngleDelta"][1] { //
			if devmv<maxcorr {
				set finTurnAngleDelta to round(devmv,2).
				set ctrlfinang["txtfield"]:text to finTurnAngleDelta:tostring().
			}
			else {
				set ptchcrrbtn:pressed to false.
			}
		}
	}

	if fdeplprs {
		if currQ < deployPress {set fdeplbtn:pressed to true.}.
	}

	if engagprs {

		set ship:control:top to 0.
		set ship:control:fore to 0.
		set ship:control:starboard to 0.
		set ship:control:yaw to upd_ywpid(90,updyaw).
		set ship:control:pitch to upd_ptchpid(90,updpitch).
		set ship:control:roll to upd_rllpid(rolled,updroll()).

		if not thrtprs {
			set ship:control:mainthrottle to thrott.
			set setVallex["controls1"]["Throttle"]["slider"]:value to thrott*100.
		}

		if apkm >= toApoapsis {
			set engagpbtn:pressed to false.

			if acircprs {
				set circapbtn:pressed to true.
				set execnodbtn:pressed to true.
				set acircchb:pressed to false.
			}
			set acircchb:enabled to false.
		}
	}

	if doNode {
		if haslengs and agimbprs {
			set setgimbal["slider"]:value to round(mangimb,0).
			setgimbal["setbtn"]:onclick().
			set agimbchb:pressed to false.
			set agimbchb:enabled to false.
		}
		execnode().
		if nodfin {
			set circapbtn:pressed to false.
			set circpebtn:pressed to false.
			set renodbtn:pressed to false.
			set nodfin to false.
		}
	}

	if astgprs {
		if stage:deltav:current <= 0 and stage:ready {
			stage.
			statmsg("auto staged").
		}
	}

	set joyvector to heading(steer,hdgptch):vector.

	if not logwindow {
		print "OPCODESLEFT: ["+OPCODESLEFT+"]   " at(tclmn1,0). print "curtime: ["+round(curtime,1)+"]   " at(tclmn2,0). print "loop:["+(time:seconds-looptime)+"]----------" at(tclmn3,0).
	}

	if termdata {

		print "current AP / final AP: ["+round(apkm,0)+"] / ["+toApoapsis+"]            " at(tclmn1,2).
		print "current thr. / thr. setpoint: ["+round(ship:control:MAINTHROTTLE,3)+"] / ["+thrott+"]            " at(tclmn1,3).
		print "current Q / Q throttle part: ["+round(currQ,2)+"] / ["+thrQ+"]            " at(tclmn1,3).
		if hasaccpart {
			print "current a / a thr. part: ["+(round(currA,2))+"] / ["+(round(thrA,2))+"]            " at(tclmn1,4).
		}
		if hastermpart {
			print "current T / T thr. part: ["+(round(currT,2))+"] / ["+(round(thrT,2))+"]            " at(tclmn1,5).
		}
		print "rolling:"+rolling+"  " at(tclmn1,6). print "rolled: ["+(round(rolled,2))+"]    " at(tclmn2,6).
		print "turning:"+turning+"  " at(tclmn1,7). print "turned:["+(round(turned,2))+"]    " at(tclmn2,7).
		print "pitch dev.: ["+round(devia,2)+"]   " at(tclmn1,8). print "fin. turn: ["+finTurnAngleDelta+"]   " at(tclmn2,8).

		if showverbose {
			print "upd_ywpid: ["+round(ship:control:yaw,2)+"]   " at(tclmn1,10). print "upd_ptchpid: ["+round(SHIP:CONTROL:pitch,2)+"]    " at(tclmn2,10). print "upd_rllpid: ["+round(SHIP:CONTROL:roll,2)+"]    " at(tclmn3,10).
			print "updyaw: ["+round(updyaw,2)+"]    " at(tclmn1,11). print "updpitch: ["+round(updpitch,2)+"]    " at(tclmn2,11). print "updroll: ["+round(updroll(),2)+"]    " at(tclmn3,11).
		}
	}
	wait 0.
}

ctrlreset(true).

if areboot="yes" {exit_cleanup().reboot.}
else if areboot="ask" {ynmsg(list("Reboot CPU?"),red,{exit_cleanup().reboot.},{},true).}.
exit_cleanup().
