-- Formats a value as a string, displaying the contents of tables.
local function deep_format(x, indent)
	if indent == nil then
		indent = 0
	end
	if type(x) == "table" then
		local ret = "{\n"
		for k, v in pairs(x) do
			ret = ret .. string.format("%s[%q] = %s,\n", string.rep("  ", indent + 1), k, deep_format(v, indent + 1))
		end
		ret = ret .. string.format("%s}", string.rep("  ", indent))
		return ret
	else
		return tostring(x)
	end
end

-- Compares two values for equality, recursively comparing tables by value.
--
-- If unordered is provided and is true, and x and y are tables, they must
-- contain the same set of values but their keys are ignored. This is not
-- recursive; sub-tables must still be exactly equal.
local function deep_equal(x, y, unordered)
	local tx = type(x)
	local ty = type(y)
	if tx ~= ty then
		return false
	elseif tx ~= "table" then
		return x == y
	else
		local x_cloned = {}
		for k, v in pairs(x) do
			x_cloned[k] = v
		end
		for k, v in pairs(y) do
			if unordered then
				local found = false
				for xk, xv in pairs(x) do
					if deep_equal(v, xv) then
						x_cloned[xk] = nil
						found = true
						break
					end
				end
				if not found then
					return false
				end
			else
				if not deep_equal(x_cloned[k], v) then
					return false
				end
				x_cloned[k] = nil
			end
		end
		return next(x_cloned) == nil
	end
end

-- Mock Digiline support.
local digiline_messages = {}
function digiline_send(channel, message)
	table.insert(digiline_messages, {
		channel = channel,
		message = message,
	})
end
local function expect_and_clear_digiline_messages(expected, unordered)
	assert(deep_equal(digiline_messages, expected, unordered),
		string.format("Expected digiline messages:\n%s\nGot:\n%s", deep_format(expected), deep_format(digiline_messages)))
	digiline_messages = {}
end
local function expect_and_clear_digiline_message(message, channel)
	return expect_and_clear_digiline_messages({{message = message, channel = channel}})
end
local function expect_no_digiline_messages()
	return expect_and_clear_digiline_messages({})
end

-- Load the UUT.
local uut = loadfile("router.lua")

-- Sends a query command and expects the specified “items” table in reply.
local function check_query(items)
	event = {
		type = "digiline",
		channel = "router:1",
		msg = {
			command = "query",
		},
	}
	uut()
	expect_and_clear_digiline_message({
		response = "query_reply",
		items = items,
	}, "router:1")
end

-- Sends in a stack of some number of an item. Returns the direction. Does not
-- check Digiline messages.
local function send_item(name, count)
	event = {
		type = "item",
		pin = "blue",
		itemstring = string.format("%s %d", name, count),
		item = {
			name = name,
			count = count,
			wear = 0,
		},
	}
	return uut()
end

-- Sends in a stack of some number of an item. Expects it to fail with the
-- specified error reason and be routed to the unroutable output (yellow).
local function send_item_check_error(name, count, reason)
	local dir = send_item(name, count)
	assert(dir == "yellow", string.format("Expected yellow, got %s", dir))
	expect_and_clear_digiline_message({
		response = "error",
		name = name,
		count = count,
		reason = reason,
	}, "router:1")
end

-- Sends the “route” command. Checks that no reply is sent back.
local function send_route(requests)
	event = {
		type = "digiline",
		channel = "router:1",
		msg = {
			command = "route",
		},
	}
	for k, v in ipairs(requests) do
		event.msg[k] = v
	end
	uut()
	expect_no_digiline_messages()
end

-- Send the “query” command. A query reply should come back with nothing.
check_query({})

-- Send the “query” command to a different channel. No reply should come back.
event = {
	type = "digiline",
	channel = "router:2",
	msg = {
		command = "query",
	},
}
uut()
expect_no_digiline_messages()

-- Send in a cobblestone. It should be sent to yellow and an “unknown” error issued.
send_item_check_error("default:cobblestone", 1, "unknown")

-- Request that one cobblestone be sent to red without completion reporting.
event = {
	type = "digiline",
	channel = "router:1",
	msg = {
		command = "route",
		{
			name = "default:cobblestone",
			count = 1,
			direction = "red",
		},
	},
}
uut()
expect_no_digiline_messages()

-- Send the “query” command. A query reply should come back reporting the
-- request.
check_query({
	["default:cobblestone"] = {
		red = 1,
		blue = 0,
		yellow = 0,
		green = 0,
		black = 0,
		white = 0,
	},
})

