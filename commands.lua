--[[

	SmartLine
	=========

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	command.lua:
	
	Register all basic controller commands

]]--

smartline.register_condition("", {
	formspec = {},
	on_execute = function(data, flags, timers, inputs) end,
	button_label = function(data) return ""	end,
})

smartline.register_action("", {
	formspec = {},
	on_execute = function(data, flags, timers, inputs) end,
	button_label = function(data) return ""	end,
})


smartline.register_condition("true", {
	formspec = {},
	on_execute = function(data, flags, timers, inputs) 
		return true
	end,
	button_label = function(data) 
		return "true"
	end,
})

smartline.register_condition("false", {
	formspec = {},
	on_execute = function(data, flags, timers, inputs) 
		return false
	end,
	button_label = function(data) 
		return "false"
	end,
})

smartline.register_condition("flag test", {
	formspec = {
		{
			type = "textlist", 
			name = "flag",
			label = "flag",      
			choices = "f1,f2,f3,f4,f5,f6,f7,f8", 
			default = 1,
		},
		{
			type = "textlist", 
			name = "value", 
			label = "is", 
			choices = "true,false", 
			default = 1,
		},
	},
	on_execute = function(data, flags, timers, inputs) 
		return flags[data.flag.num] == data.value.text
	end,
	button_label = function(data) 
		return data.flag.text.."=="..data.value.text
	end,
})

smartline.register_action("flag set", {
	formspec = {
		{
			type = "textlist", 
			name = "flag",
			label = "set flag",      
			choices = "f1,f2,f3,f4,f5,f6,f7,f8", 
			default = 1,
		},
		{
			type = "textlist", 
			name = "value", 
			label = "to value", 
			choices = "true,false", 
			default = 1,
		},
	},
	on_execute = function(data, flags, timers, number) 
		flags[data.flag.num] = data.value.text
	end,
	button_label = function(data) 
		return data.flag.text.."="..data.value.text
	end,
})

smartline.register_condition("check input", {
	formspec = {
		{
			type = "field",
			name = "number",
			label = "input from node with number",
			default = "",
		},
		{
			type = "textlist",
			name = "value",
			label = "is",
			choices = "on,off",
			default = 1,
		},
	},
	on_execute = function(data, flags, timers, inputs) 
		return inputs[data.number] == data.value.text
	end,
	button_label = function(data) 
		return "i("..data.number..")=="..data.value.text 
	end,
})


smartline.register_condition("timer test", {
	formspec = {
		{
			type = "textlist", 
			name = "timer",
			label = "timer expired",
			choices = "t1,t2,t3,t4,t5,t6,t7,t8", 
			default = 1,
		},
	},
	on_execute = function(data, flags, timers, inputs) 
		return timers[data.timer.num] == 0
	end,
	button_label = function(data) 
		return data.timer.text.." expired"
	end,
})

smartline.register_action("timer start", {
	formspec = {
		{
			type = "textlist", 
			name = "timer",
			label = "start timer",      
			choices = "t1,t2,t3,t4,t5,t6,t7,t8", 
			default = 1,
		},
		{
			type = "field", 
			name = "value", 
			label = "value in sec.", 
			default = "",
		},
	},
	on_execute = function(data, flags, timers, number) 
		timers[data.timer.num] = data.value 
	end,
	button_label = function(data) 
		return data.timer.text.."="..data.value 
	end,
})

smartline.register_condition("Pusher state", {
	formspec = {
		{
			type = "field",
			name = "number",
			label = "state from Pusher with number",
			default = "",
		},
		{
			type = "textlist",
			name = "value",
			label = "is",
			choices = "stopped,running,standby,blocked,fault",
			default = 1,
		},
	},
	
	on_execute = function(data, flags, timers, inputs) 
		return tubelib.send_request(data.number, "state", "") == data.value.text
	end,
	button_label = function(data) 
		return "st("..data.number..")=="..string.sub(data.value.text, 1, 4).."."
	end,
})

