# SmartLine \[smartline\]

This tubelib extension provides small and smart sensors, actors and controllers.

![SmartLine](https://github.com/joe7575/smartline/blob/master/screenshot.png)

The most interesting node of SmartLine is the SmartLine Controller, a 'computer' to control and monitor Tubelib based machines.
You don't need any programming skills, it is more like a configuration according to the "IF this THEN that" concept:

    IF <cond1> OR <cond2> THEN <action>
    IF <cond1> AND <cond2> THEN <action>
    
Examples for conditions are:
 - the Player Detector detects a player
 - a button is pressed
 - a node state is fault, blocked, standby,...
 - a timer is expired 

Examples for actions ate:
 - switch on/off tubelib nodes, like lamps, door blocks, machines
 - send mail/chat messages to the owner
 - output a text message to the display
 - set timer variables 
 - set/reset flag variables

The mod comes with several new nodes, all in a smart and small housing:
 - a Player Detector, sending on/off commands to connected nodes
 - a Smart Button, sending on/off commands to connected nodes
 - a Display for text outputs of the controller
 - a Signal Tower, with green, amber, red lights to signal error/fault states
 - a Timer (derived from Tubelib Addons2), for daytime based actions
 - a Sequencer (derived from Tubelib Addons2), for time triggered actions (time in seconds)


API Reference: ![api.md](https://github.com/joe7575/smartline/blob/master/api.md)



Browse on: ![GitHub](https://github.com/joe7575/smartline)

Download: ![GitHub](https://github.com/joe7575/smartline/archive/master.zip)


## Dependencies
tubelib, default, doors  
optional: display_lib, font_lib, mail  

# License
Copyright (C) 2018 Joachim Stolberg  
Code: Licensed under the GNU LGPL version 2.1 or later. See LICENSE.txt and http://www.gnu.org/licenses/lgpl-2.1.txt  
Textures: CC0

