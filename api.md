# SmartLine Controller API


The SmartLine Controller provides the following API to register additional conditions and actions from other mods:


* smartline.register_condition(name, condition definition)
* smartline.register_action(name, action definition)

The controller executes up to 10 rules every second. Each rule consists of:
- two condition functions 
- one logical operator (and/or)
- one action function

Depending on the operator, one or both condition functions have to return true, so that the action function is called.
If the action is called, the action related flag (a1..a10) is automatically set and can be used in  
subsequent rules to trigger further actions without the need to evaluate both conditions again.

The Controller supports the following variables:
- binary flags (f1..f8) to store states (true/false)
- timer variables (t1..t8), decremented each second. Used to execute actions time based
- input values (referenced via node number) to evaluate received commands (on/off) from other tubelib nodes
- action flags (a1..a10) )to store the action state from previous executed rules

`input` variables and `action` flags are deleted after each run. `flags` and `timer` variables are stored non volatile (as long as the controller is running).

Each registered condition and action has the function `on_execute`  which is called for each rule (every second).
* The condition function has to return true or false, depending if the condition is true or not
* The action function has to execute the defined action

In addition each registered condition and action has the function `button_label`, which determines the button label
for the Controller main formspec. Please note that the maximum number of visible characters for the button label is
something about 15.

See `commands.lua` as reference. All predefined SmartLine Controller commands are registered via `commands.lua`.

## Prototypes

```LUA
    smartline.register_condition("mymod;mycond", {
    	title = "this is my cond",
    	formspec = {},
    	on_execute = function(data, flags, timers, inputs, actions) 
    	-- data:    table with the formspec data 
    	-- flag:    table with the flag values
    	-- timers:  table with the timer values
    	-- inputs:  table with the input values
    	-- actions: table with the action values
    	end,
    	button_label = function(data) 
    	   return "button label"
    	end,
    })
```


```LUA
    smartline.register_action(name, {
    	title = "",
    	formspec = {},
    	on_execute = function(data, flags, timers, inputs) 
    	-- data:    table with the formspec data 
    	-- flag:    table with the flag values, see 
    	-- timers:  table with the timer values
    	-- inputs:  table with the input values
    	end,
    	button_label = function(data) 
    	   return "button label"
    	end,
    })
```
 
The formspec table defines the condition/action related form for additional user parameters.
It supports the following subset of the minetest formspec elements:

  - textlist
  - field
  - label

Please note that size and position is automatically determined.
All other attributes are according to the original formspec.
Example:

```LUA
	formspec = {
		{
			type = "field",                              -- formspec element
			name = "number",                             -- reference key for the table 'data' used in function `on_execute`
			label = "input from node with number",       -- label shown above of the element
			default = "",                                -- default value
		},
		{
			type = "textlist",
			name = "value",                              -- table 'data.value'
			label = "is",
			choices = "on,off",                          -- list elements
			default = 1,                                 -- first list element as default value
		},
		{
			type = "label",                      
			name = "lbl",                                -- not really used, but internally needed
			label = "Hint: Connect the input nodes with the controller", 
		},
```
 
 
 