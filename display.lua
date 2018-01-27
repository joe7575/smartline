--[[

	SmartLine
	=========

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	display.lua:

]]--

  
  
display_lib.register_display_entity("smartline:entity")

function display_update(pos, objref) 
	local meta = minetest.get_meta(pos)
	local text = meta:get_string("text") or ""
	text = string.gsub(text, "|", " \n")
	local texture = font_lib.make_multiline_texture(
		"default", text,
		120, 120, 9, "top", "#000")
	objref:set_properties({ textures = {texture},
							visual_size = {x=0.94, y=0.94} })
end


local lcd_box = {
	type = "wallmounted",
	wall_top = {-8/16, 15/32, -8/16, 8/16, 8/16, 8/16}
}

minetest.register_node("smartline:display", {
	description = "SmartLine Display",
	inventory_image = 'smartline_display_inventory.png',
	tiles = {"smartline_display.png"},
	drawtype = "nodebox",
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "wallmounted",
	node_box = lcd_box,
	selection_box = lcd_box,
	light_source = 6,
	
	display_entities = {
		["smartline:entity"] = { depth = 0.42,
			on_display_update = display_update},
	},

	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "smartline:display")
		local meta = minetest.get_meta(pos)
		meta:set_string("number", number)
		meta:set_string("text", " \n \nMinetest\nSmartLine Smart Tools\n \nDisplay\nNumber: "..number)
		meta:set_int("startscreen", 1)
		display_lib.update_entities(pos)
	end,

	on_place = display_lib.on_place,
	on_construct = display_lib.on_construct,
	on_destruct = display_lib.on_destruct,
	on_rotate = display_lib.on_rotate,
	groups = {cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_glass_defaults(),
})


minetest.register_craft({
	output = "smartline:display",
	recipe = {
		{"", "", ""},
		{"default:glass", "dye:green", "tubelib_addons2:wlanchip"},
		{"", "default:copper_ingot", ""},
	},
})

local function add_row(meta, payload)
	local text = meta:get_string("text")
	local rows
	if meta:get_int("startscreen") == 1 then
		rows = {}
		meta:set_int("startscreen", 0)
	else
		rows = string.split(text, "|")
	end
	if #rows > 8 then
		table.remove(rows, 1)
	end
	table.insert(rows, payload)
	text = table.concat(rows, "|")
	meta:set_string("text", text)
end

tubelib.register_node("smartline:display", {}, {
	on_recv_message = function(pos, topic, payload)
		local node = minetest.get_node(pos)
		if topic == "text" then
			local meta = minetest.get_meta(pos)
			meta:set_string("text", payload)
			display_lib.update_entities(pos)
		elseif topic == "row" then
			local meta = minetest.get_meta(pos)
			add_row(meta, payload)
			display_lib.update_entities(pos)
		elseif topic == "clear" then
			local meta = minetest.get_meta(pos)
			meta:set_string("text", "")
			display_lib.update_entities(pos)
		end
	end,
})		

