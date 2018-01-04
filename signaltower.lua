--[[

	Tubelib Smart Line
	==================

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	signaltower.lua:

]]--


local function switch_on(pos, node, color)
	node.name = "tubelib_smartline:signaltower_"..color
	minetest.swap_node(pos, node)
end	

local function switch_off(pos, node)
	node.name = "tubelib_smartline:signaltower"
	minetest.swap_node(pos, node)
end	

minetest.register_node("tubelib_smartline:signaltower", {
	description = "Tubelib Signal Tower",
	tiles = {
		'tubelib_smartline_signaltower_top.png',
		'tubelib_smartline_signaltower_top.png',
		'tubelib_smartline_signaltower.png',
	},

	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -5/32, -16/32, -5/32,  5/32,  16/32, 5/32},
		},
	},
	
	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "tubelib_smartline:signaltower")
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Tubelib Signal Tower "..number)
	end,

	on_rightclick = function(pos, node, clicker)
		if not minetest.is_protected(pos, clicker:get_player_name()) then
			switch_on(pos, node, "green")
		end
	end,

	after_dig_node = function(pos)
		tubelib.remove_node(pos)
	end,

	paramtype = "light",
	light_source = 0,	
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_glass_defaults(),
})

for _,color in ipairs({"green", "amber", "red"}) do
	minetest.register_node("tubelib_smartline:signaltower_"..color, {
		description = "Tubelib Signal Tower",
		tiles = {
			'tubelib_smartline_signaltower_top.png',
			'tubelib_smartline_signaltower_top.png',
			'tubelib_smartline_signaltower_'..color..'.png',
		},

		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{ -5/32, -16/32, -5/32,  5/32,  16/32, 5/32},
			},
		},
		on_rightclick = function(pos, node, clicker)
			if not minetest.is_protected(pos, clicker:get_player_name()) then
				switch_off(pos, node)
			end
		end,

		paramtype = "light",
		light_source = LIGHT_MAX,	
		sunlight_propagates = true,
		paramtype2 = "facedir",
		groups = {crumbly=0, not_in_creative_inventory=1},
		is_ground_content = false,
		sounds = default.node_sound_glass_defaults(),
		drop = "tubelib_smartline:signaltower",
	})
end

minetest.register_craft({
	output = "tubelib_smartline:signaltower",
	recipe = {
		{"dye:red",    "", ""},
		{"dye:orange", "default:glass", ""},
		{"dye:green",  "tubelib_addons2:wlanchip", ""},
	},
})

tubelib.register_node("tubelib_smartline:signaltower", {
	"tubelib_smartline:signaltower_green", 
	"tubelib_smartline:signaltower_amber", 
	"tubelib_smartline:signaltower_red"}, {
	on_recv_message = function(pos, topic, payload)
		local node = minetest.get_node(pos)
		if topic == "green" then
			switch_on(pos, node, "green")
		elseif topic == "amber" then
			switch_on(pos, node, "amber")
		elseif topic == "red" then
			switch_on(pos, node, "red")
		elseif topic == "off" then
			switch_off(pos, node)
		end
	end,
})		
