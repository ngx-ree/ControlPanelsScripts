// lnd65.ks by ngx

// functions !!!
// X comments finalized, checked
// X textfields cleaned
// X statmsg
// X tooltips checked TODO:
// X descr checked TODO:
// X terminaldata
// X }. cleared
//!!! gofst

@lazyglobal off.
global scriptid is "lnd65".
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

ctrlpanel(true,true,true,currsets["ctrlw"][0],currsets["ctrlx"][0],currsets["ctrly"][0],1).
set trmbtn:pressed to true.

global input_data is lexicon(
"restvel",list("landing speed (m/s)",3,"Final planned vertical speed when the vessel touches the ground."),
"altdiv",list("landing coefficient",10,"Coefficient for landing speed decrease based on radar altitude. During landing, radar altitude divided by this value determines vertical velocity (for example: if 10, descent velocity at 100 m will be 10 m/s, at 50 m will be 5 m/s, etc.). The higher the value, the more efficient landing is, at a cost of more fuel spent."),
"rdland",list("radar landed height (m)",7,"During landing sequence, if probe's radar altitude is less than this value, the probe is considered landed. Depends on probe's dimensions, so measure it before use."),
"gearalt",list("gear altitude (m)",300,"Altitude at which gear is lowered ('gear on') during landing."),
"chwheels",list("check for wheels",false,"If TRUE, the script will check for the presence of wheels to enable 'friction settings' in the 'switches' tab."),
"engagealt",list("engage altitude (m)",10000,"Maximum radar altitude at which the landing loop is active."),
"maxv",list("max. desc. velocity (m/s)",-500,"Maximum vertical velocity (negative number means descent). Even if the vessel is above the landing altitude threshold (landing not active), the script will not allow exceeding this velocity."),
"mingimb",list("final gimbal limit (%)",5,"To improve vessel stability, the gimbal of landing engine(s) (dubbed 'leng') is gradually limited during the final landing sequence. This value is the minimum final gimbal limit when the vessel touches the ground."),
"ragimb",list("gimbal limit alt. (m)",1000,"The altitude below which gimbal limitation begins during landing."),
"termlog",list("initial terminal log",false,"If TRUE, sending logs to another terminal window will be enabled right after the script starts."),
"cpuid",list("CPUID for messages",list(),"ID of the kOS log destination terminal window where script logs are sent. The destination terminal must be named (CPUID = kOS name tag) and must be running the 'getlogs.ks' script."),
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
}
).

inputpane(goon,false,1,currsets["inpx"][0],currsets["inpy"][0],true).

global restvel is input_data["restvel"][1].
global altdiv is input_data["altdiv"][1].
global rdland is input_data["rdland"][1].
global gearalt is input_data["gearalt"][1].
global engagealt is input_data["engagealt"][1].
global maxv is input_data["maxv"][1].
global mingimb is input_data["mingimb"][1].
global ragimb is input_data["ragimb"][1].
global termlog is input_data["termlog"][1].
global cpuid is input_data["cpuid"][1].
global savepos is input_data["savepos"][1].
global areboot is input_data["areboot"][1].

global pidsbtn is ctrlpan:addbutton("PIDs").
set pidsbtn:toggle to true.
set pidsbtn:ontoggle to {
	parameter tog.
	pidspanel("pidspanel",tog).

}.

global thkp is 0.05.
global thki is 0.06.
global thkd is 0.006.
global theps is 0.
global thpid is pidloop(thkp, thki, thkd, 0, 1, theps).

lock shalt to ship:altitude.
lock rdalt to alt:radar.
lock vertvel to ship:verticalspeed.
lock srfvel to ship:groundspeed.
lock lndvel to -(round(rdalt/altdiv,1)+restvel).

lock pilotthr to ship:control:pilotmainthrottle.
lock allvel to sqrt(srfvel^2+vertvel^2)*(vertvel/abs(vertvel)).
lock shangl to 180-vang(ship:facing:vector,ship:velocity:surface).
lock gimblim to ((rdalt/ragimb)*100)+shangl.
lock twistfact to abs(allvel/50).

global thset is lndvel.
global pu is 0.
global thrott is 0.

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
	popmsg(list("No landing engines dubbed.","Script will not work, exiting..."),red,{set scriptend to true.},200).
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
		popmsg(list("No landing gear dubbed.","Gear friction control unavailable."),rgb(0.6,0.7,1)).
		set hasfric to false.
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

// globals and locks
global landing is false.
global pflying is false.
global suspend is false.

////////////////////// GUI STUFF ////////////////////

