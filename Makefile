NAME := epkg
PLATFORM := macosx
SCHEMES := easypkg
TMP := $(TMPDIR)/$(NAME)
STAGE := $(TMP)/stage
APP := $(TMP)/Build/Products/Release

.PHONY: all clean $(SCHEMES)

all: $(SCHEMES)

$(SCHEMES):
	xcodebuild \
		-project $(NAME).xcodeproj \
		-scheme "$@" \
		-configuration Release \
		-sdk $(PLATFORM) \
		-arch arm64 \
		-arch x86_64 \
		-derivedDataPath $(TMP) \
		-skipPackagePluginValidation \
		CODE_SIGNING_ALLOWED=NO \
		ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO \
		ONLY_ACTIVE_ARCH=NO

	@rm -rf packages
	@rm -rf $(STAGE)
	@mkdir -p $(STAGE)
	@mv $(APP)/$@.app $(STAGE)

	@mkdir -p packages
	@cp -R $(STAGE)/$@.app packages/
	@cp $@/Resources/launch.sh packages/EasyPKG.app/Contents/MacOS/launch.sh
	@/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable launch.sh" "packages/$@.app/Contents/Info.plist"
	@zip -r packages/$(NAME).zip packages/$@.app

clean:
	@rm -rf packages
	@rm -rf $(TMP)
