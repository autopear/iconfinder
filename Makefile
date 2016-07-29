export ARCHS = arm64 armv7
export TARGET = iphone:9.2:7.0

include theos/makefiles/common.mk

TWEAK_NAME = IconFinder
IconFinder_FILES = Tweak.xm
IconFinder_FRAMEWORKS = UIKit
IconFinder_PRIVATE_FRAMEWORKS = Search SpotlightUI

include $(THEOS_MAKE_PATH)/tweak.mk

before-package::
	plutil -convert binary1 _/Library/MobileSubstrate/DynamicLibraries/IconFinder.plist
	chmod 0644 _/Library/MobileSubstrate/DynamicLibraries/IconFinder.plist
	find _ -exec touch -r _/Library/MobileSubstrate/DynamicLibraries/IconFinder.dylib {} \;
	find _ -name ".*" -exec rm -f {} \;

after-package::
	rm -fr .theos/packages/*
