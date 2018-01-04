--[[

	Tubelib Smart Line
	==================

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	display.lua:
	Derived from tubelib button

]]--

  
  
display_lib.register_display_entity("tubelib_smartline:entity")

function display_update(pos, objref) 
	local meta = minetest.get_meta(pos)
	local text = meta:get_string("text") or ""
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

minetest.register_node("tubelib_smartline:display", {
	description = "Tubelib Display",
	inventory_image = 'tubelib_smartline_display_inventory.png',
	tiles = {"tubelib_smartline_display.png"},
	drawtype = "nodebox",
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "wallmounted",
	node_box = lcd_box,
	selection_box = lcd_box,
	light_source = 6,
	
	display_entities = {
		["tubelib_smartline:entity"] = { depth = 0.42,
			on_display_update = display_update},
	},

	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "tubelib_smartline:display")
		local meta = minetest.get_meta(pos)
		meta:set_string("number", number)
		meta:set_string("text", " \n \nMinetest\nTubelib Smart Tools\n \nDisplay\nNumber: "..number)
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
	output = "tubelib_smartline:display",
	recipe = {
		{"", "", ""},
		{"default:glass", "dye:green", "tubelib_addons2:wlanchip"},
		{"", "", ""},
	},
})

tubelib.register_node("tubelib_smartline:display", {}, {
	on_recv_message = function(pos, topic, payload)
		local node = minetest.get_node(pos)
		if topic == "text" then
			local meta = minetest.get_meta(pos)
			meta:set_string("text", payload)
			display_lib.update_entities(pos)
		elseif topic == "clear" then
			local meta = minetest.get_meta(pos)
			meta:set_string("text", "")
			display_lib.update_entities(pos)
		end
	end,
})		

