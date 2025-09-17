NAME := EasyPKG
PLATFORM := macosx
SCHEMES := EasyPKG
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
	@zip -r packages/$(NAME).zip packages/$@.app

clean:
	@rm -rf packages
	@rm -rf $(TMP)
