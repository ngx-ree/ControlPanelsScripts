// exported etc/quad-a 1.1-t_q66_PID.save.kerbin1

// throttle forward
global tfkp is 0.05.
global tfki is 0.006.
global tfkd is 0.06.
global tfeps is 0.

// vertical velocity
global vvelkp is 0.06.
global vvelki is 0.008.
global vvelkd is 0.03.
global vveleps is 0.

// forward velocity
global fwdkp is 0.5.
global fwdki is 0.001.
global fwdkd is 0.2.
global fwdeps is 0.

// lateral velocity
global sidkp is 0.5.
global sidki is 0.001.
global sidkd is 0.2.
global sideps is 0.

// roll angle
global rllkp is 0.001.
global rllki is 0.0006.
global rllkd is 0.003.
global rlleps is 0.

// yaw angle
global ywkp is 0.015.
global ywki is 0.0008.
global ywkd is 0.025.
global yweps is 0.

// pitch angle
global ptchkp is 0.001.
global ptchki is 0.0006.
global ptchkd is 0.003.
global ptcheps is 0.

// joystick angle
global jyangkp is 0.015.
global jyangki is 0.0008.
global jyangkd is 0.025.
global jyangeps is 0.

// joystick lateral
global jsidkp is 0.5. //--0.5
global jsidki is 0.001. //--0.6
global jsidkd is 0.2. //--0.8
global jsideps is 0.

// forward velocity by surfaces
global fwdskp is 0.01.
global fwdski is 0.0001.
global fwdskd is 0.003.
global fwdseps is 0.

// lateral velocity by surfaces
global sidskp is 0.01.
global sidski is 0.0001.
global sidskd is 0.003.
global sidseps is 0.

// roll angle by surfaces
global rllskp is 0.01.
global rllski is 0.006.
global rllskd is 0.03.
global rllseps is 0.

// yaw angle by surfaces
global ywskp is 0.005.
global ywski is 0.0008.
global ywskd is 0.004.
global ywseps is 0.

// pitch angle by surfaces
global ptchskp is 0.01.
global ptchski is 0.006.
global ptchskd is 0.03.
global ptchseps is 0.

// roll angle by hinges
global rllhkp is 0.01.
global rllhki is 0.006.
global rllhkd is 0.03.
global rllheps is 0.

// pitch angle by hinges
global ptchhkp is 0.01.
global ptchhki is 0.006.
global ptchhkd is 0.03.
global ptchheps is 0.

global plim is 1. // pitch limitation multiplier
global rlim is 1. // roll limitation multiplier
global ywlim is 1. // yaw limitation multiplier
global fblim is 1. // forward-backward limitation multiplier
global sbdlim is 1. // starboard limitation multiplier
global angywdamp is 1. // yaw angvel dampener multiplier
global angptchdamp is 1. // pitch angvel dampener multiplier
global angrlldamp is 1. // roll angvel dampener multiplier


global pslim is 1. // pitch by surfaces limitation multiplier
global rslim is 1. // roll by surfaces limitation multiplier
global ywslim is 1. // yaw by surfaces limitation multiplier
global fbslim is 1. // forward-backward by surfaces limitation multiplier
global sbdslim is 1. // starboard by surfaces limitation multiplier