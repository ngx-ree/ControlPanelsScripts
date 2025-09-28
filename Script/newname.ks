// newname.ks by ngx

@lazyglobal off.
parameter newship is ship:name.

if exists("etc") {
	clearscreen.
	global argoon is true.
	if newship="" {
		print "usage".
	}
	else {
		if volume():name="Archive" {
			print "WARNING: running on Archive, continue? [y/n]".
			if inpchar()<>"Y" {set argoon to false.}.
		}
		if argoon {
			clearscreen.
			global locetc is open("etc/"):list().
			global confl is list().
			global oldship is "".
			for locfile in locetc:keys {
				if locfile<>"templates" {
					if not open("etc/"+locfile):isfile {
						confl:add(locfile).
					}
				}
			}
			if confl:length>1 {
				// we have more directories, let's make choice
				print "multiple directories found: ".
				from {local nm is 0.} until nm=(confl:length) step {set nm to nm+1.} do {
					print +nm+" - "+confl[nm].
				}
				set oldship to confl[inpsel()].
			}
			else {
				// there is single directory, let's rename it directly
				set oldship to confl[0].
			}
			clearscreen.
			print "old ship: '"+oldship+"'".
			print "new ship: '"+newship+"'".

			if newship=oldship {
				print "old ship and new ship cannot be the same, exiting...".
			}
			else {
				print " ".
				print "[r]eplace, [c]opy or [q]uit ? (press 'r', 'c' or 'q')".

				local act is " ".
				until "rcq":contains(act) {
					set act to inpchar().
				}
				print "selected: "+act.
				if act="q" {
					print "user quit, exiting...".
				}
				else {
					local fnclex is lexicon(
						"r",movepath@,
						"c",copypath@
					).
					local olddir is "etc/"+oldship.
					local newdir is "etc/"+newship.
					local shf is open(olddir):list().
					if shf:length=0 {
						print "directory '"+olddir+"' is empty, exiting...".
					}
					else {
						print " ".
						for lfile in shf:keys {
							local ffrom is olddir+"/"+lfile.
							local fto is ffrom:replace(oldship,newship).
							print "migrating '"+ffrom+"'".
							print "to '"+fto+"'".
							fnclex[act](ffrom,fto).
						}
						print " ".
						if act="r" {
							print "removing '"+olddir+"' directory".
							if open(olddir):list():length>0 {
								print "directory not empty, NOT removed...".
							}
							else {
								deletepath(olddir).
							}
						}
						if ship:name<>newship {
							print " ".
							print "renaming ship from '"+ship:name+"' to '"+newship+"'".
							set ship:name to newship.
						}
					}
				}
			}
		}
	}
}
else {
	print "'etc' directory not present on '"+volume():name+"' filesystem, exiting...".
}

function inpsel {
	local sel is "".
	local ic is "".
	local prompt is "enter directory number: ".
	local col is prompt:length.
	local lin is min(terminal:height,confl:length+2).
	until ic=terminal:input:return and sel:tonumber(-1)>-1 and sel:tonumber()<confl:length {
		print prompt at(0,lin).	print "_ " at(col,lin).
		set ic to inpchar().
		if ic=terminal:input:backspace {
			set col to choose col-1 if col>prompt:length else col.
			set sel to choose sel:substring(0,sel:length-1) if sel:length>1 else "".
		}
		else {
			if ic<>terminal:input:return {
				print ic at(col,lin).
				set col to col+1.
				set sel to sel+ic.
			}
		}
	}
	return sel:tonumber().
}

function inpchar {
	if terminal:input:haschar() {terminal:input:clear().}.
	return terminal:input:getchar().
}
