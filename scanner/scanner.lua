-- Where passing items should be sent.
local output_direction = "yellow"

-- The channel to which item-passing messages should be sent, each of which is
-- an itemstack in table form.
local channel = "scanner:1"

if event.type == "item" then
	digiline_send(channel, event.item)
	return output_direction
end
