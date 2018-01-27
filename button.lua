--[[

	SmartLine
	=========

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	button.lua:
	Derived from Tubelib button

]]--


local function switch_on(pos, node)
	node.name = "smartline:button_active"
	minetest.swap_node(pos, node)
	minetest.sound_play("button", {
			pos = pos,
			gain = 0.5,
			max_hear_distance = 5,
		})
	local meta = minetest.get_meta(pos)
	local own_num = meta:get_string("own_num")
	local numbers = meta:get_string("numbers")
	local cycle_time = meta:get_int("cycle_time")
	if cycle_time > 0 then 	-- button mode?
		minetest.get_node_timer(pos):start(cycle_time)
	end
	local placer_name = meta:get_string("placer_name")
	local clicker_name = nil
	if meta:get_string("public") == "false" then
		clicker_name = meta:get_string("clicker_name")
	end
	tubelib.send_message(numbers, placer_name, clicker_name, "on", own_num)
end

local function switch_off(pos)
	local node = minetest.get_node(pos)
	node.name = "smartline:button"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):stop()
	minetest.sound_play("button", {
			pos = pos,
			gain = 0.5,
			max_hear_distance = 5,
		})
	local meta = minetest.get_meta(pos)
	local own_num = meta:get_string("own_num")
	local numbers = meta:get_string("numbers")
	local placer_name = meta:get_string("placer_name")
	tubelib.send_message(numbers, placer_name, nil, "off", own_num)
end


minetest.register_node("smartline:button", {
	description = "SmartLine Button/Switch",
	inventory_image = "smartline_button_inventory.png",
	tiles = {
		-- up, down, right, left, back, front
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png^smartline_button_off.png",
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
		local own_num = tubelib.add_node(pos, "SmartLine:button")
		meta:set_string("own_num", own_num)
		meta:set_string("formspec", "size[5,6]"..
		"dropdown[0.2,0;3;type;switch,button 2s,button 4s,button 8s,button 16s;1]".. 
		"field[0.5,2;3,1;numbers;Insert destination block number(s);]" ..
		"checkbox[1,3;public;public;false]"..
		"button_exit[1,4;2,1;exit;Save]")
		meta:set_string("placer_name", placer:get_player_name())
		meta:set_string("public", "false")
		meta:set_int("cycle_time", 0)
		meta:set_string("infotext", "SmartLine Button "..own_num)
	end,

	on_receive_fields = function(pos, formname, fields, player)
		local meta = minetest.get_meta(pos)
		if tubelib.check_numbers(fields.numbers) then
			meta:set_string("numbers", fields.numbers)
			local own_num = meta:get_string("own_num")
			meta:set_string("infotext", "SmartLine Button "..own_num..", connected with block "..fields.numbers)
		else
			return
		end
		if fields.public then
			meta:set_string("public", fields.public)
		end
		local cycle_time = nil
		if fields.type == "switch" then
			cycle_time = 0
		elseif fields.type == "button 2s" then
			cycle_time = 2
		elseif fields.type == "button 4s" then
			cycle_time = 4
		elseif fields.type == "button 8s" then
			cycle_time = 8
		elseif fields.type == "button 16s" then
			cycle_time = 16
		end
		if cycle_time ~= nil then
			meta:set_int("cycle_time", cycle_time)
		end
		if fields.exit then
			meta:set_string("formspec", nil)
		end
	end,
	
	on_rightclick = function(pos, node, clicker)
		local meta = minetest.get_meta(pos)
		meta:set_string("clicker_name", clicker:get_player_name())
		switch_on(pos, node)
	end,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})


minetest.register_node("smartline:button_active", {
	description = "SmartLine Button/Switch",
	tiles = {
		-- up, down, right, left, back, front
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png^smartline_button_on.png",
	},

	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -6/32, -6/32, 14/32,  6/32,  6/32, 16/32},
		},
	},
	
	on_rightclick = function(pos, node, clicker)
		local meta = minetest.get_meta(pos)
		meta:set_string("clicker_name", clicker:get_player_name())
		if meta:get_int("cycle_time") == nil or meta:get_int("cycle_time") == 0 then
			switch_off(pos, node)
		end
	end,

	on_timer = switch_off,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_craft({
	output = "smartline:button",
	recipe = {
		{"", "", ""},
		{"dye:blue", "default:copper_ingot", "tubelib_addons2:wlanchip"},
		{"", "", ""},
	},
})


minetest.register_lbm({
	label = "[SmartLine] button update",
	name = "smartline:update",
	nodenames = {"tubelib_smartline:button"},
	run_at_every_load = true,
	action = function(pos, node)
		print("update tubelib_smartline:button")
		node.name = "smartline:button"
		minetest.swap_node(pos, node)
	end
})

