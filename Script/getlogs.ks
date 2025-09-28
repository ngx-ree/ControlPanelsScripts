// getlogs.ks by ngx

@lazyglobal off.
global scriptid is "getlogs".
runoncepath("lib/settings.lib.ks").
runoncepath("lib/ctrlpanel.lib.ks").

clearguis().
loadguipos().

global scriptend is false.
global starttime is time:seconds.
lock curtime to time:seconds-starttime.

ctrlpanel(false,false,true,currsets["ctrlw"][0],100,100,0,0,0,false).
global savepos is true.
global clsbtn is ctrlpan:addbutton("Clear Screen").
set clsbtn:tooltip to "Clears terminal window.".
set clsbtn:onclick to {
	clearscreen.
	print "screen cleared".
}.

print "waiting for logs".
global looptime is 0.
until scriptend {
	set looptime to time:seconds.
	if not core:messages:empty {
		local received is core:messages:pop.
		print received:content.
	}
	wait 0.
}.

core:messages:clear.

exit_cleanup().
print "getlogs exited".