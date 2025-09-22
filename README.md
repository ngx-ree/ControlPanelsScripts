# Control Panels Scripts

Control Panels (CP) is a set of kOS scripts and libraries that provide a relatively easy way to assemble functional GUIs for controlling loop-based kOS scripts. The scripts use stacks, buttons, sliders, and other graphical elements, along with options to save and load PID parameters (or any other values) as named presets. I've been writing and using these scripts for several years, and since I recycle them quite often, I figured they could be useful for other kOS enthusiasts as well.

Using and developing with CP scripts and libraries assumes prior knowledge of working with and programming in kOS. However, the code is not overly complicated, and if the comments and descriptions aren't enough, it can be easily reverse-engineered and adjusted to fit anyone's specific needs.

These scripts were written on the fly as I played, so some parts could certainly have been done better and made more universal. I've tried to optimize them and eliminate as many bugs as possible. The libraries and the example.ks script are commented with a reasonable level of detail for easier orientation.

If you come across a bug or any other problem, or if you need more detailed information, feel free to contact me at ngx.ree [at] gmail [dot] com.

CP scripts require kOS version 1.5 or higher. The latest version can be found here:
https://github.com/KSP-KOS/KOS/releases
Of course, don’t forget about dependencies such as ModuleManager.

Older kOS versions have a bug (I believe it’s the one addressed in the “Invoke UI field change callbacks when settings fields” issue) which causes problems with the textfield onconfirm functionality.

An optional mod is Dunbaratu’s LaserDist, an extension of kOS capabilities that provides laser distance-measuring devices. The CP scripts package includes a vessel that uses this mod (along with one of the example scripts). However, if you don’t want to use it, there’s also a version of the vessel without distance meters attached.
LaserDist can be downloaded here (it says it’s updated for KSP 1.11.x, but it works fine with 1.12.x too):
https://github.com/Dunbaratu/LaserDist/releases/tag/v1.4.0

## Table of Contents
[SCRIPTS FEATURES](#scripts-features)

INSTALLATION

 - Scripts installation
 
 - Ships installation
 
 - Directory structure
 
 - Possible conflicts
 
BEFORE YOU START

 - Set your screen resolution
 
 - Instructions per update
 
 - kOS HDD sizes
 
 - Script ID ('scriptid' variable)
 
 - Templates
 
 - Local ship files handling
 
 - Usage considerations
 
 - Development considerations
 
EXAMPLES

 - 'example.ks' - Example flight with example vessel
 
 - 'mkl.ks' - Copying scripts from Archive to ship's local volume
 
 - 'newname.ks' - Renaming ship and/or migrating configurations from old name to new name
 
 - Extra scripts, already usable in KSP gameplay
 


## SCRIPTS FEATURExS:

- Graphical input pane with pre-filled values, providing a means to enter and/or edit initial values for variables used within the functional parts of user scripts. The pane also provides the ability to save entered values as inputs automatically loaded at start, or even save various variants of inputs that can be easily selected and saved/loaded on script start.

- Basic Control Panel GUI, and more complex control panel GUIs with various controlling elements. More complex elements include combinations of buttons for easy increasing/decreasing of given values, popup menus to select various functionalities, etc. Complex panels can be minimized (hidden) and restored (shown again) to save screen space without affecting their operations, so the basic CP acts as a sort of task toolbar.

- Minipanels - specific-purpose-focused compact panels that can be invoked/revoked, for example, by a toggle-type button. Minipanels usually contain sets of small controlling parts and help reduce the number of controlling elements on main panels, keeping them clear and much easier to navigate.

- PID parameters (and/or any other scalar variables if needed) control panels for displaying/editing said parameters in real time during flight. Edited parameters can be saved under arbitrary names and loaded whenever needed during flight or automatically at script start.

- PID parameters (or other stuff if needed) stored in a separate *PID.include.ks file named by script ID and ship name combination. This file is easy to edit (in contrast to .json preset files) and serves as the source for PID parameters for a given script and ship. The file is initially created (after the first script run on a given ship) from a template for the given script.

- Save/Load mechanisms, mainly focused (but not limited to) various parameter sets - for example, different PIDs for the same vessel on different planets, etc.

- Basic orbital functions library for orbit circularization, orbit apsis change, maneuver execution, or crude reentry planning.

- Library for commonly used functions, like working with certain parts, helping with navigation, and any other stuff used across multiple scripts. Functions in this library will probably be mostly replaced and/or extended by users' own functions.

- CP scripts use kOS name tagging (dubbing) for individual parts to identify parts for certain actions. For example, engines named 'leng' identify "landing engines" where gimbal actions are performed, while other engines on the same vessel, not dubbed, are not involved in such actions. Naming of parts is set up in the VAB or SPH editor (right click → kOS → name tag:), or it can be done in flight as well in parts' right-click popup. Note that multiple parts should have the same name tag for given actions. For example, if the vessel has four landing engines, they all must have the name tag 'leng'. The exceptions are kOS processors, which should each have their own name so they can reference each other.
