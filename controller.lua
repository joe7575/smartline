--[[

	SmartLine
	=========

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	controller.lua:

]]--


local NUM_RULES = 10

local mail_exists = minetest.get_modpath("mail") and mail ~= nil
 
local sHELP = [[SmartLine Controller Help

Control other nodes by means of rules, according to:
    IF <cond1> and/or <cond2> THEN <action>

These rules allow to execute actions based on conditions.
Examples for conditions are:
 - the Player Detector detects a player
 - a button is pressed
 - a node state is fault, blocked, standby,...
 - a timer is expired 
 
Actions are:
 - switch on/off tubelib nodes, like lamps, door blocks, machines
 - send mail/chat messages to the owner
 - output a text message to the display
 - set timer variables 
 - set/reset flag variables
 
The controller supports 8 timers (resolution in seconds) 
and 8 flags (can be set true/false)

Each Rule stands for its own, but flags can be used 
to store conditions for subsequent rules.
The controller executes all rules once per second. 
All flags are cleared after each run.
Timers can be used to trigger rules on subsequent 
controller runs.

All actions are only executed once. The conditions
has to become false and then true again, to trigger
the action again.

The 'label' has no function. It is only used
to better distinguish rules.

Edit command examples:
 - 'x 1 8'  exchange rows 1 with row 8
 - 'c 1 2'  copy row 1 to 2
 - 'd 3'    delete row 3
]]

local sOUTPUT = "Press 'help' for edit commands" 
 
--
-- Helper functions
--
local function create_arr(elem, num) 
	local a = {}
	for i = 1,num do
		table.insert(a, elem)
	end
	return a
end

local function create_kv_list(elem) 
	local a = {}
	for i,v in ipairs(elem) do
		a[v] = i
	end
	return a
end

local function formspec_event(eventBindings, fields)
	for key,value in pairs(fields) do
		if value ~= nil and eventBindings[key] ~= nil then
			eventBindings[key](key, value)
		end
	end
end


--
-- Conditions
--

-- tables with all data from condition/action registrations
local kvRegisteredConditions = {}
local kvRegisteredActions = {}

-- lookup table to get the key behind the textlist index
local aConditionTypes = {}
local aActionTypes = {}

-- table with runtime functions
local CondRunTimeHandlers = {}
local ActnRunTimeHandlers = {}


local function eval_cond(data, flags, timers, inputs)
	return CondRunTimeHandlers[data.__idx__](data, flags, timers, inputs) and 1 or 0
end

local function exec_action(data, flags, timers, number)
	ActnRunTimeHandlers[data.__idx__](data, flags, timers, number)
end

smartline = {}

--
-- API functions for condition/action registrations
--
function smartline.register_condition(name, tData)
	table.insert(CondRunTimeHandlers, tData.on_execute)
	table.insert(aConditionTypes, name)
	tData.__idx__ = #aConditionTypes
	kvRegisteredConditions[name] = tData
	for _,item in ipairs(tData.formspec) do
		if item.type == "textlist" then
			item.tChoices = string.split(item.choices, ",")
			item.num_choices = #item.tChoices
		end
	end
end

function smartline.register_action(name, tData)
	table.insert(ActnRunTimeHandlers, tData.on_execute)
	table.insert(aActionTypes, name)
	tData.__idx__ = #aActionTypes
	kvRegisteredActions[name] = tData
	for _,item in ipairs(tData.formspec) do
		if item.type == "textlist" then
			item.tChoices = string.split(item.choices, ",")
			item.num_choices = #item.tChoices
		end
	end
end


--
-- Formspec
--

-- Determine the selected submenu and return the corresponding
-- formspec definition.
-- postfix: row/culumn info like "11" or "a2"
-- type: "cond" or "actn"
-- fs_data: formspec data

local function get_active_subm_definition(postfix, type, fs_data)
	local idx = 1
	local fs_definition = {}
	if type == "cond" then
		idx = fs_data["subm"..postfix.."_cond"] or 1
		local key = aConditionTypes[idx]
		fs_definition = kvRegisteredConditions[key]
	elseif type == "actn" then
		idx = fs_data["subm"..postfix.."_actn"] or 1
		local key = aActionTypes[idx]
		fs_definition = kvRegisteredActions[key]
	end
	return idx, fs_definition
end

