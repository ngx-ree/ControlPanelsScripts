// g66.ks by ngx

@lazyglobal off.

global scriptid is "g66".
declare parameter goon to false.
runoncepath("lib/settings.lib.ks").
runoncepath("lib/common.lib.ks").
runoncepath("lib/ctrlpanel.lib.ks").
runoncepath("lib/screen.lib.ks").
runoncepath("lib/ldsv.lib.ks").

clearscreen.
clearguis().
loadguipos().

global starttime is time:seconds.
lock curtime to time:seconds-starttime.
global scriptend is false.

ctrlpanel(true,true,true,currsets["ctrlw"][0],currsets["ctrlx"][0],currsets["ctrly"][0],1,1,0).
set trmbtn:pressed to true. // initially, let's have terminal data turned on

global input_data is lexicon(
// velocity section
"finvel",list("final velocity (m/s)",20,"The probe's intended forward velocity."),
"janglim",list("'joystick' angle limit (dg)",60,"The maximum angle to which the 'virtual joystick' can tilt."),
"veltrsh",list("velocity threshold (for stop levelling) (m/s)",10,"While stopping or landing, this value sets the lowest velocity at which joystick control mode stays active. If the velocity drops below this threshold, joystick mode switches off and only translation controls are used."),
"abrptstop",list("abrupt stop",false,"If TRUE, stopping sequence uses 80 dg joystick tilt and (almost) full throttle. This makes stopping faster, but can change flight height. If FALSE, stopping uses normal flight behavior as if velocity was set to 0 with very small changes to flying height."),
// steering section
"steer",list("initial steering (dg) (-1:fwd, -2:tgt, -3:wpt)",-1,"Initial probe steering after the script starts. fwd = Steer in the probe's current direction, tgt = Steer to target if one is selected, wpt = Steer toward the active waypoint."),
"tsteer",list("steering deviation tolerance (dg)",3,"The maximum deviation between effective and set steering after which heading correction occurs."),
"fsteerchb",list("initial force steer",false,"If TRUE, the 'force steer' function will be enabled right after the script starts."),
"fsteer",list("force steer coefficient",3,"Multiplier for steering deviation tolerance. When deviation exceeds tolerance * coefficient, the 'force steer' function is activated."),
"chwheels",list("check for wheels",true,"If TRUE, the script will check for the presence of wheels to enable 'friction settings' in the 'switches' tab."),
// flight section
"mvtype",list("flight type",list("AGL","ALT"),"Initial settings for the probe's flight type. 'AGL' means keep a constant height above ground level, 'ALT' means keep a constant altitude."),
"findist",list("flight distance (m)",10000,"Flight distance after which the probe will land automatically if 'Land at Target' is enabled and no target or waypoint is selected. Flight distance takes precedence over flight time."),
"fintime",list("flight time (s)",0,"Flight time after which the probe will land automatically if 'Land at Target' is enabled and no target or waypoint is selected. To use flight time, set flight distance to 0."),
"mvalt",list("flight height (m)",50,"The probe’s intended flight height."),
"safehght",list("safe height (m)",150,"Minimum radar height above the ground when flying in ALT (fixed altitude) mode."),
"rdland",list("radar landed height (m)",2.6,"During the landing sequence, if the probe's radar altitude is less than this value, the probe is considered landed. Depends on the probe's dimensions, so measure it before use."),
"mxlandv",list("max. landing velocity (-m/s)",-2,"Maximum vertical velocity for landing (negative value means descending)."),
"minvertvel",list("minimal vertical velocity (m/s)",-15,"Maximum allowed descent velocity (value < 0). If exceeded, the probe's descent velocity is reduced so it does not surpass this value."),
"maxvertvel",list("maximal vertical velocity (m/s)",20,"Maximum allowed ascent velocity. If exceeded, the probe's ascent velocity is reduced so it does not surpass this value."),
"lndvelcoef",list("landing vertical velocity coef.",10,"Coefficient for reducing the probe's landing velocity. During landing, radar altitude divided by this value determines descent velocity (for example: if 10, descent velocity at 100 m will be 10 m/s, at 50 m will be 5 m/s, etc.) until the maximum landing velocity is reached."),
"normvvelcoef",list("normal vertical velocity coef.",6,"Coefficient for the probe's vertical velocity setpoint based on its altitude above the ground during normal flight (not landing). It serves to reduce vertical speed and avoid overshooting the planned altitude."),
// approach section
"tgtlnd",list("initial land at target ",false,"If TRUE, the probe will initiate approach and landing sequences when approaching the target. Otherwise, it will just try to continue flying toward the target. Maind that the position is reset automatically only in case of 'Go Target' and 'Go Waypoint'."),
"appfwd",list("initial fwd. correction on approach",true,"If enabled, the probe uses RCS for velocity reduction during approach in addition to joystick controls."),
"appdist",list("target approach distance base (m)",3000,"Distance from the target at which approach is initiated. If the approach sequence should not be performed, set this value to the same value as 'target landing distance base'. Do not use 0 or very small numbers, as these will never be reached due to various inaccuracies."),
"lnddist",list("target landing distance base (m or s)",70,"Distance from the target at which landing is initiated. This is in meters in case the flight is based on the distance from targeted position, or in seconds in case the flight is based on time duration. Do not use 0 or very small numbers, as these will never be reached due to various inaccuracies."),
"minappvel",list("minimum approach velocity (m/s)",8,"Limit for reducing the probe's velocity during approach."),
"minappalt",list("minimum approach height (m)",15,"Limit for reducing the probe's height during approach."),
// laser section
"haslaser",list("has laser",true,"Probe has three laser distance meters with KOS name tags 'lsrl', 'lsrm' and 'lsrr'."),
"sellaser",list("selected laser",list("left","middle","right"),"Initially selected laser."),
"lsractive",list("initial laser active",true,"If set, the laser is active right after the script starts."),
"lsrvisible",list("initial laser visible",false,"If set, the laser is visible right after the script starts."),
"detcoef",list("laser detection distance coeficient",10,"Coefficient for evade procedure initiation when a ground obstacle is detected. The evade process starts when obstacle distance is less than velocity * coefficient."),
"evdlim",list("laser evade count limit",5,"Number of consecutive positive obstacle detections (cycles) required to initiate evasion."),
"lsrslope",list("laser detection maximum pitch (dg)",30,"Maximum laser angle between the laser beam and forevector for the evade procedure to start. This tries to prevent false positives from detecting the ground below the probe when it is tilted for forward flight."),
"lsrralt",list("laser detection maximum radar altitude (m)",300,"No detection will trigger the evade process above this (radar) altitude."),
"lsrvcut",list("laser detection velocity cut coeficient",1.5,"Value used to divide current velocity in the evade process. If evasion is initiated, the probe brakes to velocity / coefficient and sets that as the new velocity."),
// engine/power section
"gimblck",list("initial gimbal lock",true,"If set, engine gimbals will be locked right after the script starts. Engines must have KOS name tag set to 'leng'."),
"emergthr",list("initial emergency throttle",true,"If set, emergency throttle will be enabled right after the script starts."),
"emergcoef",list("emergency throttle coefficient",1.5,"If the probe is not using the 'Alt. by Throttle' function and its vertical descent velocity (fall) exceeds minimum vertical velocity * coefficient, 'Alt. by Throttle' is engaged."),
"minfuel",list("minimum safe fuel (%)",5,"If monopropellant fuel falls below this value, the landing procedure is automatically initiated."),
"pwrlim",list("power limit (%)",5,"If electric charge falls below this value, the landing procedure is automatically initiated."),
// misc
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

global mopts is input_data["mvtype"][1].

inputpane(goon,false,2,currsets["inpx"][0],currsets["inpy"][0],true).

set input_data["appdist"][1] to max(input_data["appdist"][1],input_data["lnddist"][1]). // prevent having approach distance smaller than landing distance

global finvel is input_data["finvel"][1].
global janglim is input_data["janglim"][1].
global veltrsh is input_data["veltrsh"][1].
global steer is input_data["steer"][1].
global tsteer is input_data["tsteer"][1].
global fsteer is input_data["fsteer"][1].
global mvtype is input_data["mvtype"][1].
global findist is input_data["findist"][1].
global fintime is input_data["fintime"][1].
global mvalt is input_data["mvalt"][1].
global safehght is input_data["safehght"][1].
global rdland is input_data["rdland"][1].
global mxlandv is min(-1,input_data["mxlandv"][1]).
global minvertvel is input_data["minvertvel"][1].
global maxvertvel is input_data["maxvertvel"][1].
global lndvelcoef is input_data["lndvelcoef"][1].
global normvvelcoef is input_data["normvvelcoef"][1].
global appdist is input_data["appdist"][1].
global lnddist is input_data["lnddist"][1].
global minappvel is input_data["minappvel"][1].
global minappalt is input_data["minappalt"][1].
global haslaser is input_data["haslaser"][1].
global sellaser is input_data["sellaser"][1].
global detcoef is input_data["detcoef"][1].
global evdlim is input_data["evdlim"][1].
global lsrslope is input_data["lsrslope"][1].
global lsrralt is input_data["lsrralt"][1].
global lsrvcut is input_data["lsrvcut"][1].
global emergcoef is input_data["emergcoef"][1].
global minfuel is input_data["minfuel"][1].
global pwrlim is input_data["pwrlim"][1].
global vcmltp is input_data["vcmltp"][1].
global termlog is input_data["termlog"][1].
global cpuid is input_data["cpuid"][1].
global savepos is input_data["savepos"][1].
global areboot is input_data["areboot"][1].

// GLOBALS & LOCKS

global pidfile is "etc/"+shipdir+"/"+ship:name+"_"+scriptid+"_PID.include.ks".
global templfile is "etc/templates/"+scriptid+"_PID.template.ks".

global startpos is ship:geoposition.
lock drdist to sqrt(abs(startpos:distance^2-rdalt^2)).

global begtime is time:seconds.
lock drtime to time:seconds-begtime.

global set_alt is mvalt.
global set_vel is finvel.
global mthr is 0.
global approach is false.
global velcut is 1.
global sbdoffst is 0.

lock dopitch to (pitchprs or thrfwdprs or stopprs).
lock doroll to (rollprs or thrfwdprs or stopprs).
global doyaw is false.

lock rdalt to alt:radar.
lock vertvel to ship:verticalspeed.
lock srfvel to ship:groundspeed*vdir()[0].
lock fwdvel to srfvel*abs(cos(stangl)).
lock sidvel to ship:groundspeed*abs(sin(stangl))*vdir()[1].
lock allvel to sqrt(srfvel^2+vertvel^2)*(vertvel/abs(vertvel)).

global joyvector is ship:up:vector.
lock mvvector to ship:velocity:surface:normalized.
lock mvvf to vxcl(ship:facing:starvector,vxcl(ship:facing:upvector,mvvector)).
lock mvvs to vxcl(ship:facing:upvector,vxcl(ship:facing:forevector,mvvector)).
lock mvvt to vxcl(ship:facing:forevector,vxcl(ship:facing:starvector,mvvector)).
lock velface to vxcl(ship:facing:upvector,mvvector).
lock velplane to vxcl(ship:up:vector,mvvector).
lock steerv to heading(steer,0):vector.
lock trnvector to steerv-velplane.
lock ssidv to v(0,0,0).

lock updpitch to vang(joyvector,ship:facing:forevector).
lock updroll to vang(joyvector,ship:facing:starvector).
lock updyaw to vang(steerv,vxcl(ship:up:vector, ship:facing:starvector)).

lock shangl to vang(velface,ship:facing:forevector).
lock srangl to vang(velface,ship:facing:starvector).
lock stangl to vang(velplane, steerv).

lock altp1 to max(0,(1-(rdalt/min(safehght,set_alt)))).
lock altp2 to max(0,min(1,(vertvel/minvertvel))).
lock altparm to min(1,(altp1+altp2)).

lock slanded to (rdalt<rdland and vertvel<0.1).

global wpnt is 0.
lock curwpnt to allwaypoints()[wpnt].

/// RESOURCES & PARTS

// addon(s)
global hasrt is addons:available("RT").
if hasrt {
	global rtaddon is addons:rt.
	lock conn to ship:connection:isconnected.
	lock aconn to rtaddon:hasconnection(ship).
	lock mcconn to rtaddon:haskscconnection(ship).
	lock locconn to rtaddon:haslocalcontrol(ship).
}

// monopropellant
global maxfuel is 0.
for res in ship:resources {
  if res:name = "monopropellant" {
	set maxfuel to maxfuel + res:capacity.
  }
}
lock fuelpct to 100*(ship:monopropellant/max(1,maxfuel)).

// electricity
global fullelch is 0.
for res in ship:resources {
  if res:name = "electriccharge" {
	set fullelch to fullelch + res:capacity.
  }
}
lock pctpwr to (ship:electriccharge/fullelch)*100.

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

// wheels friction
global hasfric is false.
if input_data["chwheels"][1] {
	if not ship:partsdubbed("wheel"):empty {
		lock rvrwheels to ship:partsdubbed("wheel").
		if not badpart(rvrwheels,{
			parameter t.
			if t:hasmodule("ModuleWheelBase") {
				return t:getmodule("ModuleWheelBase"):hasaction("friction control").
			}
			else {return false.}
		},"(ModuleWheelBase):hasaction(friction control)") {
			rvrwheels[0]:getmodule("ModuleWheelBase"):doaction("friction control",true).
			global finfric is round(rvrwheels[0]:getmodule("ModuleWheelBase"):getfield("friction control"),1).
			setfrict(finfric).
			set hasfric to true.
		}
	}
	else {
		popmsg(list("No wheels dubbed 'wheel'.","Friction controls will not be available."),rgb(0.6,0.7,1)).
	}
}

////////////////////// GUI STUFF ////////////////////

ctrlmpanel("controls1","Probe Control: "+ship:name,list("controls","switches"),true,true,70,currsets["ctrlm1x"][0],currsets["ctrlm1y"][0]).
ctrlmpanel("controls2","Probe Machinery",list("machinery settings","PID values"),false,true,list(400,600),currsets["ctrlm2x"][0],currsets["ctrlm2y"][0]).
mingui("controls2").

// GUI
{
//// CONTROLS ////
{
local ctrlset010 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global ctrlvelocity is ctrlLRCombo("controls1",ctrlset010,"Velocity:",finvel:tostring(),"m/s",false,false).
set ctrlvelocity["leftbtn"]:onclick to {
	set finvel to chkvalvel(finvel-velstep).
}.

if input_data["finvel"]:length=3{set ctrlvelocity["label"]:tooltip to input_data["finvel"][2].}.
set ctrlvelocity["txtfield"]:onconfirm to {
	parameter str.
	set finvel to chkvalvel(str:tonumber(finvel)).
}.
lock velstep to round(ctrlvelocity["slider"]:value,0).
set ctrlvelocity["rightbtn"]:onclick to {
	set finvel to chkvalvel(finvel+velstep).
}.
local function chkvalvel {
	parameter p.
	local val is round(p,0).
	set ctrlvelocity["txtfield"]:text to val:tostring().
	return val.
}.

local ctrlset020 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global labofst is ctrlset020:addlabel("Sbd offset").
set labofst:tooltip to "Starboard velocity offset. If 'Fwd. by Translation' is enabled, this slider can set additional lateral velocity left or right for the probe. Useful for fine-tuning position when hovering, for example near an observed object.".
set labofst:style:align to "left".
set labofst:style:width to 70.

global ofstslid is ctrlset020:addhslider(0,-10,10).
set ofstslid:onchange to {
	parameter slid.
	set sbdoffst to round(slid,1).
	set ofstlab:text to sbdoffst:tostring().
}.

global ofstlab is ctrlset020:addlabel("").
set ofstlab:style:width to 30.
set ofstlab:style:align to "right".
set ofstlab:text to sbdoffst:tostring().

local ofstunit is ctrlset020:addlabel("m/s").
set ofstunit:style:font to "Consolas".
set ofstunit:style:width to 30.

global ofst0btn is ctrlset020:addbutton("zero").
set ofst0btn:tooltip to "Resets the offset velocity to 0 and centers the offset slider.".
set ofst0btn:style:width to 50.
set ofst0btn:onclick to {
	set ofstslid:value to 0.
}.

local function sbdbuttons {
	parameter p.
	ofst0btn:onclick().
	set ctrlset020:enabled to p.
}

local ctrlset030 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global ctrlaltitude is ctrlLRCombo("controls1",ctrlset030,"Altitude:",mvalt:tostring(),"m",false,true).
set ctrlaltitude["leftbtn"]:onclick to {
	set mvalt to chkvalalt(mvalt-altstep).
}.
if input_data["mvalt"]:length=3 {set ctrlaltitude["label"]:tooltip to input_data["mvalt"][2].}.
set ctrlaltitude["txtfield"]:onconfirm to {
	parameter str.
	set mvalt to chkvalalt(str:tonumber(mvalt)).
	set set_alt to mvalt.

}.
set ctrlaltitude["popup"]:options to mopts.
if input_data["mvtype"]:length=3 {set ctrlaltitude["popup"]:tooltip to input_data["mvtype"][2].}.
set ctrlaltitude["popup"]:index to ctrlaltitude["popup"]:options:indexof(mvtype).
set ctrlaltitude["popup"]:onchange to {
	parameter sel.
	if sel="AGL" {
		set mvalt to rdalt.
	}
	else {
		set mvalt to altitude.
	}
	set mvalt to chkvalalt(mvalt).
	set mvtype to sel.
	set set_alt to mvalt.
}.
lock altstep to round(ctrlaltitude["slider"]:value,0).
set ctrlaltitude["rightbtn"]:onclick to {
	set mvalt to chkvalalt(mvalt+altstep).
}.
local function chkvalalt {
	parameter p.
	local val is round(p,0).
	if val < 1 {set val to 1.}.
	set ctrlaltitude["txtfield"]:text to val:tostring().
	return val.
}.

local ctrlset040 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global ctrlsteer is ctrlLRCombo("controls1",ctrlset040,"Steering:",round(steer,0):tostring(),"dg",true,false,list(10,1,45)).
set ctrlsteer["leftbtn"]:onclick to {
	set strtgtbtn:pressed to false.
	set wpntgobtn:pressed to false.
	set steer to chkvalsteer(steer-steerstep).
	specsteer(steer).
}.
set ctrlsteer["label"]:tooltip to "Probe's heading in degrees from north.".
set ctrlsteer["txtfield"]:onconfirm to {
	parameter str.
	set steer to chkvalsteer(str:tonumber(steer)).
	if strtgtprs or wpntgoprs {
		popmsg(list("Steering Locked"),red).
	}
	else {
		specsteer(steer).
	}
}.
set ctrlsteer["chbox"]:ontoggle to {
	parameter tog.
	steervects(tog,vcmltp).
}.
lock steerstep to round(ctrlsteer["slider"]:value,0).
set ctrlsteer["rightbtn"]:onclick to {
	set strtgtbtn:pressed to false.
	set wpntgobtn:pressed to false.
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
}.

local ctrlset050 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global wpntleftbtn is ctrlset050:addbutton("<<<").
set wpntleftbtn:style:width to 50.
set wpntleftbtn:onclick to {
	set wpnt to wpnt - 1.
	if wpnt < 0 {set wpnt to allwaypoints():length-1.}.
	set labwpnt:text to curwpnt:name.
}.

local wplabelbox is ctrlset050:addhbox().
global labwpnt is wplabelbox:addlabel("").
set labwpnt:tooltip to "Currently selected waypoint that can be used as the probe's target.".
set labwpnt:style:align to "center".

global wpntgoprs is false.
global wpntgobtn is ctrlset050:addbutton("Go Waypoint").
set wpntgobtn:tooltip to "Uses the selected waypoint as the probe's flight target. Turn RCS or Joystick side correction ON to prevent sideways drift.".
set wpntgobtn:style:width to 100.
set wpntgobtn:toggle to true.
set wpntgobtn:ontoggle to {
	parameter tog.
	set wpntgoprs to tog.
	if tog {
		set strtgtbtn:pressed to false.
		specsteer(-3).
		lock disttotgt to sqrt(abs(curwpnt:geoposition:distance^2-rdalt^2)).
		enabtns(false).
	}
	else {
		if not strtgtprs {
			enabtns(true).
		}
	}
}.

global wpntrightbtn is ctrlset050:addbutton(">>>").
set wpntrightbtn:style:width to 50.
set wpntrightbtn:onclick to {
	set wpnt to wpnt + 1.
	if wpnt > allwaypoints():length-1 {set wpnt to 0.}.
	set labwpnt:text to curwpnt:name.
}.

local ctrlset060 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global strfwdbtn is ctrlset060:addbutton("Steer Fwd.").
set strfwdbtn:tooltip to "Sets the steering direction to the probe's current heading.".
set strfwdbtn:onclick to {
	set strtgtbtn:pressed to false.
	set wpntgobtn:pressed to false.
	specsteer(-1).
}.

global strtgtprs is false.
global strtgtbtn is ctrlset060:addbutton("Go Target").
set strtgtbtn:tooltip to "Uses the currently selected KSP target as the probe's flight target. Turn RCS or Joystick side correction ON to prevent sideways drift.".
set strtgtbtn:toggle to true.
set strtgtbtn:ontoggle to {
	parameter tog.
	set strtgtprs to tog.
	if tog {
		set wpntgobtn:pressed to false.
		specsteer(-2).
		lock disttotgt to sqrt(abs(target:geoposition:distance^2-rdalt^2)).
		enabtns(false).
	}
	else {
		if not wpntgoprs {
			enabtns(true).
		}
	}
}.
set strtgtbtn:enabled to hastarget.

global turnsteerprs is false.
global turnsteerbtn is ctrlset060:addbutton("Steer!").
set turnsteerbtn:tooltip to "EXPERIMENTAL: faster adjustment of the probe's steering by excessive turning.".
set turnsteerbtn:toggle to true.
set turnsteerbtn:ontoggle to {
	parameter tog.
	set turnsteerprs to tog.
	if tog {
		lock updyaw to vang(trnvector,vxcl(ship:up:vector, ship:facing:starvector)).
	}
	else {
		set ship:control:yaw to 0.
		if hdsteerprs {
			set hdsteerbtn:pressed to false.
			set hdsteerbtn:pressed to true.
		}
		if hdvelprs {
			set hdvelbtn:pressed to false.
			set hdvelbtn:pressed to true.
		}
	}
}.

local ctrlset070 is ctrlpanlex["controls1"]["controls"]:addhbox().
global hdsteerprs is false.
global hdsteerbtn is ctrlset070:addbutton("Head to Steer").
set hdsteerbtn:tooltip to "Turns and holds the probe's heading to the current steering direction.".
set hdsteerbtn:toggle to true.
set hdsteerbtn:ontoggle to {
	parameter tog.
	set hdsteerprs to tog.
	ywpid:reset().
	if tog {
		set hdvelbtn:pressed to false.
		set turnsteerbtn:pressed to false.
		lock updyaw to vang(steerv,vxcl(ship:up:vector, ship:facing:starvector)).
	}
	else {set ship:control:yaw to 0.}.
}.

global hdvelprs is false.
global hdvelbtn is ctrlset070:addbutton("Head to Velocity").
set hdvelbtn:tooltip to "Turns and holds the probe's head (fore) to the current velocity vector.".
set hdvelbtn:toggle to true.
set hdvelbtn:ontoggle to {
	parameter tog.
	set hdvelprs to tog.
	ywpid:reset().
	if tog {
		set hdsteerbtn:pressed to false.
		set turnsteerbtn:pressed to false.
		lock updyaw to vang(velplane,vxcl(ship:up:vector, ship:facing:starvector)).
	}
	else {set ship:control:yaw to 0.}.
}.

local ctrlset080 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global joyprs is false.
global joybtn is ctrlset080:addbutton("JoyStick Control").
set joybtn:tooltip to "Engages or disengages the probe's control by thrust tilting, using helicopter-style control.".
set joybtn:toggle to true.
set joybtn:ontoggle to {
	parameter tog.
	set joyprs to tog.
	if not tog {
		set thrfwdbtn:pressed to false.
	}
	set thrfwdbtn:enabled to tog.
}.

global rcsbtn is ctrlset080:addbutton("RCS").
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
		set sidybtn:pressed to false.
	}
}.

global sasbtn is ctrlset080:addbutton("SAS").
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

local ctrlset090 is ctrlpanlex["controls1"]["controls"]:addhbox().
global phdr2btn is ctrlset090:addbutton("Reset Alt.").
set phdr2btn:tooltip to "Sets the flying altitude to the current value and the move type to ALT.".
set phdr2btn:onclick to {
	set ctrlaltitude["popup"]:index to ctrlaltitude["popup"]:options:indexof("AGL").
	set ctrlaltitude["popup"]:index to ctrlaltitude["popup"]:options:indexof("ALT").
}.

global trnaltprs is false.
global trnaltbtn is ctrlset090:addbutton("Alt. by Translation").
set trnaltbtn:tooltip to "Gains and maintains altitude using only RCS.".
set trnaltbtn:toggle to true.
set trnaltbtn:ontoggle to {
	parameter tog.
	set trnaltprs to tog.
	vvelpid:reset().
	if tog {
		set thraltbtn:pressed to false.
		if not thrfwdprs and not stopprs {
			set pitchbtn:pressed to true.
			set rollbtn:pressed to true.
		}
		rcs on.
		sas off.
	}
	else {set SHIP:CONTROL:TOP to 0.}.
}.

global thraltprs is false.
global thraltbtn is ctrlset090:addbutton("Alt. by Throttle").
set thraltbtn:tooltip to "Gains and maintains altitude using the main throttle. This also applies when joystick control is enabled.".
set thraltbtn:toggle to true.
set thraltbtn:ontoggle to {
	parameter tog.
	set thraltprs to tog.
	vvelpid:reset().
	if tog {
		statmsg("main throttle engaged").
		set trnaltbtn:pressed to false.
		if not thrfwdprs and not stopprs {
			set pitchbtn:pressed to true.
			set rollbtn:pressed to true.
		}
	}
	else {
		set thrfwdbtn:pressed to false.
		set mthr to 0.
	}
}.

local ctrlset100 is ctrlpanlex["controls1"]["controls"]:addhbox().
global trnfwdprs is false.
global trnfwdbtn is ctrlset100:addbutton("Fwd. by
Translation").
set trnfwdbtn:tooltip to "Moves the probe forward using only RCS.".
set trnfwdbtn:toggle to true.
set trnfwdbtn:ontoggle to {
	parameter tog.
	set trnfwdprs to tog.
	fwdpid:reset().
	sbdbuttons(tog).
	if tog {
		set stopbtn:pressed to false.
		set landbtn:pressed to false.
		set thrfwdbtn:pressed to false.
		set sidybtn:pressed to false.
		set jsidybtn:pressed to false.
		set pitchbtn:pressed to true.
		set rollbtn:pressed to true.
		set hdsteerbtn:pressed to true.
		rcs on.
		sas off.
	}
	else {
		set SHIP:CONTROL:fore to 0.
		set SHIP:CONTROL:starboard to 0.
	}
}.

global thrfwdprs is false.
global thrfwdbtn is ctrlset100:addbutton("Fwd. by
Throttle").
set thrfwdbtn:tooltip to "Moves the probe forward using main throttle.".
set thrfwdbtn:toggle to true.
set thrfwdbtn:ontoggle to {
	parameter tog.
	set thrfwdprs to tog.
	jyangpid:reset().
	if tog {
		set stopbtn:pressed to false.
		set pitchbtn:pressed to false.
		set rollbtn:pressed to false.
		set landbtn:pressed to false.
		set trnfwdbtn:pressed to false.
		set thraltbtn:pressed to true.
		set hdsteerbtn:pressed to true.
		rcs on.
		sas off.
	}
	else {
		set SHIP:CONTROL:pitch to 0.
		set SHIP:CONTROL:roll to 0.
		set sidybtn:pressed to false.
	}
	set sidybtn:enabled to tog.
	set jsidybtn:enabled to tog.
}.

global sidyprs is false.
global sidybtn is ctrlset100:addbutton("RCS
side corr.").
set sidybtn:tooltip to "Adjusts the probe's lateral velocity deviation using RCS.".
set sidybtn:toggle to true.
set sidybtn:style:width to 70.
set sidybtn:ontoggle to {
	parameter tog.
	set sidyprs to tog.
	if tog {
		rcs on.
		sas off.
	}
	else {
		set SHIP:CONTROL:starboard to 0.
		sidpid:reset().
	}
}.
set sidybtn:enabled to false.

global jsidyprs is false.
global jsidybtn is ctrlset100:addbutton("Joystick
side corr.").
set jsidybtn:tooltip to "Adjusts the probe's lateral velocity deviation using joystick controls. WARNING: still EXPERIMENTAL and can be unstable, especially during ascent, descent, or large steering changes.".
set jsidybtn:toggle to true.
set jsidybtn:style:width to 70.
set jsidybtn:ontoggle to {
	parameter tog.
	set jsidyprs to tog.
	if tog {

	lock ssidv to (vxcl(steerv,velplane)*abs(upd_jsidpid(0,sidvel))).

// { // tests
	// minipanel("jsidcor","Side correction",true,200,guilex["controls1"]:x+550,guilex["controls1"]:y,list(true,true)).

	// mpComboTog("jsidcor","steerv-velplane",false,
		// {
			// parameter tog.
			// if tog {
				// set mpCombolex["jsidcor"]["items"]["mvvs"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["velface"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["velplane"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["steerv"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["steerv-velface"]["tbtn"]:pressed to false.

				// lock ssidv to (vxcl(steerv,velplane)*abs(upd_jsidpid(0,sidvel))).

			// }
			// else {
				// lock ssidv to v(0,0,0).
				// sidpid:reset().
			// }
			// return "steerv-velplane".
		// },"ccc.").

	// mpComboTog("jsidcor","steerv-velface",false,
		// {
			// parameter tog.
			// if tog {
				// set mpCombolex["jsidcor"]["items"]["mvvs"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["velface"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["velplane"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["steerv"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["steerv-velplane"]["tbtn"]:pressed to false.

				// lock ssidv to (vxcl(steerv,velface)*abs(upd_jsidpid(0,sidvel))).

			// }
			// else {
				// lock ssidv to v(0,0,0).
				// sidpid:reset().
			// }
			// return "steerv-velface".
		// },"ccc.").

	// mpComboTog("jsidcor","mvvs",false,
		// {
			// parameter tog.
			// if tog {
				// set mpCombolex["jsidcor"]["items"]["velface"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["velplane"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["steerv"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["steerv-velplane"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["steerv-velface"]["tbtn"]:pressed to false.

				// lock ssidv to (mvvs*abs(upd_jsidpid(0,sidvel))).
			// }
			// else {
				// lock ssidv to v(0,0,0).
				// sidpid:reset().
			// }
			// return "mvvs".
		// },"ccc.").
	// mpComboTog("jsidcor","velface",false,
		// {
			// parameter tog.
			// if tog {
				// set mpCombolex["jsidcor"]["items"]["mvvs"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["velplane"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["steerv"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["steerv-velplane"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["steerv-velface"]["tbtn"]:pressed to false.

				// lock ssidv to (vxcl(velface,mvvs)*abs(upd_jsidpid(0,sidvel))).
			// }
			// else {
				// lock ssidv to v(0,0,0).
				// sidpid:reset().
			// }
			// return "velface".
		// },"ccc.").
	// mpComboTog("jsidcor","velplane",false,
		// {
			// parameter tog.
			// if tog {
				// set mpCombolex["jsidcor"]["items"]["mvvs"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["velface"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["steerv"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["steerv-velplane"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["steerv-velface"]["tbtn"]:pressed to false.

				// lock ssidv to (vxcl(velplane,mvvs)*abs(upd_jsidpid(0,sidvel))).
			// }
			// else {
				// lock ssidv to v(0,0,0).
				// sidpid:reset().
			// }
			// return "velplane".
		// },"ccc.").
	// mpComboTog("jsidcor","steerv",false,
		// {
			// parameter tog.
			// if tog {
				// set mpCombolex["jsidcor"]["items"]["mvvs"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["velface"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["velplane"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["steerv-velplane"]["tbtn"]:pressed to false.
				// set mpCombolex["jsidcor"]["items"]["steerv-velface"]["tbtn"]:pressed to false.

				// lock ssidv to (vxcl(steerv,mvvs)*abs(upd_jsidpid(0,sidvel))).
			// }
			// else {
				// lock ssidv to v(0,0,0).
				// sidpid:reset().
			// }
			// return "steerv".
		// },"ccc.").

	// set mpCombolex["jsidcor"]["items"]["steerv-velplane"]["tbtn"]:pressed to true.
// } // tests

	}
	else {
		// killgui("jsidcor").
		lock ssidv to v(0,0,0).
		sidpid:reset().
	}
}.
set jsidybtn:enabled to false.

sbdbuttons(thrfwdprs).

local ctrlset110 is ctrlpanlex["controls1"]["controls"]:addhbox().
global pitchprs is false.
global pitchbtn is ctrlset110:addbutton("Keep Pitch").
set pitchbtn:tooltip to "Keep the probe's pitch centered.".
set pitchbtn:toggle to true.
set pitchbtn:ontoggle to {
	parameter tog.
	set pitchprs to tog.
	ptchpid:reset().
	if tog {
		set thrfwdbtn:pressed to false.
	}
	else
	{set SHIP:CONTROL:pitch to 0.}.
}.

global rollprs is false.
global rollbtn is ctrlset110:addbutton("Keep Roll").
set rollbtn:tooltip to "Keep the probe's roll centered.".
set rollbtn:toggle to true.
set rollbtn:ontoggle to {
	parameter tog.
	set rollprs to tog.
	rllpid:reset().
	if tog {
		set thrfwdbtn:pressed to false.
	}
	else
	{set SHIP:CONTROL:roll to 0.}.
}.

local ctrlset120 is ctrlpanlex["controls1"]["controls"]:addhbox().
global abrptprs is false.
global abrptchb is ctrlset120:addcheckbox("abrupt",false).
if input_data["abrptstop"]:length=3 {set abrptchb:tooltip to input_data["abrptstop"][2].}.
set abrptchb:toggle to true.
set abrptchb:ontoggle to {
	parameter tog.
	set abrptprs to tog.
}.
set abrptchb:pressed to input_data["abrptstop"][1].

global stopprs is false.
global stopbtn is ctrlset120:addbutton("Stop").
set stopbtn:tooltip to "Stops the probe midair and keeps it hovering.".
set stopbtn:toggle to true.
set stopbtn:ontoggle to {
	parameter tog.
	set stopprs to tog.
	jyangpid:reset().
	vvelpid:reset().
	ptchpid:reset().
	rllpid:reset().
	ywpid:reset().
	if tog {
		set turnsteerbtn:pressed to false.
		set sidybtn:pressed to false.
		set jsidybtn:pressed to false.
		set thrfwdbtn:pressed to false.
		set trnfwdbtn:pressed to false.
		set pitchbtn:pressed to false.
		set rollbtn:pressed to false.
		set strfwdbtn:pressed to false.
		set strtgtbtn:pressed to false.
		set wpntgobtn:pressed to false.
		set hdsteerbtn:pressed to true.
		set ofstslid:value to 0.
		if not trnaltprs {set thraltbtn:pressed to true.}.
		rcs on.
		sas off.
		statmsg("stop init.").
	}
	else {
		ctrlreset(true).
	}
}.

global landprs is false.
global landbtn is ctrlset120:addbutton("Land").
set landbtn:tooltip to "Initiate landing sequence.".
set landbtn:toggle to true.
set landbtn:ontoggle to {
	parameter tog.
	set landprs to tog.
	if tog {
		set stopbtn:pressed to true.
		statmsg("landing init.").
	}
	else {
		set set_alt to mvalt.
	}
}.

local ctrlset130 is ctrlpanlex["controls1"]["controls"]:addhbox().
global rstbtn is ctrlset130:addbutton("Reset Controls").
set rstbtn:tooltip to "Resets all control values and releases all buttons.".
set rstbtn:onclick to {
	wait until btnsoff(ctrlpanlex["controls1"]["controls"],"Panic! JoyStick Control >>").
	ctrlreset(true).
}.

global boostprs is false.
global boostbtn is ctrlset130:addbutton("Full Thrust!").
set boostbtn:tooltip to "Sets the throttle to maximum immediately.".
set boostbtn:toggle to true.
set boostbtn:ontoggle to {
	parameter tog.
	set boostprs to tog.
	if tog {
	}
	else {
		ctrlreset(true).
	}
}.

global panicprs is false.
global panicbtn is ctrlset130:addbutton("Panic!").
set panicbtn:tooltip to "Resets all controls, stabilizes the probe, and stops it midair. Useful when spinning uncontrollably.".
set panicbtn:toggle to true.
set panicbtn:ontoggle to {
	parameter tog.
	set panicprs to tog.
	if tog {
		statmsg("panic!").
		wait until btnsoff(ctrlpanlex["controls1"]["controls"],"Panic! JoyStick Control >>").
		ctrlreset(true).
		sas on.
		rcs on.
		wait 1.
	}
	else {
	}
}.

set joybtn:pressed to true.
}
// switches
{
local swtset010 is ctrlpanlex["controls1"]["switches"]:addhbox().
global actlsrprs is false.
global actlsrchb is swtset010:addcheckbox("Laser Active",false).
set actlsrchb:tooltip to "EXPERIMENTAL: Activates or deactivates laser terrain detection.".
set actlsrchb:toggle to true.
set actlsrchb:ontoggle to {
	parameter tog.
	set actlsrprs to tog.
}.

global vislsrchb is swtset010:addcheckbox("Laser Visible",false).
set vislsrchb:tooltip to "Toggles laser visibility. If FALSE, the laser is visible only when the evading process is active.".
set vislsrchb:toggle to true.
set vislsrchb:ontoggle to {
	parameter tog.
	lsvisible(tog).
}.

global rstlsrbtn is swtset010:addbutton("Reset Laser").
set rstlsrbtn:tooltip to "EXPERIMENTAL: Resets laser evade count to 0.".
set rstlsrbtn:onclick to {
	set lsrcnt to 0.
	lsvisible(vislsrchb:pressed).
}.

local swtset020 is ctrlpanlex["controls1"]["switches"]:addhlayout().
local lsrlab is swtset020:addlabel("Set Active Laser").
set lsrlab:tooltip to "EXPERIMENTAL: Selects the laser device that will provide terrain detection functionality. Only one device can be active.".
local lvrsets11 is swtset020:addhbox().
global function rbtnlasr {
	if lvrsets11:radiovalue {
		lasrsel(lvrsets11:radiovalue).
		lsvisible(vislsrchb:pressed).
	}
}.

global lsrlrdbtn is lvrsets11:addradiobutton("left",false).
set lsrlrdbtn:tooltip to "EXPERIMENTAL: Selects the left laser (dubbed 'lsrl') for the detection function.".
set lsrlrdbtn:onclick to rbtnlasr@.
global lsrmrdbtn is lvrsets11:addradiobutton("middle",false).
set lsrmrdbtn:tooltip to "EXPERIMENTAL: Selects the middle laser (dubbed 'lsrm') for the detection function.".
set lsrmrdbtn:onclick to rbtnlasr@.
global lsrrrdbtn is lvrsets11:addradiobutton("right",false).
set lsrrrdbtn:tooltip to "EXPERIMENTAL: Selects the right laser (dubbed 'lsrr') for the detection function.".
set lsrrrdbtn:onclick to rbtnlasr@.

local swtset030 is ctrlpanlex["controls1"]["switches"]:addhbox().
global lndattgtprs is false.
global lndattgtbtn is swtset030:addcheckbox("Land at
Target",false).
if input_data["tgtlnd"]:length=3 {set lndattgtbtn:tooltip to input_data["tgtlnd"][2].}.
set lndattgtbtn:toggle to true.
set lndattgtbtn:ontoggle to {
	parameter tog.
	set lndattgtprs to tog.
	if not tog {
		if approach {
			set approach to false.
			statmsg("approach intrpt.").
		}
		ctrlreset(true).
	}
}.
set lndattgtbtn:pressed to input_data["tgtlnd"][1].

global appfwdprs is false.
global appfwdchb is swtset030:addcheckbox("Fwd corr.
on approach",false).
if input_data["appfwd"]:length=3 {set appfwdchb:tooltip to input_data["appfwd"][2].}.
set appfwdchb:toggle to true.
set appfwdchb:ontoggle to {
	parameter tog.
	set appfwdprs to tog.
}.
set appfwdchb:pressed to input_data["appfwd"][1].

global forcsteerprs is false.
global forcsteerchb is swtset030:addcheckbox("Force Steer!",false).
set forcsteerchb:tooltip to "EXPERIMENTAL: If TRUE, the 'Force Steer' function is automatically activated when the angle between the probe's steering and velocity vectors exceeds the steering tolerance multiplied by the force steer coefficient.".
set forcsteerchb:toggle to true.
set forcsteerchb:ontoggle to {
	parameter tog.
	set forcsteerprs to tog.
}.
set forcsteerchb:pressed to input_data["fsteerchb"][1].

global unstgtbtn is swtset030:addbutton("Unset Target").
set unstgtbtn:tooltip to "If the probe has a target set, this will unset it and cancel 'Go Target' if active.".
set unstgtbtn:onclick to {
	if hastarget {
		set strtgtbtn:pressed to false.
		specsteer(steer).
		set target to "".
		wait until not hastarget.
		statmsg("target unset").
	}
	else {
		statmsg("no target set").
	}
}.

local swtset040 is ctrlpanlex["controls1"]["switches"]:addhlayout().
global ctrlfindist is ctrlLRCombo("controls1",swtset040,"Distance:",findist:tostring(),"m",false,false).
set ctrlfindist["leftbtn"]:onclick to {
	set findist to chkvaldist(findist-findiststep).
}.
if input_data["findist"]:length=3 {set ctrlfindist["label"]:tooltip to input_data["findist"][2].}.
set ctrlfindist["txtfield"]:onconfirm to {
	parameter str.
	set findist to chkvaldist(str:tonumber(findist)).
}.
lock findiststep to round(ctrlfindist["slider"]:value,0)*100.
set ctrlfindist["steplab"]:style:width to 40.
set ctrlfindist["steplab"]:style:align to "center".
set ctrlfindist["slider"]:onchange to {
	parameter slid.
	set ctrlfindist["steplab"]:text to findiststep:tostring().
}.
set ctrlfindist["steplab"]:text to findiststep:tostring().
set ctrlfindist["rightbtn"]:onclick to {
	set findist to chkvaldist(findist+findiststep).
}.
local function chkvaldist {
	parameter p.
	local val is round(p,0).
	if val<0 {set val to 0.}.
	set ctrlfindist["txtfield"]:text to val:tostring().
	set startpos to ship:geoposition.
	set begtime to time:seconds.
	return val.
}.

local swtset050 is ctrlpanlex["controls1"]["switches"]:addhlayout().
global ctrlfintime is ctrlLRCombo("controls1",swtset050,"Time:",fintime:tostring(),"s",false,false).
set ctrlfintime["leftbtn"]:onclick to {
	set fintime to chkvaltime(fintime-fintimestep).
}.
if input_data["fintime"]:length=3 {set ctrlfintime["label"]:tooltip to input_data["fintime"][2].}.
set ctrlfintime["txtfield"]:onconfirm to {
	parameter str.
	set fintime to chkvaltime(str:tonumber(fintime)).

}.
lock fintimestep to round(ctrlfintime["slider"]:value,0).
set ctrlfintime["steplab"]:style:width to 40.
set ctrlfintime["steplab"]:style:align to "center".
set ctrlfintime["rightbtn"]:onclick to {
	set fintime to chkvaltime(fintime+fintimestep).
}.
local function chkvaltime {
	parameter p.
	local val is round(p,0).
	if val<0 {set val to 0.}.
	set ctrlfintime["txtfield"]:text to val:tostring().
	set startpos to ship:geoposition.
	set begtime to time:seconds.
	return val.
}.

local swtset060 is ctrlpanlex["controls1"]["switches"]:addhlayout().
global rstdistbtn is swtset060:addbutton("Reset Position").
set rstdistbtn:tooltip to "Resets the probe's position for flight distance or time measurement.".
set rstdistbtn:onclick to {
	set strtgtbtn:pressed to false.
	set wpntgobtn:pressed to false.
	set startpos to ship:geoposition.
	set begtime to time:seconds.
	specsteer(steer).
}.

local swtset070 is ctrlpanlex["controls1"]["switches"]:addhbox().
global lckgimchb is swtset070:addcheckbox("Lock Gimbal",false).
set lckgimchb:tooltip to "Locks or unlocks the gimbals of engines with the kOS name tag 'lengs'.".
set lckgimchb:toggle to true.
set lckgimchb:ontoggle to {
	parameter tog.
	lock_gimbal(tog).
}.
set lckgimchb:enabled to haslengs.
if haslengs {set lckgimchb:pressed to input_data["gimblck"][1].}.

global emergthrprs is false.
global emergthrchb is swtset070:addcheckbox("Emrg. Thr.",false).
if input_data["emergthr"]:length=3 {set emergthrchb:tooltip to input_data["emergthr"][2].}.
set emergthrchb:toggle to true.
set emergthrchb:ontoggle to {
	parameter tog.
	set emergthrprs to tog.
}.
set emergthrchb:pressed to input_data["emergthr"][1].

global solpanprs is false.
global solpanbtn is swtset070:addbutton("Ext./Retr. Solar Panels").
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

local swtset080 is ctrlpanlex["controls1"]["switches"]:addhbox().
global termlogchb is swtset080:addcheckbox("Terminal Logs",false).
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
global menucpu is swtset080:addpopupmenu().
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

if hasfric {
local swtset090 is ctrlpanlex["controls1"]["switches"]:addhbox().
global fricdownbtn is swtset090:addbutton("<<<").
set fricdownbtn:style:width to 50.
set fricdownbtn:onclick to {
	set finfric to finfric - fricstep.
	if finfric < 0 {set finfric to 0.}.
	set dlgfric:text to finfric:tostring().
	setfrict(finfric).
}.

global labfric is swtset090:addlabel("Friction:").
set labfric:tooltip to "Controls the friction settings of the probe's wheels with the kOS name tag 'wheel'.".
set labfric:style:align to "left".
set labfric:style:width to 65.

global dlgfric is swtset090:addbutton(finfric:tostring()).
set dlgfric:style:align to "right".
set dlgfric:style:width to 60.
set dlgfric:onclick to {
	set dlgfricx:text to finfric:tostring().
	dlgfric:hide.
	dlgfricx:show.
	screeninit().
}.

global dlgfricx is swtset090:addtextfield(finfric:tostring()).
set dlgfricx:style:align to "right".
set dlgfricx:style:width to 60.
set dlgfricx:onconfirm to {
	parameter str.
	set dlgfric:text to str.
	set finfric to str:tonumber(finfric).
	dlgfricx:hide.
	dlgfric:show.
	setfrict(finfric).
	screeninit().
}.
dlgfricx:hide.

global fricslid is swtset090:addhslider(1,0.1,1).
set fricslid:onchange to {
	parameter slid.
	set fricsteplab:text to fricstep:tostring().
}.

global fricsteplab is swtset090:addlabel("").
set fricsteplab:style:width to 20.
set fricsteplab:style:align to "center".
lock fricstep to round(fricslid:value,1).
set fricsteplab:text to fricstep:tostring().

global fricupbtn is swtset090:addbutton(">>>").
set fricupbtn:style:width to 50.
set fricupbtn:onclick to {
	set finfric to finfric + fricstep.
	if finfric > 10 {set finfric to 10.}.
	set dlgfric:text to finfric:tostring().
	setfrict(finfric).
}.
}
}
// machinery settings
{
local machtitle is ctrlpanlex["controls2"]["machinery settings"]:addlabel(ship:name).
set machtitle:style:align to "center".
set machtitle:style:hstretch to true.

local mchset010 is ctrlpanlex["controls2"]["machinery settings"]:addvbox().
global dlgjanglim is
mchnrline("controls2",mchset010,"janglim",{
	parameter str.
	set janglim to str:tonumber(janglim).
}).
global dlgveltrsh is
mchnrline("controls2",mchset010,"veltrsh",{
	parameter str.
	set veltrsh to str:tonumber(veltrsh).
}).

local mchset020 is ctrlpanlex["controls2"]["machinery settings"]:addvbox().
global dlgtsteer is
mchnrline("controls2",mchset020,"tsteer",{
   parameter str.
   set tsteer to str:tonumber(tsteer).
}).
global dlgfsteer is
mchnrline("controls2",mchset020,"fsteer",{
   parameter str.
   set fsteer to str:tonumber(fsteer).
}).

local mchset030 is ctrlpanlex["controls2"]["machinery settings"]:addvbox().
global dlgsfhght is
mchnrline("controls2",mchset030,"safehght",{
   parameter str.
   set safehght to str:tonumber(safehght).
}).

global dlgrdland is
mchnrline("controls2",mchset030,"rdland",{
   parameter str.
   set rdland to str:tonumber(rdland).
}).

global dlglndvel is
mchnrline("controls2",mchset030,"mxlandv",{
   parameter str.
   set mxlandv to str:tonumber(mxlandv).
}).
global dlgminvertvel is
mchnrline("controls2",mchset030,"minvertvel",{
   parameter str.
   set minvertvel to str:tonumber(minvertvel).
}).
global dlgmaxvertvel is
mchnrline("controls2",mchset030,"maxvertvel",{
   parameter str.
   set maxvertvel to str:tonumber(maxvertvel).
}).
global dlglndvelcoef is
mchnrline("controls2",mchset030,"lndvelcoef",{
   parameter str.
   set lndvelcoef to str:tonumber(lndvelcoef).
}).
global dlgnormvvelcoef is
mchnrline("controls2",mchset030,"normvvelcoef",{
   parameter str.
   set normvvelcoef to str:tonumber(normvvelcoef).
}).

local mchset040 is ctrlpanlex["controls2"]["machinery settings"]:addvbox().
global dlgtgtdist is
mchnrline("controls2",mchset040,"appdist",{
   parameter str.
   set appdist to str:tonumber(appdist).
	set appdist to max(appdist,lnddist).
	set mchnrlex["controls2"]["appdist"]["txtfield"]:text to appdist:tostring().
}).
global dlglnddist is
mchnrline("controls2",mchset040,"lnddist",{
   parameter str.
   set lnddist to str:tonumber(lnddist).
}).
global dlgminappvel is
mchnrline("controls2",mchset040,"minappvel",{
   parameter str.
   set minappvel to str:tonumber(minappvel).
}).
global dlgminappalt is
mchnrline("controls2",mchset040,"minappalt",{
   parameter str.
   set minappalt to str:tonumber(minappalt).
}).

local mchset050 is ctrlpanlex["controls2"]["machinery settings"]:addvbox().
global dlgdetcoef is
mchnrline("controls2",mchset050,"detcoef",{
   parameter str.
   set detcoef to str:tonumber(detcoef).
}).
global dlgevdlim is
mchnrline("controls2",mchset050,"evdlim",{
   parameter str.
   set evdlim to str:tonumber(evdlim).
}).
global dlglsrslope is
mchnrline("controls2",mchset050,"lsrslope",{
   parameter str.
   set lsrslope to str:tonumber(lsrslope).
}).
global dlglsrralt is
mchnrline("controls2",mchset050,"lsrralt",{
   parameter str.
   set lsrralt to str:tonumber(lsrralt).
}).
global dlglsrvcut is
mchnrline("controls2",mchset050,"lsrvcut",{
   parameter str.
   set lsrvcut to str:tonumber(lsrvcut).
}).

local mchset060 is ctrlpanlex["controls2"]["machinery settings"]:addvbox().
global dlgemergcoef is
mchnrline("controls2",mchset060,"emergcoef",{
   parameter str.
   set emergcoef to str:tonumber(emergcoef).
}).
global dlglimfuel is
mchnrline("controls2",mchset060,"minfuel",{
   parameter str.
   set minfuel to str:tonumber(minfuel).
}).
global dlgpwrlim is
mchnrline("controls2",mchset060,"pwrlim",{
   parameter str.
   set pwrlim to str:tonumber(pwrlim).
}).

local mchset070 is ctrlpanlex["controls2"]["machinery settings"]:addvbox().
global dlgvcmltp is
mchnrline("controls2",mchset070,"vcmltp",{
   parameter str.
   set vcmltp to str:tonumber(vcmltp).
}).
}
}

if haslaser {
	on haslaser {
		lsrbuttons(haslaser).
		return true.
	}

	global lasrlist is lexicon(
	"left",list("lsrl",lsrlrdbtn),
	"middle",list("lsrm",lsrmrdbtn),
	"right",list("lsrr",lsrrrdbtn),
	"meta",list("left","middle","right")
	).
	lexcleanup:add(lasrlist).

	local function lsrok {
		for lsrp in lasrlist:keys {
			if badpart(ship:partsdubbed(lasrlist[lsrp][0]),{
			parameter t.
			if t:hasmodule("LaserDistModule") {
				return t:getmodule("LaserDistModule"):hasfield("distance").
			}},"(LaserDistModule):hasfield(distance)") {return false.}.
		}
		return true.
	}

	if lsrok() {
		global bname is body:name.
		global lsrcnt is 0.
		lock lsrby to 90-vang(ship:up:vector,ship:facing:forevector).
		global lasr is 0.

		global function lasrsel {
			parameter l.
			for lsr in lasrlist:keys {
				if lsr<>"meta" {
					if ship:partsdubbed(lasrlist[lsr][0]):empty {
						set lasrlist[lsr][1]:pressed to false.
						set lasrlist[lsr][1]:enabled to false.
						lasrlist:remove(lsr).
						lasrlist["meta"]:remove(lasrlist["meta"]:indexof(lsr)).
					}
					else {
						set lasr to ship:partsdubbed(lasrlist[lsr][0])[0]:getmodule("LaserDistModule").
						lasr:setfield("Enabled",false).
						lasr:doevent("zero bend").
						lock lasrdist to lasr:getfield("distance").
						lock lasrhit to lasr:getfield("hit").
						lock lasrcond to (lasrhit:contains(bname) and lasrdist>-1 and lasrdist <= srfvel*detcoef).

						lsvisible(false).
					}
				}
			}
			if lasrlist:length=1 {
				set haslaser to false.
			}
			else {
				if lasrlist:haskey(l) {
					set lasr to ship:partsdubbed(lasrlist[l][0])[0]:getmodule("LaserDistModule").
					lasr:setfield("Enabled",true).
				}
				else {
					set lasrlist[lasrlist["meta"][0]][1]:pressed to true.
				}
			}
		}
		global function lsvisible {
			parameter vis.
			if lasr:hassuffix("setfield") {lasr:setfield("visible",vis).}.
		}
		set vislsrchb:pressed to input_data["lsrvisible"][1].
		set actlsrchb:pressed to input_data["lsractive"][1].
		global prvlsrdist is 0.
		set lasrlist[sellaser][1]:pressed to true.
	}
	else {set haslaser to false.}.
}

lsrbuttons(haslaser).
specsteer(steer).
solpanels(false).
updwpoints().

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

// throttle for forward
global tfpid is pidloop(tfkp, tfki, tfkd, -1, 1, tfeps).
global function upd_tfpid {
	parameter spoint.
	parameter feedback.
	set tfpid:setpoint to spoint.
	return tfpid:update(time:seconds, feedback).
}

//vertical velocity, hovering, landing...
global vvelpid is pidloop(vvelkp, vvelki, vvelkd, -0.5, 1, vveleps).
global function upd_vvelpid {
	parameter spoint.
	parameter feedback.
	set vvelpid:setpoint to spoint.
	return vvelpid:update(time:seconds, feedback).
}

// forward-backward translation
global fwdpid is pidloop(fwdkp, fwdki, fwdkd, -1, 1, fwdeps).
global function upd_fwdpid {
	parameter spoint.
	parameter feedback.
	set fwdpid:setpoint to spoint.
	return fwdpid:update(time:seconds, feedback).
 }

// lateral translation
global sidpid is pidloop(sidkp, sidki, sidkd, -1, 1, sideps).
global function upd_sidpid {
	parameter spoint.
	parameter feedback.
	set sidpid:setpoint to spoint.
	return sidpid:update(time:seconds, feedback).
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

// joystick vector angle, velocity part
global jyangpid is pidloop(jyangkp, jyangki, jyangkd, -1, 1, jyangeps).
global function upd_jyangpid {
	parameter spoint.
	parameter feedback.
	set jyangpid:setpoint to spoint.
	return jyangpid:update(time:seconds, feedback).
}

// lateral joystick
global jsidpid is pidloop(jsidkp, jsidki, jsidkd, -1, 1, jsideps).
global function upd_jsidpid {
	parameter spoint.
	parameter feedback.
	set jsidpid:setpoint to spoint.
	return jsidpid:update(time:seconds, feedback).
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

local tfpidset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global tfkpdlg is valbox("controls2",tfpidset,"tfkp","tf kp:",tfpid:kp,{
	parameter str.
	set tfpid:kp to str:tonumber(tfpid:kp).
},
"throttle for forward").
global tfkidlg is valbox("controls2",tfpidset,"tfki","tf ki:",tfpid:ki,{
	parameter str.
	set tfpid:ki to str:tonumber(tfpid:ki).
}).
global tfkddlg is valbox("controls2",tfpidset,"tfkd","tf kd:",tfpid:kd,{
	parameter str.
	set tfpid:kd to str:tonumber(tfpid:kd).
}).
global tfepsdlg is valbox("controls2",tfpidset,"tfeps","tf eps:",tfpid:epsilon,{
	parameter str.
	set tfpid:epsilon to str:tonumber(tfpid:epsilon).
}).

local vvelpidset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global vvelkpdlg is valbox("controls2",vvelpidset,"vvelkp","vvel kp:",vvelpid:kp,{
   parameter str.
   set vvelpid:kp to str:tonumber(vvelpid:kp).
},
"vertical velocity, hovering, landing").
global vvelkidlg is valbox("controls2",vvelpidset,"vvelki","vvel ki:",vvelpid:ki,{
   parameter str.
   set vvelpid:ki to str:tonumber(vvelpid:ki).
}).
global vvelkddlg is valbox("controls2",vvelpidset,"vvelkd","vvel kd:",vvelpid:kd,{
   parameter str.
   set vvelpid:kd to str:tonumber(vvelpid:kd).
}).
global vvelepsdlg is valbox("controls2",vvelpidset,"vveleps","vvel eps:",vvelpid:epsilon,{
	parameter str.
	set vvelpid:epsilon to str:tonumber(vvelpid:epsilon).
}).

local fwdpidset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global fwdkpdlg is valbox("controls2",fwdpidset,"fwdkp","fwd kp:",fwdpid:kp,{
   parameter str.
   set fwdpid:kp to str:tonumber(fwdpid:kp).
},
"forward-backward translation").
global fwdkidlg is valbox("controls2",fwdpidset,"fwdki","fwd ki:",fwdpid:ki,{
   parameter str.
   set fwdpid:ki to str:tonumber(fwdpid:ki).
}).
global fwdkddlg is valbox("controls2",fwdpidset,"fwdkd","fwd kd:",fwdpid:kd,{
   parameter str.
   set fwdpid:kd to str:tonumber(fwdpid:kd).
}).
global fwdepsdlg is valbox("controls2",fwdpidset,"fwdeps","fwd eps:",fwdpid:epsilon,{
	parameter str.
	set fwdpid:epsilon to str:tonumber(fwdpid:epsilon).
}).

local sidpidset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global sidkpdlg is valbox("controls2",sidpidset,"sidkp","sid kp:",sidpid:kp,{
   parameter str.
   set sidpid:kp to str:tonumber(sidpid:kp).
},
"lateral translation").
global sidkidlg is valbox("controls2",sidpidset,"sidki","sid ki:",sidpid:ki,{
   parameter str.
   set sidpid:ki to str:tonumber(sidpid:ki).
}).
global sidkddlg is valbox("controls2",sidpidset,"sidkd","sid kd:",sidpid:kd,{
   parameter str.
   set sidpid:kd to str:tonumber(sidpid:kd).
}).
global sidepsdlg is valbox("controls2",sidpidset,"sideps","sid eps:",sidpid:epsilon,{
	parameter str.
	set sidpid:epsilon to str:tonumber(sidpid:epsilon).
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

local jyangpidset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global jyangkpdlg is valbox("controls2",jyangpidset,"jyangkp","jyang kp:",jyangpid:kp,{
   parameter str.
   set jyangpid:kp to str:tonumber(jyangpid:kp).
},
"joystick vector angle").
global jyangkidlg is valbox("controls2",jyangpidset,"jyangki","jyang ki:",jyangpid:ki,{
   parameter str.
   set jyangpid:ki to str:tonumber(jyangpid:ki).
}).
global jyangkddlg is valbox("controls2",jyangpidset,"jyangkd","jyang kd:",jyangpid:kd,{
   parameter str.
   set jyangpid:kd to str:tonumber(jyangpid:kd).
}).
global jyangepsdlg is valbox("controls2",jyangpidset,"jyangeps","jyang eps:",jyangpid:epsilon,{
	parameter str.
	set jyangpid:epsilon to str:tonumber(jyangpid:epsilon).
}).

local jsidpidset is ctrlpanlex["controls2"]["PID values"]:addhbox().
global jsidkpdlg is valbox("controls2",jsidpidset,"jsidkp","jsid kp:",jsidpid:kp,{
   parameter str.
   set jsidpid:kp to str:tonumber(jsidpid:kp).
},
"joystick lateral").
global jsidkidlg is valbox("controls2",jsidpidset,"jsidki","jsid ki:",jsidpid:ki,{
   parameter str.
   set jsidpid:ki to str:tonumber(jsidpid:ki).
}).
global jsidkddlg is valbox("controls2",jsidpidset,"jsidkd","jsid kd:",jsidpid:kd,{
   parameter str.
   set jsidpid:kd to str:tonumber(jsidpid:kd).
}).
global jsidepsdlg is valbox("controls2",jsidpidset,"jsideps","jsid eps:",jsidpid:epsilon,{
	parameter str.
	set jsidpid:epsilon to str:tonumber(jsidpid:epsilon).
}).
}

// FUNCTIONS

function lsrbuttons {
	parameter p.
	if not p {
		set actlsrchb:pressed to p.
		set vislsrchb:pressed to p.
		set rstlsrbtn:pressed to p.
	}
	set actlsrchb:enabled to p.
	set vislsrchb:enabled to p.
	set rstlsrbtn:enabled to p.
	set lsrlrdbtn:enabled to p.
	set lsrmrdbtn:enabled to p.
	set lsrrrdbtn:enabled to p.
}

function vsteer {
	local snorth is ship:north:vector.
	if vang(velplane,vcrs(ship:up:vector, snorth))>=90 {
		return 360-vang(velplane,snorth).
	}
	else {
		return vang(velplane,snorth).
	}
}

function trnsteer {
	local snorth is ship:north:vector.
	if vang(trnvector,vcrs(ship:up:vector, snorth))>=90 {
		return 360-vang(trnvector,snorth).
	}
	else {
		return vang(trnvector,snorth).
	}
}

function specsteer {
	parameter s.
	if ship=kuniverse:activevessel {SET NAVMODE TO "surface".}. //for active ship
	if s>-2 {
		if findist>0 {
			lock disttotgt to findist-drdist.
		}
		else {
			lock disttotgt to fintime-drtime.
		}
	}
	if s = -1 {
		set steer to btoc(ship:bearing).
	}
	else if s = -2 {
		if hastarget {
			if ship=kuniverse:activevessel {SET NAVMODE TO "target".}.
			set steer to target:heading.
		}
		else {
			set steer to btoc(ship:bearing).
		}
	}
	else if s = -3 {
		if allwaypoints():length>0 {
			set steer to curwpnt:geoposition:heading.
		}
	}
	else if s = -4 {
		set steer to btoc(ship:geoposition:bearing).
	}
	else {
		set steer to s.
	}
	set steer to round(steer,0).
	set ctrlsteer["txtfield"]:text to steer:tostring().
}


function vvelset {
	local retval is 0.
	if set_alt = -1 {
		set retval to min(mxlandv,((-rdalt)/lndvelcoef)).
	}
	else {
		set retval to ((set_alt-rdalt)/normvvelcoef).
	}
	set retval to min(maxvertvel,max(retval,minvertvel)).
	if trnaltprs {set retval to retval/3.}.
	return retval.
}


function get_alt {
	if set_alt>-1 {
		if mvtype="AGL" {
			set set_alt to mvalt.
		}
		else {
			set set_alt to max(rdalt+(mvalt-altitude),safehght).
		}
		if approach {
			set set_alt to  min(mvalt,max(set_alt*(disttotgt/appdist),minappalt)).
		}
	}
}

function get_vel {
	if approach {
		set set_vel to min(finvel,max(finvel*(disttotgt/appdist),minappvel)).
	}
	else {
		set set_vel to finvel.
	}
	set set_vel to set_vel*velcut.
}

function joyangle {
	parameter velset.
	parameter velfeed.
	local jangprm is upd_jyangpid(velset,velfeed)*janglim.
	return (90-jangprm)+(jangprm*altparm).
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

		global shjoyvector is vecdraw(
			V(0,0,0),
			joyvector*mltp,
			RGB(0,0,1),
			"joyvect",
			1.0,
			true,
			0.2
		).
		set shjoyvector:vecupdater to {return joyvector*mltp.}.

		global shssidvector is vecdraw(
			V(0,0,0),
			ssidv*mltp,
			RGB(1,1,0),
			"ssidv",
			1.0,
			true,
			0.2
		).
		set shssidvector:vecupdater to {return ssidv*mltp.}.

		// global shvelface is vecdraw(
			// V(0,0,0),
			// velface*mltp,
			// RGB(0,1,0),
			// "velface",
			// 1.0,
			// true,
			// 0.2
		// ).
		// set shvelface:vecupdater to {return velface*mltp.}.

		// global shhdg is vecdraw(
			// V(0,0,0),
			// heading(trnsteer(),joyangle(set_vel,fwdvel)):vector*mltp,
			// RGB(1,1,0),
			// "HEADING",
			// 1.0,
			// true,
			// 0.2
		// ).
		// set shhdg:vecupdater to {return heading(trnsteer(),joyangle(set_vel,fwdvel)):vector*mltp.}.

	}
	else {
		set lstrv:vecupdater to DONOTHING.
		set lmvvector:vecupdater to DONOTHING.
		set lvelplanev:vecupdater to DONOTHING.
		set shjoyvector:vecupdater to DONOTHING.
		set shssidvector:vecupdater to DONOTHING.
// set shvelface:vecupdater to DONOTHING.
// set shhdg:vecupdater to DONOTHING.

		set lstrv to 0.
		set lmvvector to 0.
		set lvelplanev to 0.
		set shjoyvector to 0.
		set shssidvector to 0.
// set shvelface to 0.
// set shhdg to 0.

	}
}

function enabtns {
	parameter d.
	ctrlLRCombo("controls1",d,"Distance:").
	ctrlLRCombo("controls1",d,"Time:").
	if d {specsteer(-1).}.
}

function savvalsload {
	set tfpid:kp to savvals["tfkp"].
	set tfkpdlg["txtfield"]:text to tfpid:kp:tostring().
	set tfpid:ki to savvals["tfki"].
	set tfkidlg["txtfield"]:text to tfpid:ki:tostring().
	set tfpid:kd to savvals["tfkd"].
	set tfkddlg["txtfield"]:text to tfpid:kd:tostring().
	set tfpid:epsilon to savvals["tfeps"].
	set tfepsdlg["txtfield"]:text to tfpid:epsilon:tostring().

	set vvelpid:kp to savvals["vvelkp"].
	set vvelkpdlg["txtfield"]:text to vvelpid:kp:tostring().
	set vvelpid:ki to savvals["vvelki"].
	set vvelkidlg["txtfield"]:text to vvelpid:ki:tostring().
	set vvelpid:kd to savvals["vvelkd"].
	set vvelkddlg["txtfield"]:text to vvelpid:kd:tostring().
	set vvelpid:epsilon to savvals["vveleps"].
	set vvelepsdlg["txtfield"]:text to vvelpid:epsilon:tostring().

	set fwdpid:kp to savvals["fwdkp"].
	set fwdkpdlg["txtfield"]:text to fwdpid:kp:tostring().
	set fwdpid:ki to savvals["fwdki"].
	set fwdkidlg["txtfield"]:text to fwdpid:ki:tostring().
	set fwdpid:kd to savvals["fwdkd"].
	set fwdkddlg["txtfield"]:text to fwdpid:kd:tostring().
	set fwdpid:epsilon to savvals["fwdeps"].
	set fwdepsdlg["txtfield"]:text to fwdpid:epsilon:tostring().

	set sidpid:kp to savvals["sidkp"].
	set sidkpdlg["txtfield"]:text to sidpid:kp:tostring().
	set sidpid:ki to savvals["sidki"].
	set sidkidlg["txtfield"]:text to sidpid:ki:tostring().
	set sidpid:kd to savvals["sidkd"].
	set sidkddlg["txtfield"]:text to sidpid:kd:tostring().
	set sidpid:epsilon to savvals["sideps"].
	set sidepsdlg["txtfield"]:text to sidpid:epsilon:tostring().

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

	set jyangpid:kp to savvals["jyangkp"].
	set jyangkpdlg["txtfield"]:text to jyangpid:kp:tostring().
	set jyangpid:ki to savvals["jyangki"].
	set jyangkidlg["txtfield"]:text to jyangpid:ki:tostring().
	set jyangpid:kd to savvals["jyangkd"].
	set jyangkddlg["txtfield"]:text to jyangpid:kd:tostring().
	set jyangpid:epsilon to savvals["jyangeps"].
	set jyangepsdlg["txtfield"]:text to jyangpid:epsilon:tostring().

	set jsidpid:kp to savvals["jsidkp"].
	set jsidkpdlg["txtfield"]:text to jsidpid:kp:tostring().
	set jsidpid:ki to savvals["jsidki"].
	set jsidkidlg["txtfield"]:text to jsidpid:ki:tostring().
	set jsidpid:kd to savvals["jsidkd"].
	set jsidkddlg["txtfield"]:text to jsidpid:kd:tostring().
	set jsidpid:epsilon to savvals["jsideps"].
	set jsidepsdlg["txtfield"]:text to jsidpid:epsilon:tostring().
}

function savvalssave {
	set savvals["tfkp"] to tfpid:kp.
	set savvals["tfki"] to tfpid:ki.
	set savvals["tfkd"] to tfpid:kd.
	set savvals["tfeps"] to tfpid:epsilon.

	set savvals["vvelkp"] to vvelpid:kp.
	set savvals["vvelki"] to vvelpid:ki.
	set savvals["vvelkd"] to vvelpid:kd.
	set savvals["vveleps"] to vvelpid:epsilon.

	set savvals["fwdkp"] to fwdpid:kp.
	set savvals["fwdki"] to fwdpid:ki.
	set savvals["fwdkd"] to fwdpid:kd.
	set savvals["fwdeps"] to fwdpid:epsilon.

	set savvals["sidkp"] to sidpid:kp.
	set savvals["sidki"] to sidpid:ki.
	set savvals["sidkd"] to sidpid:kd.
	set savvals["sideps"] to sidpid:epsilon.

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

	set savvals["jyangkp"] to jyangpid:kp.
	set savvals["jyangki"] to jyangpid:ki.
	set savvals["jyangkd"] to jyangpid:kd.
	set savvals["jyangeps"] to jyangpid:epsilon.

	set savvals["jsidkp"] to jsidpid:kp.
	set savvals["jsidki"] to jsidpid:ki.
	set savvals["jsidkd"] to jsidpid:kd.
	set savvals["jsideps"] to jsidpid:epsilon.
}

// TRIGGERS
on hastarget {
	set strtgtbtn:enabled to hastarget.
	return true.
}

chkpreset(input_data["ldpres"][1],input_data["preset"][1]).
ctrlreset(false).

global looptime is 0.
statmsg("probe ready").

global tclmn1 is currsets["tclmn1"][0].
global tclmn2 is currsets["tclmn2"][0].
global tclmn3 is currsets["tclmn3"][0].

until scriptend {
	set looptime to time:seconds.

	if ship:control:pilotmainthrottle>0 {set ship:control:pilotmainthrottle to 0.}. // block accidental throttle input

	get_alt().
	get_vel().

	if strtgtprs and abs(steer-target:heading) > tsteer {
		statmsg("tgt. heading corr.").
		specsteer(-2).
	}

	if wpntgoprs and abs(steer-curwpnt:geoposition:heading) > tsteer {
		statmsg("wpt. heading corr.").
		specsteer(-3).
	}

	if lndattgtprs {
		if not approach and not slanded and (disttotgt<=appdist) {
			set approach to true.
			statmsg("approach init.").
		}
		if approach {
			if disttotgt>appdist {
				set approach to false.
				statmsg("approach intrpt.").
				ctrlreset(true).
			}
			else {
				if disttotgt<=lnddist and not slanded {
					set landbtn:pressed to true.
				}
			}
		}
	}

	// Head to Steer, Head to Velocity
	if hdsteerprs or hdvelprs {
		set ship:control:yaw to upd_ywpid(90,updyaw).
	}

	// Stop
	if stopprs {
		if joyprs and abs(srfvel)>veltrsh {
			set joyvector to choose heading(vsteer(),170):vector if abrptprs else heading(vsteer(),joyangle(0,abs(srfvel))):vector.

			if vang(joyvector,ship:facing:topvector)<=6 {
				set ship:control:fore to upd_vvelpid(vvelset(),vertvel).
			}
		}
		else {
			set joyvector to heading(steer,90):vector.
			set ship:control:fore to upd_fwdpid(0,fwdvel).
		}
		set ship:control:starboard to upd_sidpid(0+sbdoffst,sidvel).
	}

	// Alt. by Throttle
	if thraltprs {
		local vertthr is upd_vvelpid(vvelset(),vertvel).
		if stopprs and abrptprs and joyprs and abs(srfvel)>veltrsh {
			set mthr to (sin(vang(ship:facing:topvector,ship:up:vector))).
		}
		else {
			set mthr to vertthr.
		}
	}

	// Alt. by Translation
	if trnaltprs {
		set ship:control:top to upd_vvelpid(vvelset(),vertvel).
	}

	// Fwd. by Translation
	if trnfwdprs {
		set ship:control:fore to upd_fwdpid(set_vel,fwdvel).
		set ship:control:starboard to upd_sidpid(0+sbdoffst,sidvel).
	}

	// Fwd. by Throttle
	if thrfwdprs {
		local jangle is joyangle(set_vel,fwdvel).
		if turnsteerprs and jangle<=95 {
			set joyvector to heading(trnsteer(),jangle):vector-ssidv.
		}
		else {
			set joyvector to heading(steer,jangle):vector-ssidv.
			if sidyprs {
				set ship:control:starboard to upd_sidpid(0,sidvel).
			}
			if approach and appfwdprs {set ship:control:fore to min(0,upd_fwdpid(set_vel,fwdvel)).}.
		}
		set mthr to (sin(vang(ship:up:vector,joyvector))*abs(upd_tfpid(set_vel,fwdvel)))+mthr.
	}

	// Level Pitch, Roll
	if pitchprs or rollprs {
		set joyvector to ship:up:vector.
	}

	// Landing
	if landprs {
		if set_alt>-1 and abs(srfvel)<=veltrsh {
			set set_alt to -1.
		}
		if slanded {
			if ship:angularvel:mag < 0.1 and abs(srfvel)<0.1 {
				wait until btnsoff(ctrlpanlex["controls1"]["controls"],"JoyStick Control >>").
				set approach to false.
				statmsg("landed").
				ctrlreset(true).
			}
			else {
				set ship:control:top to -1.
				brakes on.
			}
		}
	}
	else {
		if fuelpct<=minfuel and not slanded {
			statmsg("fuel running out, landing...").
			set landbtn:pressed to true.
		}
		if hasrt and not (aconn or locconn) and not slanded {
			statmsg("connection lost, landing...").
			set landbtn:pressed to true.
		}
	}

	// Panic!
	if panicprs {
		if ship:angularvel:mag < 0.1 {
			set panicbtn:pressed to false.
			set thraltbtn:pressed to true.
			set hdsteerbtn:pressed to true.
			rcs on.
			sas off.
			statmsg("panic fin.").
		}
	}

	// Turn by throttle (Steer!)
	if turnsteerprs {
		if vang(velplane,steerv)<=tsteer {set turnsteerbtn:pressed to false.}.
	}
	if forcsteerprs {
		if vang(velplane,steerv)>tsteer*fsteer {set turnsteerbtn:pressed to true.}.
	}

	// engage emergency throttle
	if emergthrprs {
		if not thraltprs and vertvel<minvertvel*emergcoef {
			set thraltbtn:pressed to true.
		}
	}

	// Full Throttle
	if boostprs {
		set mthr to 1.
		set ship:control:top to 1.
	}

	if dopitch {
		set ship:control:pitch to -upd_ptchpid(90,updpitch).
	}
	if doroll {
		set ship:control:roll to upd_rllpid(90,updroll).
	}

	if haslaser and actlsrprs and not landprs and not slanded {
		if lasrdist=prvlsrdist {rbtnlasr().}.
		if rdalt<lsrralt {
			lasr:setfield("bend y",lsrby).
			if lasrcond {
				lsvisible(true).
				if lsrcnt<evdlim {
					if vang(ship:facing:forevector,mvvector)<lsrslope {
						set lsrcnt to lsrcnt + 1.
						if lsrcnt>=evdlim {
							set lsrcnt to evdlim.
							set velcut to velcut/lsrvcut.
							lsvisible(true).
							statmsg("evade init.").
						}
					}
				}
				else {
					if fwdvel<=set_vel*1.1 {
						set lsrcnt to 1.
					}
				}
			}
			else {
				if lsrcnt>0 {
					if velcut<1 {
						if fwdvel<=set_vel or vang(ship:facing:forevector,mvvector)<lsrslope {
							set lsrcnt to lsrcnt - 1.
							if lsrcnt<=0 {
								set velcut to min(1,velcut*lsrvcut).
								set lsrcnt to evdlim.
							}
						}
					}
					else {
						set lsrcnt to 0.
						statmsg("evade fin.").
					}
				}
				lsvisible(vislsrchb:pressed).
			}
		}
		set prvlsrdist to lasrdist.
	}

	if pctpwr<pwrlim and not spextracted and not solpanprs {
		statmsg("power below limit").
		solpanels(true).
	}
	if spextracted and pctpwr>=95 and not solpanprs {
		statmsg("power restored").
		solpanels(false).
	}

	set ship:control:mainthrottle to mthr*shornt().

	print "OPCODESLEFT: ["+OPCODESLEFT+"]   " at(tclmn1,0). print "curtime: ["+round(curtime,1)+"]   " at(tclmn2,0). print "loop:["+(time:seconds-looptime)+"]----------" at(tclmn3,0).

	if termdata {
		print "radar alt.: ["+round(rdalt,2)+"]   " at(tclmn1,2). print "setpoint: ["+round(set_alt,2)+"]   " at(tclmn2,2).
		print "vertical vel.: ["+round(vertvel,2)+"]   " at(tclmn1,3). print "setpoint: ["+round(vvelset(),2)+"]   "  at(tclmn2,3).

		print "fwd.: ["+round(fwdvel,2)+"]   " at(tclmn1,4). print "side.: ["+round(sidvel,2)+"]   " at(tclmn2,4). print "all: ["+round(srfvel,2)+"]   " at(tclmn3,4).

		print "flight: ["+mvtype+"]; approach: ["+approach+"]; landed: ["+slanded+"]   " at(tclmn1,6).
		print "fuel: ["+round(fuelpct,1)+"/"+minfuel+"%]  " at(tclmn1,8). print "power: ["+round(pctpwr,1)+"/"+pwrlim+"%]  " at(tclmn2,8).
		print "pid preset: ["+savsuffix+"]   " at(tclmn1,9).

		if haslaser {
			print "cond: ["+lasrcond+"]   " at(tclmn1,11). print "lsrcnt: ["+lsrcnt+"]   " at(tclmn2,11). print "velcut: ["+round(velcut,2)+"]   " at(tclmn3,11).
			print "lasrdist: ["+round(lasrdist,0)+"]   " at(tclmn1,12). print "srfvel*detcoef: ["+round(srfvel*detcoef,2)+"]   " at(tclmn2,12).
		}

		print "dist. to land (m or s): ["+round(disttotgt,1)+"]  " at(0,14).

		if showverbose {
			print "joyangle: ["+round(joyangle(set_vel,fwdvel),2)+"]; altparm: ["+round(altparm,2)+"]-------" at(0,16).
			print "shornt: "+shornt()+"; vsteer: "+round(vsteer(),0) at (0,17).

			print "pitch,yaw,roll: "+dopitch+","+doyaw+","+doroll+"]--------" at(0,19).
			print "Pitch angle *updpitch: ["+round(updpitch,2)+"]; pitch: ["+ship:facing:pitch+"]--------" at(0,20).
			print "Roll angle *updroll: ["+round(updroll,2)+"]; roll: ["+ship:facing:roll+"]--------" at(0,21).

			print "shangl: "+round(shangl,2)+"; srangl: "+round(srangl,2)+"; stangl: "+round(stangl,2) at (0,23).

print "vang: "+vang(ship:facing:forevector,mvvector)+" < slope: "+lsrslope+"     " at (0,25).




		}
	}

	wait 0.
}

if haslengs {lock_gimbal(false).}.
if haslaser {lsvisible(false).}.

ctrlreset(true).

if areboot="yes" {exit_cleanup().reboot.}
else if areboot="ask" {ynmsg(list("Reboot CPU?"),red,{exit_cleanup().reboot.},{},true).}.
exit_cleanup(). // proper disposal of all GUIs, cleanup of all lexicons and saving of final GUIs positions.