ctrlmpanel("controls1","Probe Control: "+ship:name,list("controls","switches"),true,true,list(550,550),currsets["ctrlm1x"][0],currsets["ctrlm1y"][0]).

// GUI
{
// controls
{
local ctrls1 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global ctrlfinl is ctrlLRCombo("controls1",ctrls1,input_data["restvel"][0],restvel:tostring(),"",false,false,list(1,1,10)).
if input_data["restvel"]:length=3{set ctrlfinl["label"]:tooltip to input_data["restvel"][2].}.
set ctrlfinl["leftbtn"]:onclick to {
	set restvel to chkvalfinl(restvel-finlstep).
}.

set ctrlfinl["label"]:style:width to 140.
set ctrlfinl["txtfield"]:style:width to 50.
set ctrlfinl["txtfield"]:onconfirm to {
	parameter str.
	set restvel to chkvalfinl(str:tonumber(restvel)).
}.
lock finlstep to round(ctrlfinl["slider"]:value,0).
set ctrlfinl["rightbtn"]:onclick to {
	set restvel to chkvalfinl(restvel+finlstep).
}.
local function chkvalfinl {
	parameter p.
	local val is round(p,0).
	if val<0 {set val to 0.}.
	set ctrlfinl["txtfield"]:text to val:tostring().
	return val.
}

local ctrls2 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global ctrlaltdv is ctrlLRCombo("controls1",ctrls2,input_data["altdiv"][0],altdiv:tostring(),"",false,false,list(1,1,10)).
if input_data["altdiv"]:length=3{set ctrlaltdv["label"]:tooltip to input_data["altdiv"][2].}.
set ctrlaltdv["leftbtn"]:onclick to {
	set altdiv to chkvalaltdv(altdiv-altdvstep).
}.

set ctrlaltdv["label"]:style:width to 140.
set ctrlaltdv["txtfield"]:style:width to 50.
set ctrlaltdv["txtfield"]:onconfirm to {
	parameter str.
	set altdiv to chkvalaltdv(str:tonumber(altdiv)).
}.
lock altdvstep to round(ctrlaltdv["slider"]:value,0).
set ctrlaltdv["rightbtn"]:onclick to {
	set altdiv to chkvalaltdv(altdiv+altdvstep).
}.
local function chkvalaltdv {
	parameter p.
	local val is round(p,0).
	if val<1 {set val to 1.}.
	set ctrlaltdv["txtfield"]:text to val:tostring().
	return val.
}

local ctrls21 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global rdhght is ctrlLRCombo("controls1",ctrls21,input_data["rdland"][0],rdland:tostring(),"",false,false,list(1,1,10)).
if input_data["rdland"]:length=3{set rdhght["label"]:tooltip to input_data["rdland"][2].}.
set rdhght["leftbtn"]:onclick to {
	set rdland to chkvalrdl(rdland-rdlstep).
}.

set rdhght["label"]:style:width to 160.
set rdhght["txtfield"]:style:width to 30.
set rdhght["txtfield"]:onconfirm to {
	parameter str.
	set rdland to chkvalrdl(str:tonumber(rdland)).
}.
lock rdlstep to round(rdhght["slider"]:value,0).
set rdhght["rightbtn"]:onclick to {
	set rdland to chkvalrdl(rdland+rdlstep).
}.
local function chkvalrdl {
	parameter p.
	local val is round(p,0).
	if val<0 {set val to 0.}.
	set rdhght["txtfield"]:text to val:tostring().
	return val.
}

local ctrls3 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global ctrlgralt is ctrlLRCombo("controls1",ctrls3,input_data["gearalt"][0],gearalt:tostring(),"",false,false).
if input_data["gearalt"]:length=3{set ctrlgralt["label"]:tooltip to input_data["gearalt"][2].}.
set ctrlgralt["leftbtn"]:onclick to {
	set gearalt to chkvalgralt(gearalt-graltstep).
}.

set ctrlgralt["label"]:style:width to 140.
set ctrlgralt["txtfield"]:style:width to 50.
set ctrlgralt["txtfield"]:onconfirm to {
	parameter str.
	set gearalt to chkvalgralt(str:tonumber(gearalt)).
}.
lock graltstep to round(ctrlgralt["slider"]:value,0).
set ctrlgralt["rightbtn"]:onclick to {
	set gearalt to chkvalgralt(gearalt+graltstep).
}.
local function chkvalgralt {
	parameter p.
	local val is round(p,0).
	if val<0 {set val to 0.}.
	set ctrlgralt["txtfield"]:text to val:tostring().
	return val.
}

local ctrls4 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global ctrlengalt is ctrlLRCombo("controls1",ctrls4,input_data["engagealt"][0],engagealt:tostring(),"",false,false,list(100,1,1000)).
if input_data["engagealt"]:length=3{set ctrlengalt["label"]:tooltip to input_data["engagealt"][2].}.
set ctrlengalt["leftbtn"]:onclick to {
	set engagealt to chkvalengalt(engagealt-engaltstep).
}.

set ctrlengalt["label"]:style:width to 140.
set ctrlengalt["txtfield"]:style:width to 50.
set ctrlengalt["txtfield"]:onconfirm to {
	parameter str.
	set engagealt to chkvalengalt(str:tonumber(engagealt)).
}.
lock engaltstep to round(ctrlengalt["slider"]:value,0).
set ctrlengalt["steplab"]:style:width to 40.
set ctrlengalt["rightbtn"]:onclick to {
	set engagealt to chkvalengalt(engagealt+engaltstep).
}.
local function chkvalengalt {
	parameter p.
	local val is round(p,0).
	if val<0 {set val to 0.}.
	set ctrlengalt["txtfield"]:text to val:tostring().
	return val.
}

local ctrls5 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global ctrlmxvel is ctrlLRCombo("controls1",ctrls5,input_data["maxv"][0],maxv:tostring(),"",false,false,list(10,1,100)).
if input_data["maxv"]:length=3{set ctrlmxvel["label"]:tooltip to input_data["maxv"][2].}.
set ctrlmxvel["leftbtn"]:onclick to {
	set maxv to chkvalmxvel(maxv-mxvelstep).
}.

set ctrlmxvel["label"]:style:width to 140.
set ctrlmxvel["txtfield"]:style:width to 50.
set ctrlmxvel["txtfield"]:onconfirm to {
	parameter str.
	set maxv to chkvalmxvel(str:tonumber(maxv)).
}.
lock mxvelstep to round(ctrlmxvel["slider"]:value,0).
set ctrlmxvel["steplab"]:style:width to 30.
set ctrlmxvel["rightbtn"]:onclick to {
	set maxv to chkvalmxvel(maxv+mxvelstep).
}.
local function chkvalmxvel {
	parameter p.
	local val is round(p,0).
	if val>0 {set val to 0.}.
	set ctrlmxvel["txtfield"]:text to val:tostring().
	return val.
}

local ctrls6 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global ctrlmngmb is ctrlLRCombo("controls1",ctrls6,input_data["mingimb"][0],mingimb:tostring(),"",false,false,list(1,1,10)).
if input_data["mingimb"]:length=3{set ctrlmngmb["label"]:tooltip to input_data["mingimb"][2].}.
set ctrlmngmb["leftbtn"]:onclick to {
	set mingimb to chkvalmngmb(mingimb-mngmbstep).
}.

set ctrlmngmb["label"]:style:width to 140.
set ctrlmngmb["txtfield"]:style:width to 50.
set ctrlmngmb["txtfield"]:onconfirm to {
	parameter str.
	set mingimb to chkvalmngmb(str:tonumber(mingimb)).
}.
lock mngmbstep to round(ctrlmngmb["slider"]:value,0).
set ctrlmngmb["rightbtn"]:onclick to {
	set mingimb to chkvalmngmb(mingimb+mngmbstep).
}.
local function chkvalmngmb {
	parameter p.
	local val is round(p,0).
	if val<0 {set val to 0.}.
	set ctrlmngmb["txtfield"]:text to val:tostring().
	return val.
}

local ctrls7 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global ctrlrgmb is ctrlLRCombo("controls1",ctrls7,input_data["ragimb"][0],ragimb:tostring(),"",false,false).
if input_data["ragimb"]:length=3{set ctrlrgmb["label"]:tooltip to input_data["ragimb"][2].}.
set ctrlrgmb["leftbtn"]:onclick to {
	set ragimb to chkvalrgmb(ragimb-rgmbstep).
}.

set ctrlrgmb["label"]:style:width to 140.
set ctrlrgmb["txtfield"]:style:width to 50.
set ctrlrgmb["txtfield"]:onconfirm to {
	parameter str.
	set ragimb to chkvalrgmb(str:tonumber(ragimb)).
}.
lock rgmbstep to round(ctrlrgmb["slider"]:value,0).
set ctrlrgmb["rightbtn"]:onclick to {
	set ragimb to chkvalrgmb(ragimb+rgmbstep).
}.
local function chkvalrgmb {
	parameter p.
	local val is round(p,0).
	if val<0 {set val to 0.}.
	set ctrlrgmb["txtfield"]:text to val:tostring().
	return val.
}

local ctrls22 is ctrlpanlex["controls1"]["controls"]:addhlayout().
global gimbbtn is ctrls22:addbutton("Lock Gimbal").
set gimbbtn:tooltip to "Locks the gimbals of engines tagged with 'leng'.".
set gimbbtn:toggle to true.
set gimbbtn:ontoggle to {
	parameter tog.
	if tog {
		lock_gimbal(true).
	}
	else {
		lock_gimbal(false).
	}
}.

global suspprs is false.
global suspbtn is ctrls22:addbutton("Suspend").
set suspbtn:tooltip to "If pressed, the functional part of the script is suspended and manual ship control is restored. This has similar effect as using pilot throttle (controlling throttle manually in KSP).".
set suspbtn:toggle to true.
set suspbtn:ontoggle to {
	parameter tog.
	set suspprs to tog.
	if tog {
	}
	else {
		set suspend to false.
	}
}.
}
// switches
{

if hasfric {
	local lvrsets5 is ctrlpanlex["controls1"]["switches"]:addhbox().
	global fricdownbtn is lvrsets5:addbutton("<<<").
	set fricdownbtn:style:width to 50.
	set fricdownbtn:onclick to {
		set finfric to finfric - fricstep.
		if finfric < 0 {set finfric to 0.}.
		set dlgfric:text to finfric:tostring().
		setfrict(finfric).
	}.
	global labfric is lvrsets5:addlabel("Friction:").
	set labfric:style:align to "left".
	set labfric:style:width to 65.
	global dlgfric is lvrsets5:addbutton(finfric:tostring()).
	set dlgfric:style:align to "right".
	set dlgfric:style:width to 60.
	set dlgfric:onclick to {
		set dlgfricx:text to finfric:tostring().
		dlgfric:hide.
		dlgfricx:show.
	}.
	global dlgfricx is lvrsets5:addtextfield(finfric:tostring()).
	set dlgfricx:style:align to "right".
	set dlgfricx:style:width to 60.
	set dlgfricx:onconfirm to {
		parameter str.
		set dlgfric:text to str.
		set finfric to str:tonumber(finfric).
		dlgfricx:hide.
		dlgfric:show.
		setfrict(finfric).
	}.
	dlgfricx:hide.
	global fricslid is lvrsets5:addhslider(1,0.1,1).
	set fricslid:onchange to {
		parameter slid.
		set fricsteplab:text to fricstep:tostring().
	}.
	global fricsteplab is lvrsets5:addlabel("").
	set fricsteplab:style:width to 20.
	set fricsteplab:style:align to "center".
	lock fricstep to round(fricslid:value,1).
	set fricsteplab:text to fricstep:tostring().
	global fricupbtn is lvrsets5:addbutton(">>>").
	set fricupbtn:style:width to 50.
	set fricupbtn:onclick to {
		set finfric to finfric + fricstep.
		if finfric > 10 {set finfric to 10.}.
		set dlgfric:text to finfric:tostring().
		setfrict(finfric).
	}.
}

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

global solpanprs is false.
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
}


// FUNCTIONS

function pidspanel {
	parameter panid.
	parameter tog.
	if tog {
		ctrlmpanel(panid,"PID settings",list("PID values")).
		local ldsvsset is ctrlpanlex[panid]["PID values"]:addhlayout().
		global saveloadbtn1 is svldbtn(ldsvsset).
		set saveloadbtn1:ontoggle to {
			parameter tog.
			saveload(tog,guilex[panid]:x,guilex[panid]:y-200).
		}.

		local confset is savldconf(ldsvsset).
		global saveconfchb1 is confset[0].
		global loadconfchb1 is confset[1].

		local thpidset is ctrlpanlex[panid]["PID values"]:addhbox().
		global thkpdlg is valbox(panid,thpidset,"thkp","th kp:",thpid:kp,{
			parameter str.
			set thpid:kp to str:tonumber(thpid:kp).
		},"throttle for forward").
		global thkidlg is valbox(panid,thpidset,"thki","th ki:",thpid:ki,{
			parameter str.
			set thpid:ki to str:tonumber(thpid:ki).
		}).
		global thkddlg is valbox(panid,thpidset,"thkd","th kd:",thpid:kd,{
			parameter str.
			set thpid:kd to str:tonumber(thpid:kd).
		}).
		global thepsdlg is valbox(panid,thpidset,"theps","th eps:",thpid:epsilon,{
			parameter str.
			set thpid:epsilon to str:tonumber(thpid:epsilon).
		}).
	}
	else {
		set saveloadbtn1:pressed to false.
		killgui("pidspanel").
	}
}

function savvalsload {
	set thpid:kp to savvals["thkp"].
	set thkpdlg["txtfield"]:text to thpid:kp:tostring().
	set thpid:ki to savvals["thki"].
	set thkidlg["txtfield"]:text to thpid:ki:tostring().
	set thpid:kd to savvals["thkd"].
	set thkddlg["txtfield"]:text to thpid:kd:tostring().
	set thpid:epsilon to savvals["theps"].
	set thepsdlg["txtfield"]:text to thpid:epsilon:tostring().
}


function savvalssave {
	set savvals["thkp"] to thpid:kp.
	set savvals["thki"] to thpid:ki.
	set savvals["thkd"] to thpid:kd.
	set savvals["theps"] to thpid:epsilon.
}

when not landing and not suspend and pilotthr=0 and vertvel<-1 and (rdalt<=engagealt or allvel<=maxv) then {
	set landing to true.
	set pflying to false.
	lock throttle to thrott.
	statmsg("locks engaged, landing...").
	return true.
}
when landing and not gear and rdalt<=gearalt then {
	gear on.
	statmsg("gear on").
	return true.
}

when landing and rdalt<=rdland and vertvel>=0 then {
	set thrott to 0.
	set landing to false.
	unlock throttle.
	set ship:control:MAINTHROTTLE to 0.
	set ship:control:fore to -1.
	wait 2.
	set ship:control:fore to 0.
	statmsg("on the ground").
	return true.
}

chkpreset().

global looptime is 0.
global tclmn1 is currsets["tclmn1"][0].
global tclmn2 is currsets["tclmn2"][0].
global tclmn3 is currsets["tclmn3"][0].

until scriptend {
	set looptime to time:seconds.

	if pilotthr>0 or suspprs {
		if not pflying and not suspend {
			set landing to false.
			unlock throttle.
			set_gimbal(100).
			set pflying to true.
			if suspprs {set suspend to true.}.
			unlock steering.
			statmsg("locks released, flying...").
		}
	}
	if landing {
		lock steering to lookdirup(-ship:velocity:surface:normalized,ship:facing:topvector).

		set thset to max(lndvel,maxv).
		set thpid:setpoint to thset.
		set pu to thpid:update(time:seconds, allvel).
		set thrott to pu-(shangl/(twistfact*180)).
		set ship:control:MAINTHROTTLE to thrott.

		if rdalt<ragimb and gimblim>mingimb {
			set_gimbal(gimblim).
		}
	}

	print "OPCODESLEFT: ["+OPCODESLEFT+"]   " at(tclmn1,0). print "curtime: ["+round(curtime,1)+"]   " at(tclmn2,0). print "loop:["+(time:seconds-looptime)+"]----------" at(tclmn3,0).
	if termdata {
		print "altitude: ["+round(shalt,2)+"]   " at(tclmn1,3).
		print "radar alt.: ["+round(rdalt,2)+"]   " at(tclmn2,3).

		print "surface vel.: ["+round(srfvel,2)+"]   " at(tclmn1,5).
		print "vertical vel.: ["+round(vertvel,2)+"]   " at(tclmn2,5).
		print "combined velocity: ["+round(allvel,2)+"]   " at(tclmn1,6).
		print "landing velocity: ["+round(lndvel,2)+"]   " at(tclmn1,7).

		print "ship angle: ["+round(shangl,2)+"]   " at(tclmn1,9).
		print "twist factor: ["+round(twistfact,2)+"]   " at(tclmn2,9).

		print "gimbal lim.: ["+round(gimblim,2)+"]   " at(tclmn1,11).

		print "throttle: ["+round(thrott,2)+"]   " at(tclmn1,13).
		print "thr. set: ["+round(thset,2)+"]   " at(tclmn2,13).

		print "pilot throttle: ["+round(pilotthr,2)+"]   " at(tclmn1,14).

		print "landing: ["+landing+"]  " at(tclmn1,16).
		print "flying: ["+pflying+"]  " at(tclmn2,16).
		print "gear: ["+gear+"]" at(tclmn1,17).

		print "suspended: ["+suspend+"]  " at(tclmn1,19).
	}
	wait 0.
}

ctrlreset(true).

if areboot="yes" {exit_cleanup().reboot.}
else if areboot="ask" {ynmsg(list("Reboot CPU?"),red,{exit_cleanup().reboot.},{},true).}.
exit_cleanup().
