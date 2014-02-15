export ARCHS = arm64 armv7s armv7
export TARGET = iphone:7.0:7.0

include theos/makefiles/common.mk

TWEAK_NAME = IconFinder
IconFinder_FILES = Tweak.xm
IconFinder_FRAMEWORKS = UIKit
IconFinder_PRIVATE_FRAMEWORKS = Search

include $(THEOS_MAKE_PATH)/tweak.mk

before-package::
	plutil -convert binary1 _/Library/MobileSubstrate/DynamicLibraries/IconFinder.plist
	chmod 0644 _/Library/MobileSubstrate/DynamicLibraries/IconFinder.plist
	find _ -exec touch -r _/Library/MobileSubstrate/DynamicLibraries/IconFinder.dylib {} \;
	find _ -name ".*" -exec rm -f {} \;
	sudo chown -R 0:0 _

after-package::
	sudo chown -R merlin:staff _
	rm -fr .theos/packages/*
