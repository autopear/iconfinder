export ARCHS = arm64 armv7
export TARGET = iphone:9.2:7.0

include theos/makefiles/common.mk

TWEAK_NAME = IconFinder
IconFinder_FILES = Tweak.xm
IconFinder_FRAMEWORKS = UIKit
IconFinder_PRIVATE_FRAMEWORKS = Search SpotlightUI
IconFinder_LDFLAGS = -weak_framework SearchUI
IconFinder_LDFLAGS += -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/tweak.mk

before-package::
	plutil -convert binary1 $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/IconFinder.plist
	chmod 0644 $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/IconFinder.plist
	find $(THEOS_STAGING_DIR) -exec touch -r $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/IconFinder.dylib {} \;
	find $(THEOS_STAGING_DIR) -name ".*" -exec rm -f {} \;

after-package::
	rm -fr .theos/packages/*
