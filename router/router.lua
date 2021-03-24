-- Routes itemstacks according to instructions received via Digilines.

-- Where unroutable items should be sent.
local unroutable = "yellow"

-- The channel used to communicate with this device.
local channel = "router:1"

-- ====== Digilines API =====
--
-- The router understands messages of table type. Within the table must be a
-- “command” key with string value identifying what is to be done. Valid
-- commands are as follows.
--
-- clear
--   Removes all routing table entries immediately.
--
-- query
--   Provokes a response message containing a summary of outstanding routing
--   requests. See the list of sent messages for details.
--
-- route
--   Requests that certain numbers of certain types of items be sent in certain
--   directions. The message must be an array whose array elements are the
--   individual routing requests to process; there is no functional difference
--   between submitting a single “route” command with many requests versus
--   submitting the requests one at a time.
--
--   Each request must be a table with keys “name” identifying the name of the
--   item to route, “count” indicating how many of the item should be routed,
--   “direction” identifying the direction in which the items should be sent,
--   and optionally “id” specifying an opaque value (which is not interpreted
--   by the router itself in any way) used to identify the request when
--   generating a “done” response.
--
--   If multiple requests are submitted for the same item in different
--   directions, their priority is unspecified—items will eventually be
--   delivered in the specified numbers to the specified destinations, but they
--   may arrive in any order.
--
--   If multiple requests are submitted for the same item in the same
--   direction, they are accumulated—their counts effectively add, and a single
--   large itemstack may satisfy multiple requests, but if the requests have
--   “id” keys, their counts are kept separate for accounting purposes so that
--   “done” replies can be generated at the proper times.
--
-- The router may send messages of table type. Within the table will be a
-- “response” key identifying the type of information. Valid replies are as
-- follows.
--
-- done
--   Reports that a routing table entry has been deleted because the specified
--   item count has been reached. The message contains an “id” key with the
--   identifier value provided in the routing request. Routing requests without
--   “id” keys do not generate “done” replies.
--
-- error
--   Reports that an itemstack entered the router and could not be routed
--   properly. The message contains “name” and “count” keys identifying the
--   itemstack that could not be routed. The “reason” key identifies why and is
--   either “unknown” if no requests at all are outstanding for the item type,
--   “toomany” if the item stack is larger than the sum of counts of all
--   outstanding requests for the item type, or “unsplittable” if the item
--   stack fits within the sum of counts of all outstanding requests but not
--   within the sum of counts for a single direction (and thus the item stack
--   needs to be split into smaller stacks to be routed properly). The stack
--   has been sent to the “unroutable” destination.
--
-- query_reply
--   In response to a “query” command, reports a summary of current routing
--   requests. The message contains an “items” key. The value of that key is a
--   table each of whose keys is an item name. The value of each such key is a
--   table each of whose keys is a direction (all six are always present). The
--   value of each such key is the number of items that have been requested to
--   be routed in that direction and have not yet passed the router.

-- “mem” must be a table; if it is not, then initialize it.
if type(mem) ~= "table" then
	mem = {}
end

-- Handle the event.
if event.type == "item" then
	-- Look up the item table for the incoming item.
	local item_table = mem[event.item.name]
	if item_table ~= nil then
		-- There is at least one routing table entry for this item. Choose a
		-- direction to send the stack.
		local direction = nil
		local all_directions_count = 0
		for candidate_direction, direction_data in pairs(item_table) do
			all_directions_count = all_directions_count + direction_data.total_count
			if event.item.count <= direction_data.total_count then
				direction = candidate_direction
			end
		end
		if direction ~= nil then
			-- Routing succeeded. Update accounting information and send
			-- completion notifications if possible.
			local direction_table = item_table[direction]
			direction_table.total_count = direction_table.total_count - event.item.count
			local count_remaining = event.item.count
			while count_remaining ~= 0 and direction_table.read ~= direction_table.write do
				local this_count = direction_table[direction_table.read].count
				local this_update = math.min(this_count, count_remaining)
				this_count = this_count - this_update
				count_remaining = count_remaining - this_update
				if this_count == 0 then
					-- This ID is now complete. Send a notification and remove
					-- the entry.
					local response = {
						response = "done",
						id = direction_table[direction_table.read].id,
					}
					digiline_send(channel, response)
					direction_table[direction_table.read] = nil
					direction_table.read = direction_table.read + 1
				else
					-- This ID is not finished yet. Update the stored count.
					direction_table[direction_table.read].count = this_count
				end
			end

			-- If all directions have counts of zero…
			local all_zero = true
			for _, direction_data in pairs(item_table) do
				all_zero = all_zero and direction_data.total_count == 0
			end
			-- … delete this item.
			if all_zero then
				mem[event.item.name] = nil
			end

			-- Send the stack to the selected direction.
			return direction
		elseif all_directions_count >= event.item.count then
			-- There are enough total requests to cover the item stack, but not
			-- in any single direction; it would need splitting which we cannot
			-- do.
			local error_message = {
				response = "error",
				name = event.item.name,
				count = event.item.count,
				reason = "unsplittable",
			}
			digiline_send(channel, error_message)
			return unroutable
		else
			-- There are more items than all requests for this item type.
			local error_message = {
				response = "error",
				name = event.item.name,
				count = event.item.count,
				reason = "toomany",
			}
			digiline_send(channel, error_message)
			return unroutable
		end
	else
		-- There are no entries for this item.
		local error_message = {
			response = "error",
			name = event.item.name,
			count = event.item.count,
			reason = "unknown",
		}
		digiline_send(channel, error_message)
		return unroutable
	end
elseif event.type == "digiline" and event.channel == channel then
	local command = event.msg.command
	if command == "route" then
		-- Add the routing table entries.
		for _, entry in ipairs(event.msg) do
			-- Find the routing table for the item name and direction.
			local item_name = entry.name
			local by_name = mem[item_name]
			if by_name == nil then
				by_name = {
					red = {
						total_count = 0,
						read = 1,
						write = 1,
					},
					blue = {
						total_count = 0,
						read = 1,
						write = 1,
					},
					yellow = {
						total_count = 0,
						read = 1,
						write = 1,
					},
					green = {
						total_count = 0,
						read = 1,
						write = 1,
					},
					black = {
						total_count = 0,
						read = 1,
						write = 1,
					},
					white = {
						total_count = 0,
						read = 1,
						write = 1,
					},
				}
				mem[item_name] = by_name
			end
			local by_dir = by_name[entry.direction]

			-- Add the total count.
			by_dir.total_count = by_dir.total_count + entry.count

			if entry.id ~= nil then
				-- Stash the ID for reporting completion.
				local index = by_dir.write
				by_dir[index] = {
					id = entry.id,
					count = entry.count,
				}
				by_dir.write = index + 1
			end
		end
	elseif command == "clear" then
		-- Destroy everything.
		mem = {}
	elseif command == "query" then
		-- Construct the response, including only the total counts for each
		-- item/direction and not the request ID details.
		local items = {}
		for item_name, item_table in pairs(mem) do
			local item = {}
			for direction, direction_table in pairs(item_table) do
				item[direction] = direction_table.total_count
			end
			items[item_name] = item
		end
		local response = {
			response = "query_reply",
			items = items,
		}
		digiline_send(channel, response)
	end
end