-- Extract runtime relevant data from the given submenu 
-- postfix: row/culum info like "11" or "a2"
-- fs_definition: submenu formspec definition
-- fs_data: formspec data
local function get_subm_data(postfix, fs_definition, fs_data)
	local data = {}
	for idx,elem in ipairs(fs_definition.formspec) do
		if elem.type == "field" then	
			data[elem.name] = fs_data["subm"..postfix.."_"..elem.name] or "?"
		elseif elem.type == "textlist" then	
			local num = tonumber(fs_data["subm"..postfix.."_"..elem.name]) or 1
			num = math.min(num, elem.num_choices)
			data[elem.name] = {text = elem.tChoices[num], num = num}
		end
	end
	-- type of the condition/action
	data.__idx__ = fs_definition.__idx__
	return data
end

-- Copy field/formspec data to the table fs_data
-- fs_definition: submenu formspec definituion
-- fields: formspec input
-- fs_data: formspec data
local function field2fs_data(fs_definition, fields, fs_data)
	for idx,elem in ipairs(fs_definition.formspec) do
		local key = "subm"..fields._postfix_.."_"..elem.name
		if elem.type == "field" then	
			if fields[elem.name] then
				fs_data[key] = fields[elem.name]
			end
		elseif elem.type == "textlist" then	
			local evt = minetest.explode_textlist_event(fields[elem.name])
			if evt.type == "CHG" then
				fs_data[key] = evt.index
			end
		end
		if fs_data[key] == nil then
			fs_data[key] = elem.default
		end
	end
	return fs_data
end

