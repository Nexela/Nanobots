# Get the current name and version from info.json
PACKAGE_NAME := $(shell jq -r .name info.json)
PACKAGE_VERSION := $(shell jq -r .version info.json)
PACKAGE_FULL_NAME := $(PACKAGE_NAME)_$(PACKAGE_VERSION)
PACKAGE_FILE := $(PACKAGE_FULL_NAME).zip
CONFIG_FILE = ./$(OUTPUT_DIR)/config.lua

# Setup Build Directoy and Files
BUILD_DIR := .build
OUTPUT_DIR := $(BUILD_DIR)/$(PACKAGE_FULL_NAME)

PKG_FILES := $(wildcard *.md) $(wildcard *.txt) $(wildcard locale) $(wildcard sounds) $(wildcard info.json) $(wildcard thumbnail.png)
LUA_FILES += $(shell find . -iname '*.lua' -type f -not -path "./.*/*")
LUA_FILES := $(LUA_FILES:%=$(OUTPUT_DIR)/%)
PNG_FILES += $(shell find ./graphics -iname '*.png' -type f)
PNG_FILES := $(PNG_FILES:%=$(OUTPUT_DIR)/%)

all: clean package check zip

quick: package zip

clean:
	@echo Removing Build Directory.
	@rm -rf $(BUILD_DIR)

package: $(PNG_FILES) $(LUA_FILES) nodebug
	@echo 'Copying files'
	@mkdir -p $(OUTPUT_DIR)
	@cp -r $(PKG_FILES) $(OUTPUT_DIR)

$(OUTPUT_DIR)/%.png: %.png
	@mkdir -p $(@D)
	@cp -r $< $(OUTPUT_DIR)/$<
	@pngquant --skip-if-larger --quiet --ext .png --force $(OUTPUT_DIR)/$< || true

$(OUTPUT_DIR)/%.lua: %.lua
	@mkdir -p $(@D)
	@cp -r $< $(OUTPUT_DIR)/$<

nodebug:
	@[ -e $(CONFIG_FILE) ] && \
	echo Removing debug switches from config.lua && \
	sed -i 's/^\(.*DEBUG.*=\).*/\1 false/' $(CONFIG_FILE) && \
	sed -i 's/^\(.*LOGLEVEL.*=\).*/\1 0/' $(CONFIG_FILE) && \
	sed -i 's/^\(.*loglevel.*=\).*/\1 0/' $(CONFIG_FILE) || \
	echo No Config Files

#Download the luacheckrc file from the repo, remove the .build guard and check the file.
check:
	@curl -s -o ./$(BUILD_DIR)/luacheckrc.lua https://raw.githubusercontent.com/Nexela/Factorio-luacheckrc/master/.luacheckrc
	@sed -i 's/\('\''\*\*\/\.\*\/\*'\''\)/--\1/' ./$(BUILD_DIR)/luacheckrc.lua
	@luacheck ./$(OUTPUT_DIR) -q --codes --config ./$(BUILD_DIR)/luacheckrc.lua

zip:
	@cd $(BUILD_DIR) && zip -rq $(PACKAGE_FILE) $(PACKAGE_FULL_NAME) && mkdir artifacts && cp -r $(PACKAGE_FILE) artifacts/$(PACKAGE_FILE)
	@echo $(PACKAGE_FULL_NAME) ready

release:
	@echo Preparing Release
	@git checkout release && git merge master && git push && git checkout master
