// common.lib.ks by ngx

// Library 'common.lib.ks' contains some functions that are commonly used across multiple scripts. They are related to flight mechanics rather than GUI functions.
// All functions in this library can be masked in the main script if they are defined after this library is included by the 'runoncepath' command.
// Most likely, users will alter parts or the entire 'common.lib.ks' library for their own purposes.

// compass to bearing
function ctob {
	parameter c.
	if c<=180 {
		return -c.
	}
	else {
		return 360-c.
	}
}

// bearing to compass
function btoc {
	parameter b.
	if b<=0 {
		return -b.
	}
	else {
		return 360-b.
	}
}

// Geographical longitude to 360 degrees circle (around equator).
// Converts geographical longitude to a 360-degree circle around the equator, in an eastern direction.
function geotodg {
	parameter l.
	if l<0 {
		return (180+(180-abs(l))).
	}
	else {
		return (l).
	}
}

// Returns a two-dimensional list, detects the direction of movement of the vessel. Element [0] determines the direction forward (1) or backward (-1), element [1] determines the direction right (1) or left (-1)
// global variables used:
// stangl - angle between vessel's  :lock stangl to vang(velplane, steerv).
// srangl - angle between QQQ :lock srangl to vang(velface,ship:facing:starvector).
// velface - vector, velocity QQQ :lock velface to vxcl(ship:facing:upvector,mvvector).
function vdir {
	local veldir is list(0,0).
	if stangl<90 {
		set veldir[0] to 1.
	}
	else if stangl>90 {
		set veldir[0] to -1.
	}
	else {
		set veldir[0] to 0.
	}
	if srangl<90 {
		set veldir[1] to 1.
	}
	else if srangl>90 {
		set veldir[1] to -1.
	}
	else {
		set veldir[0] to 0.
	}
	return veldir.
}

// Returns ship's facing orientation; up:1, down:0
function shornt {
	if vang(ship:up:vector,ship:facing:topvector)<90 {
		return 1.
	}
	else {
		return 0.
	}
}

// Extend/retract solar panels
// global variables used:
// solpan - list containing solar panel parts: lock solpan to ship:partsdubbed("solpan").
// Initial 'haspanels' section cannot be here - it contains a lock statement
function solpanels {
	parameter extend.
	if haspanels {
		if extend {
			statmsg("extending panels").
			for sp in solpan {
				sp:getmodule("ModuleDeployableSolarPanel"):doaction("extend solar panel",true).
			}
		}
		else {
			statmsg("retracting panels").
			for sp in solpan {
				sp:getmodule("ModuleDeployableSolarPanel"):doaction("retract solar panel",true).
			}
		}
		set spextracted to extend.
	}
}

// Get current status of solar panels
// global variables used:
// solpan - list containing solar panels parts: lock solpan to ship:partsdubbed("solpan").
// Initial 'haspanels' section cannot be here - it contains a lock statement
function solpstat {
	local s is "".
	for sp in solpan {
		set s to s+":"+sp:getmodule("ModuleDeployableSolarPanel"):getfield("status").
	}
	return s.
}

// Set wheels friction
// global variables used:
// rvrwheels - list containing wheels with friction control: lock rvrwheels to ship:partsdubbed("wheel").
// Initial 'hasfric' section cannot be here - it contains a lock statement
function setfrict {
	parameter f.
	for whl in rvrwheels {
		whl:getmodule("ModuleWheelBase"):doaction("friction control",true).
		whl:getmodule("ModuleWheelBase"):setfield("friction control",f).
	}
}

// Returns current gimbal limit percentage value (average, in case values of particular engines differ).
// global variables used:
// lengs - list of landing engines (parts dubbed 'leng')
function get_gimbal {
	local sumgimb is 0.
	for engn in lengs {
		local landgimbal is engn:gimbal:limit.
		set sumgimb to sumgimb + landgimbal.
	}
	return (round(sumgimb/lengs:length,0)).
}

// Sets gimbal limit on all landing engines to a given value.
// global variables used:
// lengs - list of landing engines (parts dubbed 'leng')
function set_gimbal {
	parameter glimit.
	for engn in lengs {
		set engn:gimbal:limit to glimit.
	}
}

// Gimbal lock switch for landing engines.
// global variables used:
// lengs - list containing engines with gimbal: lock lengs to ship:partsdubbed("leng").
// Initial 'haslengs' section cannot be here - it contains a lock statement.
function lock_gimbal {
	parameter l.
	for engn in lengs {
		set engn:gimbal:lock to l.
	}
}

// Function 'badpart' checks a list of parts and returns true if any of them is invalid.
function badpart {
	parameter prts. // List of parts to be checked.
	parameter sffxfnc. // Function to check part validity. It must return true if part is valid or false if it is invalid.
	parameter failmsg is "*not stated*".

	local isbad is false.
	for lpart in prts {
		if not sffxfnc(lpart) {
			set isbad to true.
		}
	}
	if isbad {popmsg(list("At least one part dubbed '"+prts[0]:tag+"'","does not have required props.","("+failmsg+")"),red,{},300).}.
	return isbad.
}

// Update waypoints list (added, deleted...).
// global variables used:
// wpnt - waypoint's index in the list of waypoints.
// wpntgobtn - button 'Go waypoint': global wpntgobtn is ctrwp1:addbutton("Go Waypoint").
// labwpnt - label showing the name of the currently selected waypoint.
// wpntleftbtn, wpntrightbtn - buttons to browse waypoints left/right.
function updwpoints {
	if allwaypoints():length = 0 {
		set wpntgobtn:pressed to false.
		set labwpnt:text to "no waypoint".
		wpbtnena(false).
	}
	else {
		if wpnt > allwaypoints():length-1 {set wpnt to allwaypoints():length-1.}.
		set labwpnt:text to allwaypoints()[wpnt]:name.
		wpbtnena(true).
	}
	function wpbtnena {
		parameter ena.
		set wpntleftbtn:enabled to ena.
		set wpntrightbtn:enabled to ena.
		set wpntgobtn:enabled to ena.
	}
}

// Trigger for updating waypoints if some is added or deleted
on allwaypoints():length {
	updwpoints().
	return true.
}

// Reset ALL* controls (to 0), unlock all control locks
function ctrlreset {
	parameter msg.

	unlock steering.
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
	if msg {statmsg("controls reset").}.
}
