--[[

	SmartLine
	=========

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	controller.lua:

]]--


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
		return flags[data.flag] == data.value 
	end,
	button_label = function(data) 
		return "f"..data.flag.."=="..(({"true", "false"})[data.value] or "?")
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
		flags[data.flag] = data.value 
	end,
	button_label = function(data) 
		return "f"..data.flag.."="..({"true", "false"})[data.value] 
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
		local bool = data.value == 1 and 1 or 0
		return inputs[data.number] == bool
	end,
	button_label = function(data) 
		return "i("..data.number..")=="..({"on", "off"})[data.value] 
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
		return timers[data.timer] == 0
	end,
	button_label = function(data) 
		return "t"..data.timer.." expired"
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
		timers[data.timer] = data.value 
	end,
	button_label = function(data) 
		return "t"..data.timer.."="..data.value 
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
			choices = "stopped,running,standby,blocked,faulty",
			default = 1,
		},
	},
	
	on_execute = function(data, flags, timers, inputs) 
		local state = ({"stopped", "running", "standby", "blocked"})[data.value]
		return SmartLine.send_request(data.number, nil, nil, "state", "") == state
	end,
	button_label = function(data) 
		local state = ({"stp", "run", "sby", "blk"})[data.value]
		return "state("..data.number..")=="..state
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
		local state = ({"full", "empty"})[data.value]
		return SmartLine.send_request(data.number, nil, nil, "fuel", nil) == state
	end,
	button_label = function(data) 
		local state = ({"f..", "e.."})[data.value]
		return "state("..data.number..")=="..state
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
		local color = ({"off", "green", "amber", "red"})[data.value]
		SmartLine.send_message(data.number, data.owner, nil, color, number)
	end,
	button_label = function(data) 
		local color = ({"off", "grn", "amb", "red"})[data.value]
		return "sig("..data.number..")="..color 
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
		local cmnd = data.value == 1 and "on" or "off"
		SmartLine.send_message(data.number, data.owner, nil, cmnd, number)
	end,
	button_label = function(data) 
		local state = ({"on", "off"})[data.value]
		return "cmnd("..data.number..")="..state 
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
		SmartLine.send_message(data.number, data.owner, nil, "row", data.text)
	end,
	button_label = function(data) 
		local color = ({"off", "grn", "amb", "red"})[data.value]
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
