LUA_OBJECTS=init.lua
NODEMCU_TOOL=nodemcu-uploader
FENNEL=fennel

default: $(LUA_OBJECTS)

%.lua: %.fnl
	$(FENNEL) --compile $< > $@

upload: $(LUA_OBJECTS)
	$(NODEMCU_TOOL) upload $^

terminal:
	$(NODEMCU_TOOL) terminal

clean:
	rm $(LUA_OBJECTS)

.PHONY: upload terminal clean default
