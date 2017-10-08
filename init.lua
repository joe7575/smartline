--[[

	Tubelib Addons 2
	================

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	2017-09-08  v0.01  first version
	2017-09-17  v0.02  harvester added
	2017-10-02  v0.03  fermenter and reformer added
	2017-10-08  v0.04  Mesecons Converter and Programmer Tool added

]]--

if tubelib.version >= 0.06 then
	dofile(minetest.get_modpath("tubelib_addons2") .. "/timer.lua")
	dofile(minetest.get_modpath("tubelib_addons2") .. "/repeater.lua")
	dofile(minetest.get_modpath("tubelib_addons2") .. "/programmer.lua")
	if mesecon then
		dofile(minetest.get_modpath("tubelib_addons2") .. "/mesecons_converter.lua")
	end
else
	print("[tubelib_addons2] Version 0.06+ of Tubelib Mod is required!")
end