-- The channel for this I/O expander.
local channel = ""

if event.type == "on" or event.type == "off" then
	digiline_send(channel, pin)
elseif event.type == "digiline" and event.channel == channel then
	if event.msg == "GET" then
		digiline_send(channel, pin)
	else
		port = event.msg
	end
end
