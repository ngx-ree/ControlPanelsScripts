//

// main throttle, hovering...
// global thkp is 0.05. //0.05. //0.01.
// global thki is 0.006. //0.006. 
// global thkd is 0.06. //0.006. //wobble,fast reaction> smooth,slow reaction<

// throttle for forward
global tfkp is 0.05.
global tfki is 0.006.
global tfkd is 0.06.
global tfeps is 0.

//vertical velocity, hovering, landing...
global vvelkp is 0.5.
global vvelki is 0.06.
global vvelkd is 0.08.
global vveleps is 0.

// up-down translation
// global altkp is 0.5. //0.05. //0.01.
// global altki is 0.06. //0.006. 
// global altkd is 0.6. //0.006.

// forward-backward translation
global fwdkp is 0.5. //--0.5
global fwdki is 0.001. //--0.06
global fwdkd is 0.2. //--0.5
global fwdeps is 0.

// lateral translation
global sidkp is 0.5. //--0.5
global sidki is 0.001. //--0.6
global sidkd is 0.2. //--0.8
global sideps is 0.

// roll
global rllkp is 0.02.//0.03.
global rllki is 0.006.//0.0001.
global rllkd is 0.03.//0.025.
global rlleps is 0.

// yaw
global ywkp is 0.03.//0.03.
global ywki is 0.006.//0.0001.
global ywkd is 0.03.//0.035.
global yweps is 0.

// pitch
global ptchkp is 0.03.//0.06.
global ptchki is 0.006.//0.0001.
global ptchkd is 0.03.//0.06.
global ptcheps is 0.

////////////// joystick vector angle, velocity part
global jyangkp is 0.1.
global jyangki is 0.06.
global jyangkd is 0.08.
global jyangeps is 0.

// // joystick vector angle, altitude part
// global altangkp is 0.01.//001. //0.05. //0.01.
// global altangki is 0.006. //0.006. 
// global altangkd is 0.006. //0.006.

// joystick lateral
global jsidkp is 0.5. //--0.5
global jsidki is 0.001. //--0.6
global jsidkd is 0.2. //--0.8
global jsideps is 0.