local battery_boxes = "lv_batteries"
local supply_converter = "lv_converter"
local poll_interval = 10
local min_charge = 25
local max_charge = 75

if event.type == "program" or (event.type == "interrupt" and event.iid == "start") then
	-- Step 1: ask the battery boxes for their data.
	digiline_send(battery_boxes, "get")
	interrupt(1, "finish")
	mem.current = 0
	mem.total = 0
elseif event.type == "digiline" and event.channel == battery_boxes then
	-- Step 2: collect data from battery boxes.
	mem.current = mem.current + event.msg.charge
	mem.total = mem.total + event.msg.max_charge
elseif event.type == "interrupt" and event.iid == "finish" then
	-- Step 3: all data received; decide what to do and sleep until next update.
	local percent
	if mem.total ~= 0 then
		percent = mem.current * 100 / mem.total
	else
		percent = 0
	end
	if percent <= min_charge then
		digiline_send(supply_converter, "on")
	elseif percent >= max_charge then
		digiline_send(supply_converter, "off")
	end
	interrupt(poll_interval - 1, "start")
end