-- Send in a cobblestone. It should be sent to red and no messages should be
-- generated.
local actual = send_item("default:cobblestone", 1)
assert(actual == "red", string.format("Expected red, got %s", actual))
expect_no_digiline_messages()

-- Send the “query” command. A query reply should come back with nothing.
check_query({})

-- Send in a cobblestone. It should be sent to yellow and an “unknown” error issued.
send_item_check_error("default:cobblestone", 1, "unknown")

-- Request that one cobblestone be sent to red without completion reporting.
send_route({
	{
		name = "default:cobblestone",
		count = 1,
		direction = "red",
	}
})

-- Send the “query” command. A query reply should come back reporting the
-- request.
check_query({
	["default:cobblestone"] = {
		red = 1,
		blue = 0,
		yellow = 0,
		green = 0,
		black = 0,
		white = 0,
	},
})

-- Send in two cobblestone. They should be sent to yellow and a “toomany” error
-- issued.
send_item_check_error("default:cobblestone", 2, "toomany")

-- Request that one cobblestone be sent to white without completion reporting.
send_route({
	{
		name = "default:cobblestone",
		count = 1,
		direction = "white",
	},
})

-- Send the “query” command. A query reply should come back reporting the
-- request.
check_query({
	["default:cobblestone"] = {
		red = 1,
		blue = 0,
		yellow = 0,
		green = 0,
		black = 0,
		white = 1,
	},
})

-- Send in two cobblestone. They should be sent to yellow and an “unsplittable”
-- error issued.
send_item_check_error("default:cobblestone", 2, "unsplittable")

-- Send in two cobblestone one at a time. One should go to red and the other to
-- white, though the order is arbitrary, and no messages should be emitted.
actual = {}
table.insert(actual, send_item("default:cobblestone", 1))
table.insert(actual, send_item("default:cobblestone", 1))
assert(deep_equal(actual, {"red", "white"}, true),
	string.format("Expected {red, white} in either order, but got {%s, %s}", actual[1], actual[2]))
expect_no_digiline_messages()

-- Send the “query” command. There should be no items.
check_query({})

-- Request that one cobblestone be sent to white with a report ID, a second
-- cobblestone be sent to white with a different report ID, and two cobblestone
-- be sent to red with a single report ID.
send_route({
	{
		name = "default:cobblestone",
		count = 1,
		direction = "white",
		id = "foo",
	},
	{
		name = "default:cobblestone",
		count = 1,
		direction = "white",
		id = "bar",
	},
	{
		name = "default:cobblestone",
		count = 2,
		direction = "red",
		id = "baz",
	},
})

-- Send the “query” command. The totals in each direction should be reported.
check_query({
	["default:cobblestone"] = {
		red = 2,
		blue = 0,
		yellow = 0,
		green = 0,
		black = 0,
		white = 2,
	},
})

-- Send in four cobblestone one at a time. Record the reports generated in each
-- case.
actual = {}
for _ = 1, 4 do
	table.insert(actual, string.format("route:%s", send_item("default:cobblestone", 1)))
	for _, message in ipairs(digiline_messages) do
		assert(message.channel == "router:1")
		assert(message.message.response == "done")
		table.insert(actual, string.format("done:%s", message.message.id))
	end
	digiline_messages = {}
end
-- One of these possible outcomes is expected.
local expected = {
	-- WWRR
	{"route:white", "done:foo", "route:white", "done:bar", "route:red", "route:red", "done:baz"},
	-- WRRW
	{"route:white", "done:foo", "route:red", "route:red", "done:baz", "route:white", "done:bar"},
	-- RRWW
	{"route:red", "route:red", "done:baz", "route:white", "done:foo", "route:white", "done:bar"},
	-- RWWR
	{"route:red", "route:white", "done:foo", "route:white", "done:bar", "route:red", "done:baz"},
	-- WRWR
	{"route:white", "done:foo", "route:red", "route:white", "done:bar", "route:red", "done:baz"},
	-- RWRW
	{"route:red", "route:white", "done:foo", "route:red", "done:baz", "route:white", "done:bar"},
}
local any_found = false
for _, v in ipairs(expected) do
	any_found = any_found or deep_equal(actual, v)
end
assert(any_found, "Event ordering was not any of the legal options:\n%s", deep_format(actual))

-- Send the “query” command. A query reply should come back with nothing.
check_query({})
