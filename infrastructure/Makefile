ALL_SOURCES := $(filter-out combined.lua,$(wildcard *.lua))
MAIN_SOURCE := main.lua
TEST_SOURCES := $(filter test-%.lua,$(ALL_SOURCES))
MODULE_SOURCES := $(filter-out $(MAIN_SOURCE) $(TEST_SOURCES),$(ALL_SOURCES))

.PHONY : world
world : combined.lua

combined.lua : $(MAIN_SOURCE) $(MODULE_SOURCES) ../infrastructure/combine
	../infrastructure/combine $(MAIN_SOURCE) $(MODULE_SOURCES) > $@

.PHONY : check
check : luacheck $(TEST_SOURCES:test-%.lua=check-%)

.PHONY : luacheck
luacheck : $(ALL_SOURCES)
	luacheck $+

.PHONY : $(TEST_SOURCES:test-%.lua=check-%)
$(TEST_SOURCES:test-%.lua=check-%) : check-% : $(ALL_SOURCES)
	luajit $(@:check-%=test-%.lua)

.PHONY : clean
clean :
	$(RM) combined.lua

.DELETE_ON_ERROR :
