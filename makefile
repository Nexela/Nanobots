PACKAGE_NAME := $(shell cat info.json|jq -r .name)
VERSION_STRING := $(shell cat info.json|jq -r .version)
OUTPUT_NAME := $(PACKAGE_NAME)_$(VERSION_STRING)
BUILD_DIR := .build
OUTPUT_DIR := $(BUILD_DIR)/$(OUTPUT_NAME)
CONFIG = ./$(OUTPUT_DIR)/config.lua
MODS_DIRECTORY := ../.mods.15
##MOD_LINK := $(shell find $(MODS_DIRECTORY)/$(OUTPUT_NAME) -mindepth 1 -maxdepth 1 -type d)

PKG_COPY := $(wildcard *.md) $(wildcard .*.md) $(wildcard graphics) $(wildcard locale) $(wildcard sounds)

SED_FILES := $(shell find . -iname '*.json' -type f -not -path "./.*/*") $(shell find . -iname '*.lua' -type f -not -path "./.*/*")
PNG_FILES := $(shell find ./graphics -iname '*.png' -type f)

OUT_FILES := $(SED_FILES:%=$(OUTPUT_DIR)/%)

SED_EXPRS := -e 's/{{MOD_NAME}}/$(PACKAGE_NAME)/g'
SED_EXPRS += -e 's/{{VERSION}}/$(VERSION_STRING)/g'

##@luac -p $@
##@luacheck $@

all: clean

release: clean check package tag

optimized-release: clean check optimize-package

package-copy: $(PKG_DIRS) $(PKG_FILES)
	@mkdir -p $(OUTPUT_DIR)
ifneq ($(PKG_COPY),)
	@cp -r $(PKG_COPY) $(OUTPUT_DIR)
endif

$(OUTPUT_DIR)/%.lua: %.lua
	@mkdir -p $(@D)
	@sed $(SED_EXPRS) $< > $@


$(OUTPUT_DIR)/%: %
	@mkdir -p $(@D)
	@sed $(SED_EXPRS) $< > $@

link2:
	([ -d "$(MODS_DIRECTORY)/$(OUTPUT_NAME)" ]  && \
	echo "Junction does not need updating.") || \
	@[ -d "$(MODS_DIRECTORY)/$(PACKAGE_NAME)*" ] && \
	echo "Updating Junction" && \
	mv $(MODS_DIRCTORY)/$(PACKAGE_NAME)* $(MODS_DIRECTORY)/$(OUTPUT_NAME)

link:
	if test -d $(MODS_DIRECTORY)/$(PACKAGE_NAME)*; then \
		if test -d $(MODS_DIRECTORY)/$(OUTPUT_NAME); then \
			echo "Dont Update"; \
		else \
			echo "DO STUFF"; \
		fi \
	else \
		echo "No Target to Link"; \
	fi

tag:
	git tag -f v$(VERSION_STRING)

optimize1:
	for name in $(PNG_FILES); do \
		optipng -o8 $(OUTPUT_DIR)'/'$$name; \
	done

optimize2:
	@echo Please wait, Optimizing Graphics.
	@for name in $(PNG_FILES); do \
		pngquant --skip-if-larger -q --strip --ext .png --force $(OUTPUT_DIR)'/'$$name; \
	done

nodebug:
	@[ -e $(CONFIG) ] && \
	echo Removing debug switches from config.lua && \
	sed -i 's/^\(.*DEBUG.*=\).*/\1 false/' $(CONFIG) && \
	sed -i 's/^\(.*LOGLEVEL.*=\).*/\1 0/' $(CONFIG) && \
	sed -i 's/^\(.*loglevel.*=\).*/\1 0/' $(CONFIG) || \
	echo No Config Files

check:
	@luacheck .

package: package-copy $(OUT_FILES) nodebug
	@cd $(BUILD_DIR) && zip -rq $(OUTPUT_NAME).zip $(OUTPUT_NAME)
	@echo $(OUTPUT_NAME).zip ready

optimize-package: package-copy $(OUT_FILES) nodebug optimize2
	@cd $(BUILD_DIR) && zip -rq $(OUTPUT_NAME).zip $(OUTPUT_NAME)
	@echo $(OUTPUT_NAME).zip ready

clean:
	@rm -rf $(BUILD_DIR)
	@echo Removing Build Directory.
