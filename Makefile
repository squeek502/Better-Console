CORE_FILES:=modinfo.lua $(wildcard modmain.lua) $(wildcard modworldgenmain.lua)
LIB_FILES:=

UTILITY_FILES:=scripts/ configurable.lua

MISC_FILES:=config.default.lua 


ICON_STEM:=$(shell lua -e 'io.write(dofile("modinfo.lua") or "")')
ICON_FILES:=$(if $(ICON_STEM),$(foreach suf,.tex .xml,$(ICON_STEM)$(suf)),)


FILES:=$(CORE_FILES) $(LIB_FILES) $(UTILITY_FILES) $(MISC_FILES) $(ICON_FILES)


STAGE_DIR:=workshop
.PHONY: dist clean stage


ZIPNAME:=$(notdir $(CURDIR)).zip

dist: $(ZIPNAME)

stage: $(FILES) | $(STAGE_DIR)
	for f in $^; do \
		mkdir -p "`dirname "$(STAGE_DIR)/$$f"`"; \
		cp -a "$$f" "$(STAGE_DIR)/$$f"; \
	done

$(STAGE_DIR):
	mkdir -p $@

clean:
	rm -rf $(ZIPNAME) $(STAGE_DIR)

$(ZIPNAME): $(FILES)
	( cd ..; zip -FS -8 "$(CURDIR)/$@" $(foreach f,$^,$(notdir $(CURDIR))/$(f)) )
