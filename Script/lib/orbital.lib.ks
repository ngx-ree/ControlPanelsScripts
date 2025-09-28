// orbital.lib.ks by ngx

// Library related to basic orbital maneuvers, like circularizations or transfers.
// Functions here are a bit chaotic, but they sort of work, so I don't "optimize". Yet....

// Returns dv for the vessel to circularize orbit either on AP or PE (only!)
declare global function orbit_circ_dv {
	parameter cship. // Current vessel.
	parameter atApsis. // AP or PE value where the burn starts. Enter radius, not altitude!
	parameter cbody is cship:body. // The body for which we compute the maneuver. By default it is the body that the current vessel is orbiting.

	local cv is sqrt(cbody:mu/(atApsis)). // velocity of circular orbit
	local dv is cv-orbit_v(cship,atApsis,cship:orbit:semimajoraxis,cbody).

	return dv.
}

// Returns dv to change orbit from-to.
declare global function orbit_dv {
	parameter cship. // Current vessel.
	parameter atAx. // Radius point of burn start.
	parameter toApsis. // Final radius.
	parameter cbody is cship:body. // The body for which we compute the maneuver. By default it is the body that the current vessel is orbiting.

	local sma2 is (atAx+toApsis)/2. // New sma with current atAx radius and new toApsis radius.
	local v1 is orbit_v(cship,atAx,cship:orbit:semimajoraxis,cbody). // v at 'from' radius atAx while circular (current).
	local v2 is orbit_v(cship,atAx,sma2,cbody). // v at atAx (current) radius with new sma2 with new lowest radius toApsis.
	local dv is v2-v1. // dv to achieve new orbit.

	return dv.
}

// Returns orbital velocity of the ship at a given radius (not altitude!) for the specified orbit.
declare global function orbit_v { // Enter radius, not altitude!
	parameter cship. // Current vessel.
	parameter atAx. // Radius at the point where velocity is calculated.
	parameter sma is cship:orbit:semimajoraxis.	// If not entered, current ship's orbit SMA is used.
	parameter cbody is cship:body. // If not entered, current ship's body is used.

	local ve is sqrt(cbody:mu*((2/atAx)-(1/sma))).

	return ve.
}

global didonce is false.
global thrset is 1.
global orisas is sas.

// Function 'prepnodex' prepares execution of maneuver node and steers the vessel towards the maneuver.
// Global variables used:
// maneuverNode - kOS maneuver node is prepared in main script and used here.
function prepnodex {
	parameter p.
	if p {
		lock manarrtime to maneuverNode:eta.
		lock mydeltav to maneuverNode:deltav:mag.
		lock burnstart to manarrtime-burntime()/2.

		statmsg("maneuver arrival time: "+manarrtime).
		statmsg("maneuver burntime: "+burntime()).
		statmsg("maneuver burnstart: "+burnstart).
		statmsg("maneuver delta V: "+mydeltav).

		set didonce to false.
		set orisas to sas. // Let's remember last SAS status so that we can return it back later.

		sas off.
		lock steering to lookdirup(maneuverNode:burnvector,ship:facing:topvector).
	}
	else {
		unlock steering.
		unlock throttle.
	}
}

// This function is called in a loop from within the main script. The function is called periodically, usually when 'doNode' variable is TRUE.
// Global variables used:
// maneuverNode - Maneuver node itself, created and set up in the main script.
// execnodbtn - 'Execute Node' button, usually setting 'doNode' variable to TRUE
// nodfin - Global variable declared and handled in the main script. It is set to TRUE after the node execution is finished.
function execnode {
	parameter term is true. // If TRUE, burn start and burn time (in seconds) will be displayed in the terminal window.
	parameter atx is 0. // X terminal position of burn start/burn time line.
	parameter aty is 17. // Y terminal position of burn start/burn time line.
	if term {
		print "burn start: ["+round(burnstart,0)+"]; burn time: ["+round(burntime,0)+"]-------" at(atx,aty).
	}

	if not didonce and throttle<1 and burnstart <= 0 {
		set thrset to mydeltav/brakeDeltaV. // for case when deltav < brakedeltav
		lock throttle to thrset.
		set didonce to true.
	}
	if didonce {
		if mydeltav <= brakeDeltaV and mydeltav > remnThrottle {
			set thrset to mydeltav/brakeDeltaV.
		}

		if mydeltav <= finDeltaV {
			set thrset to 0.
			unlock steering.
			unlock throttle.
			if defined execnodbtn {set execnodbtn:pressed to false.}.
			if defined nodfin {set nodfin to true.}.
			set sas to orisas. // Set SAS status to the state before maneuver node execution.
		}
	}
}


// Function 'burntime' returns a very crude burn time value, but works for basic maneuvers.
global function burntime {
	if ship:maxthrust>0 {
		return mydeltav/(ship:maxthrust/ship:mass).
	} else {
		return 0.
	}
}