local function add_controls_to_table(tbl, postfix, fs_data, fs_definition)
	local val = ""
	local offs = 2.4
	for idx,elem in ipairs(fs_definition.formspec) do
		tbl[#tbl+1] = "label[0,"..offs..";"..elem.label..":]"
		if elem.type == "field" then
			val = fs_data["subm"..postfix.."_"..elem.name] or elem.default
			tbl[#tbl+1] = "field[0.3,"..(offs+0.7)..";8.2,1;"..elem.name..";;"..val.."]"
			offs = offs + 1.5
		elseif elem.type == "textlist" then
			val = fs_data["subm"..postfix.."_"..elem.name] or elem.default
			tbl[#tbl+1] = "textlist[0.0,"..(offs+0.5)..";8,1.4;"..elem.name..";"..elem.choices..";"..val.."]"
			offs = offs + 2.4
		elseif elem.type == "label" then
			offs = offs + 0.6
		end
	end
	return tbl
end

local function runtime_data(postfix, type, fs_data)
	local _,fs_definition = get_active_subm_definition(postfix, type, fs_data)
	return get_subm_data(postfix, fs_definition, fs_data)
end

local function decrement_timers(timers)
	for idx,_ in ipairs(timers) do
		timers[idx] = timers[idx] - 1
	end
end


--
-- Condition formspec
--
local function formspec_cond(_postfix_, fs_data)
	local tbl = {"size[8.2,10]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"field[0,0;0,0;_type_;;cond]"..
		"field[0,0;0,0;_postfix_;;".._postfix_.."]"}
	
	local sConditions = table.concat(aConditionTypes, ",")
	local cond_idx, fs_definition = get_active_subm_definition(_postfix_, "cond", fs_data)
	tbl[#tbl+1] = "label[0,0.1;Condition type:]"
	tbl[#tbl+1] = "textlist[0,0.6;8,1.4;cond;"..sConditions..";"..cond_idx.."]"
	tbl = add_controls_to_table(tbl, _postfix_, fs_data, fs_definition)
	tbl[#tbl+1] = "button[6,9.4;1.5,1;_exit_;ok]"
	return table.concat(tbl)
end

-- evaluate the row condition
local function eval_formspec_cond(meta, fs_data, fields)
	-- determine condition type
	local cond = minetest.explode_textlist_event(fields.cond)
	if cond.type == "CHG" then
		fs_data["subm"..fields._postfix_.."_cond"] = cond.index
	end
	-- prepare data
	local _, fs_definition = get_active_subm_definition(fields._postfix_, "cond", fs_data)
	fs_data = field2fs_data(fs_definition, fields, fs_data)
	local data = get_subm_data(fields._postfix_, fs_definition, fs_data)
	-- update button for main menu
	fs_data["cond"..fields._postfix_] = fs_definition.button_label(data)
	
	if fields._exit_ == nil then
		-- update formspec if exit is not pressed
		meta:set_string("formspec", formspec_cond(fields._postfix_, fs_data))
	end
	return fs_data
end
	

--
-- Action formspec
--
local function formspec_actn(_postfix_, fs_data)
	local tbl = {"size[8.2,10]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"field[0,0;0,0;_type_;;actn]"..
		"field[0,0;0,0;_postfix_;;".._postfix_.."]"}
	
	local sActions = table.concat(aActionTypes, ",")
	local actn_idx, fs_definition = get_active_subm_definition(_postfix_, "actn", fs_data)
	tbl[#tbl+1] = "label[0,0.1;Action type:]"
	tbl[#tbl+1] = "textlist[0,0.6;8,1.4;actn;"..sActions..";"..actn_idx.."]"
	tbl = add_controls_to_table(tbl, _postfix_, fs_data, fs_definition)
	tbl[#tbl+1] = "button[6,9.4;1.5,1;_exit_;ok]"
	return table.concat(tbl)
end

-- evaluate the row action
local function eval_formspec_actn(meta, fs_data, fields)
	-- determine action type
	local actn = minetest.explode_textlist_event(fields.actn)
	if actn.type == "CHG" then
		fs_data["subm"..fields._postfix_.."_actn"] = actn.index
	end
	-- prepare data
	local _, fs_definition = get_active_subm_definition(fields._postfix_, "actn", fs_data)
	fs_data = field2fs_data(fs_definition, fields, fs_data)
	local data = get_subm_data(fields._postfix_, fs_definition, fs_data)
	-- update button for main menu
	fs_data["actn"..fields._postfix_] = fs_definition.button_label(data)
	
	if fields._exit_ == nil then
		-- update formspec if exit is not pressed
		meta:set_string("formspec", formspec_actn(fields._postfix_, fs_data))
	end
	return fs_data
end


--
-- Label text formspec
--
local function formspec_label(_postfix_, fs_data)
	--print(dump(fs_data))
	local label = fs_data["label".._postfix_] or "<any text>"
	return "size[6,4]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"field[0,0;0,0;_type_;;label]"..
		"field[0,0;0,0;_postfix_;;".._postfix_.."]"..
		"label[0.2,0.3;Label:]"..
		"field[0.3,1.5;5,1;label;;"..label.."]"..
		"button[4.5,3;1.5,1;_exit_;ok]"
end

-- evaluate the row label
local function eval_formspec_label(meta, fs_data, fields)
	--print("label", dump(fields))
	fs_data["subml"..fields._postfix_.."_label"] = fields.label
	if fields._exit_ == nil then
		meta:set_string("formspec", formspec_label(fields._postfix_, fs_data))
	end
	-- set the button label of the main menu based on the given input in the submenu
	fs_data["label"..fields._postfix_] = fs_data["subml"..fields._postfix_.."_label"]
	return fs_data
end


--
-- Operand formspec
--
local function formspec_oprnd(_postfix_, fs_data)
	local oprnd = fs_data["submo".._postfix_.."_oprnd"] or ""
	return "size[6,4]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"field[0,0;0,0;_type_;;oprnd]"..
		"field[0,0;0,0;_postfix_;;".._postfix_.."]"..
		"label[0.2,0.3;Operand:]"..
		"textlist[0,0.8;5.6,1.4;oprnd;or,and;"..oprnd.."]"..
		"button[4.5,3;1.5,1;_exit_;ok]"
end

-- evaluate the row operand
local function eval_formspec_oprnd(meta, fs_data, fields)
	--print("label", dump(fields))
	local oprnd = minetest.explode_textlist_event(fields.oprnd)
	if oprnd.type == "CHG" then
		fs_data["submo"..fields._postfix_.."_oprnd"] = oprnd.index
	end
	if fields._exit_ == nil then
		meta:set_string("formspec", formspec_oprnd(fields._postfix_, fs_data))
	end
	-- set the button label of the main menu based on the given input in the submenu
	fs_data["oprnd"..fields._postfix_] = fs_data["submo"..fields._postfix_.."_oprnd"] == 1 and "or" or "and"
	return fs_data
end

local function formspec_main(state, fs_data, output)
	local tbl = {"size[13,10;true]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"field[0,0;0,0;_type_;;main]"..
		"label[0.8,0;label:]label[3.3,0;IF  cond 1:]label[6,0;and/or]label[7.3,0;cond 2:]label[10.2,0;THEN  action:]"}
		
	for idx = 1,NUM_RULES do
		local ypos = idx * 0.8 - 0.4
		tbl[#tbl+1] = "label[0,"..(0.2+ypos)..";"..idx.."]"
		tbl[#tbl+1] = "button[0.4,"..ypos..";2.5,1;label"..idx..";"..(fs_data["label"..idx] or "...").."]"
		tbl[#tbl+1] = "button[3,"..  ypos..";2.9,1;cond1"..idx..";"..(fs_data["cond1"..idx] or "...").."]"
		tbl[#tbl+1] = "button[6,"..  ypos..";1,1;oprnd"..  idx..";"..(fs_data["oprnd"..idx] or "or").."]"
		tbl[#tbl+1] = "button[7,"..  ypos..";2.9,1;cond2"..idx..";"..(fs_data["cond2"..idx] or "...").."]"
		tbl[#tbl+1] = "button[10,".. ypos..";2.9,1;actna"..idx..";"..(fs_data["actna"..idx] or "...").."]"
	end
	tbl[#tbl+1] = "image_button[12,9;1,1;".. tubelib.state_button(state) ..";button;]"
	tbl[#tbl+1] = "button[10.2,9;1.5,1;help;help]"
	tbl[#tbl+1] = "label[0.2,8.8;"..output.."]"
	tbl[#tbl+1] = "field[0.4,9.6;4.8,1;cmnd;;<cmnd>]"
	tbl[#tbl+1] = "button[5,9.3;1,1;ok;OK]"
	return table.concat(tbl)
end

local function eval_formspec_main(meta, fs_data, fields)
	--print("main", dump(fields))
	for idx = 1,NUM_RULES do
		-- eval standard inputs
		fs_data["oprnd"..idx] = fields["oprnd"..idx] or fs_data["oprnd"..idx]
		
		-- eval submenu button events
		if fields["label"..idx] then
			meta:set_string("formspec", formspec_label(idx, fs_data))
		elseif fields["cond1"..idx] then
			meta:set_string("formspec", formspec_cond("1"..idx, fs_data))
		elseif fields["cond2"..idx] then
			meta:set_string("formspec", formspec_cond("2"..idx, fs_data))
		elseif fields["oprnd"..idx] then
			meta:set_string("formspec", formspec_oprnd(idx, fs_data))
		elseif fields["actna"..idx] then
			meta:set_string("formspec", formspec_actn("a"..idx, fs_data))
		end
	end	
	return fs_data
end

local function formspec_help(offs)
	return "size[13,10]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"field[0,0;0,0;_type_;;help]"..
		"label[0,"..(-offs/50)..";"..sHELP.."]"..
		--"label[0.2,0;test]"..
		"scrollbar[11.5,1;0.5,7;vertical;sb_help;"..offs.."]"..
		"button[11.5,9;1.5,1;close;close]"
end

local function execute(meta, number, debug)
	--print("elapsed", elapsed)
	local rt_rules = tubelib.get_data(number, "rt_rules")
	local inputs = tubelib.get_data(number, "inputs")
	local actions = tubelib.get_data(number, "actions")
	local timers = tubelib.get_data(number, "timers")
	decrement_timers(timers)
	local flags = {}
	for i,item in ipairs(rt_rules) do
		if eval_cond(item.cond1, flags, timers, inputs) + eval_cond(item.cond2, flags, timers, inputs) >= item.cond_cnt then
			--print("exec rule", i)
			if actions[i] == false then
				-- execute action
				exec_action(item.actn, flags, timers, number)
			end
			actions[i] = true
		else
			actions[i] = false
		end
	end
	tubelib.set_data(number, "rt_rules", rt_rules)
	tubelib.set_data(number, "inputs", {})
	tubelib.set_data(number, "actions", actions)
end

local function check_rules(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	local state = meta:get_int("state")
	if state == tubelib.RUNNING and number then
		execute(meta, number, debug)
	end
	return true
end

local function switch_state(pos, state, fs_data)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	meta:set_int("state", state)
	meta:set_string("formspec", formspec_main(state, fs_data, sOUTPUT))
	if state == tubelib.RUNNING then
		meta:set_string("infotext", "SmartLine Controller "..number..": running")
		minetest.get_node_timer(pos):start(1)
	else
		meta:set_string("infotext", "SmartLine Controller "..number..": stopped")
		minetest.get_node_timer(pos):stop()
	end
end

local function start_controller(pos, number, fs_data)
	tubelib.set_data(number, "timers", create_arr(0, NUM_RULES))  -- local timers
	tubelib.set_data(number, "inputs", {}) 	-- for rx commands
	tubelib.set_data(number, "actions", create_arr(false, NUM_RULES))  -- for action states
	switch_state(pos, tubelib.RUNNING, fs_data)
end

local function stop_controller(pos, fs_data)
	switch_state(pos, tubelib.STOPPED, fs_data)
end

local function formspec2runtime_rule(number, owner, fs_data)
	local rt_rules = {}
	local num2inp = {}
	for idx = 1,NUM_RULES do
		-- valid rule?
		if fs_data["subm1"..idx.."_cond"] and fs_data["subm2"..idx.."_cond"] 
		and fs_data["subma"..idx.."_actn"] then
			-- add to list of runtine rules
			local rule = {
				cond_cnt = fs_data["oprnd"..idx] == "and" and 2 or 1,
				cond1 = runtime_data("1"..idx, "cond", fs_data),
				cond2 = runtime_data("2"..idx, "cond", fs_data),
				actn  = runtime_data("a"..idx, "actn", fs_data),
			}
			rule.actn.owner = owner
			table.insert(rt_rules, rule)
		end
	end 
	tubelib.set_data(number, "rt_rules", rt_rules)
	print("rt_rules", dump(rt_rules))
end


local function get_keys(fs_data)
	-- collect all keys and remove row information
	local keys = {}
	for k,v in pairs(fs_data) do
		local key = string.sub(k,1,5).."*"..string.sub(k, 7)
		if type(v) == 'number' then
			keys[key] = 1  -- default value
		else
			keys[key] = "..."  -- default value
		end
	end
	return keys
end

local function exchange_rules(fs_data, pos1, pos2)
	-- exchange elem by elem
	for k,v in pairs(get_keys(fs_data)) do
		local k1 = string.gsub(k, "*", pos1)
		local k2 = string.gsub(k, "*", pos2)
		local temp = fs_data[k1] or v
		fs_data[k1] = fs_data[k2] or v
		fs_data[k2] = temp
	end
	return fs_data
end

local function copy_rule(fs_data, pos1, pos2)
	-- copy elem by elem
	for k,v in pairs(get_keys(fs_data)) do
		local k1 = string.gsub(k, "*", pos1)
		local k2 = string.gsub(k, "*", pos2)
		fs_data[k2] = fs_data[k1] or v
	end
	return fs_data
end

local function delete_rule(fs_data, pos)
	for k,v in pairs(get_keys(fs_data)) do
		local k1 = string.gsub(k, "*", pos)
		fs_data[k1] = nil
	end
	return fs_data
end

local function edit_command(fs_data, text)
	local cmnd, pos1, pos2 = text:match('^(%S)%s(%d+)%s(%d+)$')
	if pos2 == nil then
		cmnd, pos1 = text:match('^(%S)%s(%d+)$')
	end
	if cmnd and pos1 and pos2 then
		if cmnd == "x" then 
			exchange_rules(fs_data, pos1, pos2) 
			return "rows "..pos1.." and "..pos2.." exchanged"
		end
		if cmnd == "c" then
			copy_rule(fs_data, pos1, pos2) 
			return "row "..pos1.." copied to "..pos2
		end
	elseif cmnd == "d" and pos1 then
		delete_rule(fs_data, pos1)
		return "row "..pos1.." deleted"
	end
	return "Invalid command '"..text.."'"
end

local function 	on_receive_fields(pos, formname, fields, player)
	print("fields", dump(fields))
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	if not player or not player:is_player() then
		return
	end
	if player:get_player_name() ~= owner then
		return
	end
	local fs_data = minetest.deserialize(meta:get_string("fs_data")) or {}
	local output = ""
	if fields.ok then	
		output = edit_command(fs_data, fields.cmnd)
		meta:set_string("formspec", formspec_main(tubelib.STOPPED, fs_data, output))
	end
	if fields._type_ == "main" then
		fs_data = eval_formspec_main(meta, fs_data, fields)
	elseif fields._type_ == "label" then
		fs_data = eval_formspec_label(meta, fs_data, fields)
	elseif fields._type_ == "cond" then
		fs_data = eval_formspec_cond(meta, fs_data, fields)
	elseif fields._type_ == "oprnd" then
		fs_data = eval_formspec_oprnd(meta, fs_data, fields)
	elseif fields._type_ == "actn" then
		fs_data = eval_formspec_actn(meta, fs_data, fields)
	elseif fields._type_ == "help" then
		meta:set_string("formspec", formspec_main(tubelib.STOPPED, fs_data, sOUTPUT))
	end
	meta:set_string("fs_data", minetest.serialize(fs_data))
	
	if fields._exit_ then
		meta:set_string("formspec", formspec_main(tubelib.STOPPED, fs_data, sOUTPUT))
		stop_controller(pos, fs_data)
	elseif fields.help then
		stop_controller(pos, fs_data)
		meta:set_string("formspec", formspec_help(1))
	elseif fields.sb_help then
		local evt = minetest.explode_scrollbar_event(fields.sb_help)
		if evt.type == "CHG" then
			meta:set_string("formspec", formspec_help(evt.value))
		end
	elseif fields.button then
		local number = meta:get_string("number")
		local state = meta:get_int("state")
		if state == tubelib.RUNNING then
			stop_controller(pos, fs_data)
			meta:set_string("formspec", formspec_main(tubelib.STOPPED, fs_data, sOUTPUT))
		else
			formspec2runtime_rule(number, owner, fs_data)
			start_controller(pos, number, fs_data)
			meta:set_string("formspec", formspec_main(tubelib.RUNNING, fs_data, sOUTPUT))
		end
		
	end
end

minetest.register_node("smartline:controller", {
	description = "SmartLine Controller",
	inventory_image = "smartline_controller_inventory.png",
	wield_image = "smartline_controller_inventory.png",
	stack_max = 1,
	tiles = {
		-- up, down, right, left, back, front
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png^smartline_controller.png",
	},

	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -6/32, -6/32, 14/32,  6/32,  6/32, 16/32},
		},
	},
	
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		local number = tubelib.add_node(pos, "smartline:controller")
		local fs_data = {}
		meta:set_string("fs_data", minetest.serialize(fs_data)) 
		meta:set_string("owner", placer:get_player_name())
		meta:set_string("number", number)
		meta:set_int("state", tubelib.STOPPED)
		meta:set_int("debug", 0)
		meta:set_string("formspec", formspec_main(tubelib.STOPPED, fs_data, sOUTPUT))
		meta:set_string("infotext", "SmartLine Controller "..number..": stopped")
	end,

	on_receive_fields = on_receive_fields,
	
	on_dig = function(pos, node, puncher, pointed_thing)
		if minetest.is_protected(pos, puncher:get_player_name()) then
			return
		end
		
		local meta = minetest.get_meta(pos)
		local state = meta:get_int("state")
		if state ~= tubelib.STOPPED then
			return
		end
			
		minetest.node_dig(pos, node, puncher, pointed_thing)
		tubelib.remove_node(pos)
	end,
	
	on_timer = check_rules,
	
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=1, cracky=1, crumbly=1},
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
})


minetest.register_craft({
	output = "smartline:controller",
	recipe = {
		{"",         "default:mese_crystal", ""},
		{"dye:blue", "default:copper_ingot", "tubelib:wlanchip"},
		{"",         "default:mese_crystal", ""},
	},
})


local function set_input(meta, payload, val)
	if payload then 
		local number = meta:get_string("number")
		local inputs = tubelib.get_data(number, "inputs")
		if inputs then
			inputs[payload] = val
			tubelib.set_data(number, "inputs", inputs)
		end
	end
end	

tubelib.register_node("smartline:controller", {}, {
	on_recv_message = function(pos, topic, payload)
		local meta = minetest.get_meta(pos)
		if topic == "on" then
			set_input(meta, payload, topic)
		elseif topic == "off" then
			set_input(meta, payload, topic)
		elseif topic == "state" then
			local state = meta:get_int("state")
			return tubelib.statestring(state)
		else
			return "unsupported"
		end
	end,
})		