smartline.register_condition("fuel state", {
	formspec = {
		{
			type = "field",
			name = "number",
			label = "fuel state from node with number",
			default = "",
		},
		{
			type = "textlist",
			name = "value",
			label = "is",
			choices = "full,empty",
			default = 1,
		},
	},
	
	on_execute = function(data, flags, timers, inputs) 
		return tubelib.send_request(data.number, "fuel", nil) == data.value.text
	end,
	button_label = function(data) 
		return "st("..data.number..")=="..data.value.text
	end,
})

smartline.register_action("Signal Tower command", {
	formspec = {
		{
			type = "field", 
			name = "number", 
			label = "set Signal Tower with number", 
			default = "",
		},
		{
			type = "textlist", 
			name = "value",
			label = "to color",      
			choices = "off,green,amber,red", 
			default = 1,
		},
	},
	on_execute = function(data, flags, timers, number) 
		tubelib.send_message(data.number, data.owner, nil, data.value.text, number)
	end,
	button_label = function(data) 
		return "sig("..data.number..","..data.value.text..")"
	end,
})

smartline.register_action("switch nodes on/off", {
	formspec = {
		{
			type = "field", 
			name = "number", 
			label = "set node with number", 
			default = "",
		},
		{
			type = "textlist", 
			name = "value",
			label = "to state",      
			choices = "on,off", 
			default = 1,
		},
	},
	on_execute = function(data, flags, timers, number) 
		tubelib.send_message(data.number, data.owner, nil, data.value.text, number)
	end,
	button_label = function(data) 
		return "cmnd("..data.number..","..data.value.text..")"
	end,
})

smartline.register_action("Display", {
	formspec = {
		{
			type = "field", 
			name = "number", 
			label = "output to Display with number", 
			default = "",
		},
		{
			type = "field", 
			name = "text",
			label = "the following text",      
			default = "",
		},
	},
	on_execute = function(data, flags, timers, number) 
		tubelib.send_message(data.number, data.owner, nil, "row", data.text)
	end,
	button_label = function(data) 
		return "dispay("..data.number..")"
	end,
})

if minetest.get_modpath("mail") and mail ~= nil then
	smartline.register_action("mail", {
		formspec = {
			{
				type = "field", 
				name = "text",
				label = "send the message",      
				default = "",
			},
		},
		on_execute = function(data, flags, timers, number) 
			mail.send("Server", data.owner, "[SmartLine Controller]", data.text)
		end,
		button_label = function(data) 
			return "mail(...)"
		end,
	})
end

smartline.register_action("chat", {
	formspec = {
		{
			type = "field", 
			name = "text",
			label = "send the message",      
			default = "",
		},
	},
	on_execute = function(data, flags, timers, number)
		minetest.chat_send_player(data.owner, "[SmartLine Controller] "..data.text)
	end,
	button_label = function(data) 
		return "chat(...)"
	end,
})

local function door_toggle(pos, owner, state)
	pos = minetest.string_to_pos("("..pos..")")
	print("pos", dump(pos))
	if pos then
		local door = doors.get(pos)
		print("door", dump(door))
		if door then
			local player = {
				get_player_name = function() return owner end,
			}
			print("player", dump(player))
			if state == "open" then
				door:open(player)
			elseif state == "close" then
				door:close(player)
			end
		end
	end
end

smartline.register_action("doors open/close", {
	formspec = {
		{
			type = "field", 
			name = "pos", 
			label = "door position like '123,7,-1200'", 
			default = "",
		},
		{
			type = "label", 
			name = "lbl1", 
			label = "Hint: use a marker stick to determine the door position", 
		},
		{
			type = "textlist", 
			name = "state",
			label = "set",      
			choices = "open,close", 
			default = 1,
		},
	},
	on_execute = function(data, flags, timers, number) 
		door_toggle(data.pos, data.owner, data.state.text)
	end,
	button_label = function(data) 
		return "door("..data.state.text..")"
	end,
})

