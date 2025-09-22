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

[INSTALLATION](#installation)

 - [Scripts installation](#scripts-installation)
 
 - [Ships installation](#ships-installation)
 
 - [Directory structure](#directory-structure)

 
[BEFORE YOU START](#before-you-start)

 - [Set your screen resolution](#set-your-screen-resolution)
 
 - [Instructions per update](#instructions-per-update)
 
 - [kOS HDD sizes](#kos-hdd-sizes)
 
 - [Script ID ('scriptid' variable)](#script-id)
 
 - [Templates](#templates)
 
 - [Local ship files handling](#local-ship-files-handling)
 
 - [Usage considerations](#usage-considerations)
 
 - [Development considerations](#development-considerations)
 
EXAMPLES

 - 'example.ks' - Example flight with example vessel
 
 - 'mkl.ks' - Copying scripts from Archive to ship's local volume
 
 - 'newname.ks' - Renaming ship and/or migrating configurations from old name to new name
 
 - Extra scripts, already usable in KSP gameplay
 


## SCRIPTS FEATURES
- Graphical input parameters pane with pre-filled values. This pane is displayed on script start (unless inapplicable, like 'getlogs.ks' or 'mkl.ks') and provides a means to enter and/or edit initial values for variables used within the functional parts of user scripts. The pane also provides the ability to save entered values as inputs automatically loaded at start, or even save various variants of inputs that can be easily selected and saved/loaded on script start.

- Basic Control Panel GUI, and more complex control multipanel GUIs with various controlling elements. These elements include combinations of buttons for easy increasing/decreasing of given values, popup menus to select various functionalities, textboxes for displaying messages and tooltips, etc. Complex panels can be minimized (hidden) and restored (shown again) to save screen space without affecting their operations, so the basic CP acts as a sort of task toolbar.

- Minipanels - purpose-specific compact panels that can be invoked/revoked, for example, by a toggle-type button. Minipanels usually contain sets of small control elements and help reduce the number of controlling elements on main panels, keeping them clear and much easier to navigate.

- Mechanism for easy tooltips usage to maintain descriptions of individual functions and control elements.

- PID parameters (and/or any other scalar variables if needed) control panels for displaying/editing said parameters in real time during the flight. Edited parameters can be saved under arbitrary preset names and loaded whenever needed during flight or automatically at script start. Save/Load mechanisms are mainly focused on (but not limited to) various parameter sets - for example, different PIDs for the same vessel on different planets, etc.

- PID parameters (or other stuff if needed) stored in a separate *PID.include.ks file named by script ID and ship name combination. This file is easy to edit (in contrast to .json preset files) and serves as the source for PID parameters for a given script and ship. The file is initially created (after the first script run on a given ship) from a template for the given script.

- Basic orbital functions library for orbit circularization, orbit apsis change, maneuver execution, or crude reentry planning.

- Library for commonly used functions, like working with certain parts, helping with navigation, and any other stuff used across multiple scripts. Functions in this library will probably be mostly replaced and/or extended by users' own functions.

- CP scripts use kOS name tagging (dubbing) for individual parts to identify parts for certain actions. For example, engines named 'leng' identify "landing engines" where gimbal actions are performed, while other engines on the same vessel, not dubbed, are not involved in such actions. Naming of parts is set up in the VAB or SPH editor (right click → kOS → name tag:), or it can be done in flight as well in parts' right-click popup. Note that multiple parts should have the same name tag for given actions. For example, if the vessel has four landing engines, they all must have the name tag 'leng'. The exceptions are kOS processors, which should each have their own name so they can reference each other.

[back to TOC](#table-of-contents)

## INSTALLATION

### Scripts installation

Simply unpack ControlPanelScripts.zip into the kOS archive directory, usually [KSP installation folder]/Ships/Script/. It is also a good idea to back up your 'Script' directory beforehand, just to be sure.  
There should be no file collisions, but in the very improbable case you have some of your scripts named the same as some of the CP scripts, rename the problematic CP script, but DO CHANGE the variable 'scriptid' at the beginning of the script accordingly (see Script ID below).

### Ships installation

Unpack CPShips.zip or CPShips_noLaser.zip into your save's VAB Ships directory. This package contains example vessels to work with included example scripts. All vessels were created without any other parts mods than kOS and LaserDist. Vessels in CPShips_noLaser.zip are variants without LaserDist mod parts.

### Directory structure

Directory structure of CP scripts adds two subdirectories to the kOS default directory:

lib - Subdirectory containing libraries which are included by 'runoncepath' commands in main scripts.

etc - Subdirectory for saved settings and presets. By default, for each vessel running CP scripts, its own subdirectory in 'etc' is created named by the vessel's name.

etc/templates - Contains templates for each script which will be used to create the initial *PID.include.ks file after the script's first start (the template is simply copied to the ship's subdirectory as a file with a given name following the ship-script naming convention).

boot - Standard kOS subdirectory containing scripts loaded on boot. The CP scripts package contains script 'archive.ks' which (when set as boot file) switches the terminal to archive filesystem after launch or switching to a given vessel. Its usage is optional, according to your preferences.

[back to TOC](#table-of-contents)

## BEFORE YOU START

### Set your screen resolution
Before you begin working with scripts, set the parameters of your screen resolution in the 'etc/settings.lib.ks' file. This is necessary for the initial GUI positions to be placed correctly.
Open the file in a text editor and find the following section:


global currsets is lexicon(
"mainx",list(1920,"maximum x screen resolution"),
"mainy",list(1080,"maximum y screen resolution"),


Replace 1920 with your X screen resolution and 1080 with your Y screen resolution (if you know how to get actual resolution parameters directly in kOS, please let me know).
CP scripts use the global settings lexicon 'currsets' (current settings) defined in the 'settings.lib.ks' library. It contains the initial screen positions (some of them computed relative to other 'currsets' settings, e.g., the screen's X and Y resolutions), box styles, terminal window width and height, some default colors, and some other default values.
Settings are either read from this lexicon (in the 'settings.lib.ks' library), or can be overridden by a *_settings.json file. This is still experimental, so all you need for now is the 'settings.lib.ks' library and you don't need to worry about it (besides the initial setting of screen resolution, as described above).

In case you do care about settings, here is more information:
File 'all_settings.json' replaces settings for all scripts regardless of 'scriptid' and the vessel's name. This file is saved directly in the 'etc' subdirectory. It is read first in the sequence.
File 'scriptid_settings.json' (where scriptid is the actual ID of a given script) replaces settings for the script with the 'scriptid' identifier. This file is saved directly in the 'etc' subdirectory. It is read second in the sequence.
File 'shipname_scriptid_settings.json' (shipname is the actual ship's name, scriptid is the actual ID of a given script) replaces settings for the script with the 'scriptid' identifier running on the ship with 'shipname'. This file is saved in the 'etc/shipname' subdirectory. It is read third in the sequence.
The library 'settings.lib.ks' (which must be included first, at the beginning of each CP script) looks for all settings files in the given order and prints 'File not found' if the file is not there. That is not an error message.

### Instructions per update
kOS has limitation settings that control how many instructions are run per KSP update. The more instructions, the smoother the script runs (more instructions are performed) at a certain cost to KSP performance. The default IPU value is 200, which is quite low for kOS scripts using complex GUIs (you can literally see them redrawing). Please use higher values, at least 500 or as many as your PC can handle. The IPU can be changed in kOS settings, or from within scripts (all but 'getlogs.ks' and 'mkl.ks' have a button for it).

### kOS HDD sizes
When placing kOS processors on your vessel, use full HDD sizes for kOS CPUs. The KAL9000 with a fully upgraded disk is the best option. Libraries are quite long and they contain a lot of comments. If needed, you can mass remove comments (e.g., using Notepad++) to decrease file sizes.

### Script ID
Each script must have its 'scriptid' variable set to the script's name (without .ks extension). The 'scriptid' variable is crucial for file operations (configurations, settings, saves and loads) to work correctly.

### Templates
If no template for a given script exists in the 'etc/templates' subdirectory, the script creates an empty include file in the ship's configuration subdirectory. This file must be manually edited before it works.

### Local ship files handling
'mkl.ks' script
For scripts running on the ship's local filesystem, all necessary libraries and settings need to be copied from archive, along with the script itself. To easily copy scripts from archive to local filesystems, use the GUI-based 'mkl.ks' script, usage described below.
'newname.ks' script
It is crucial for the ship's saved and configuration files to be placed under the correctly named subdirectory with correctly constructed filenames. If you want to rename your ship, or the ship is renamed by KSP, for example, after undocking or separation, use the simple interactive command line utility 'newname.ks'. This utility automatically migrates all the ship's configuration into the new location. The utility's usage is described below.

### Usage considerations
Scripts do not work well with the 'RemoteTech' mod due to long-distance time delay. The kOS GUI reacts to button presses as if they were issued remotely even if the button press is invoked from within the script (which is used pretty often). Hence, waiting for the time delay will occur every time the function is invoked by a 'set buttonname:press to true.' call somewhere in the code. Of course, for usage over short distances, where delay is minimal, scripts work well (Minmus is the furthest I tested). Also, crewed/droned vessels work correctly regardless of distance.

Setting some parameters during script run to certain values can be fatal, since it can invoke invalid operations. For example, an attempt to divide by zero or calling a function out of its bounds. Not all variables are checked for validity, although setting those variables to invalid values usually does not make sense.

Losing some part during the flight (e.g., after bumping into something) can cause the script to crash, if it refers to lost parts. Not all parts are checked for presence constantly.

### Development considerations
Some library functions rely on the presence of global variables in main script, so do pay attention to the naming of your own global variable identifiers. Always check if they are not already present and used in some of the libraries. If you use an existing variable identifier in global context, script(s) may not work as intended. Of course, you can use library global variables for your purposes. For example, 'screen.lib.ks' uses 'on' triggers for checking RCS and SAS status change to toggle 'RCS' and 'SAS' buttons if defined, presuming they are created as global variables named 'rcsbtn' and 'sasbtn' respectively.
For example, you can use the Notepad++ 'Find in Files' function with descent into subdirectories to check for the presence of variables. Check used library function comments (and code) for more information.

kOS remembers some variables set within the script after it ends. This can mislead you when you change your code and re-run the script. Certain variables can seem to be defined and the script will not crash due to their non-existence (referring to a variable before it was created). The safest (but also annoying) way to avoid this is to reboot the kOS terminal (with the 'reboot.' command), so do it from time to time to check if all variable declarations are in order (if you know a better way please let me know. I know there is the 'unset' command, but unsetting all variables one by one is not really a good way).

[back to TOC](#table-of-contents)


.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
dummy EOF
