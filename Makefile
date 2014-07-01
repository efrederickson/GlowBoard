ARCHS = armv7 arm64
THEOS_PACKAGE_DIR_NAME = debs

TWEAK_NAME = GlowBoard
GlowBoard_FILES = Tweak.xm
GlowBoard_FRAMEWORKS = UIKit QuartzCore CoreGraphics CoreImage

include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
SUBPROJECTS += glowboardsettings
include $(THEOS_MAKE_PATH)/aggregate.mk
