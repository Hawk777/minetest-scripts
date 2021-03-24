codes = true
stds.sandboxcommon = {
	globals = {
		"mem",
	},
	read_globals = {
		"assert",
		"error",
		"ipairs",
		"next",
		"pairs",
		"select",
		"tonumber",
		"tostring",
		"type",
		"unpack",
		"_VERSION",
		"event",
		"heat",
		"heat_max",
		"print",
		"interrupt",
		"digiline_send",
		string = {
			fields = {
				"byte",
				"char",
				"format",
				"len",
				"lower",
				"upper",
				"rep",
				"reverse",
				"sub",
				"find",
			},
		},
		math = {
			fields = {
				"abs",
				"acos",
				"asin",
				"atan",
				"atan2",
				"ceil",
				"cos",
				"cosh",
				"deg",
				"exp",
				"floor",
				"fmod",
				"frexp",
				"huge",
				"ldexp",
				"log",
				"log10",
				"max",
				"min",
				"modf",
				"pi",
				"pow",
				"rad",
				"random",
				"sin",
				"sinh",
				"sqrt",
				"tan",
				"tanh",
			},
		},
		table = {
			fields = {
				"concat",
				"insert",
				"maxn",
				"remove",
				"sort",
			},
		},
		os = {
			fields = {
				"clock",
				"difftime",
				"time",
				"datetable",
			},
		},
	},
}

stds.sandboxcommonwriteable = {
	globals = {
		"mem",
	},
}
for k, v in pairs(stds.sandboxcommon.read_globals) do
	stds.sandboxcommonwriteable.globals[k] = v
end

stds.luacontroller = {
	globals = {
		port = {
			fields = {"a", "b", "c", "d"},
		},
	},
	read_globals = {
		pin = {
			fields = {"a", "b", "c", "d"},
		},
	},
}

stds.luacontrollerwriteable = {
	globals = {
		port = {
			fields = {"a", "b", "c", "d"},
		},
		pin = {
			fields = {"a", "b", "c", "d"},
		},
	},
}

stds.combinescript = {
	read_globals = {
		"require",
	}
}

files["*.lua"].std = "sandboxcommon+luacontroller+combinescript"
files["test-*.lua"].std = "sandboxcommonwriteable+luacontrollerwriteable+luajit"
