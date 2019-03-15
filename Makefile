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

slideshow:
	cd slides; python -m http.server

.PHONY: upload terminal clean default slideshow
