ARCHS = arm64
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = 34306jit

# Compiler Flags
$(TWEAK_NAME)_CCFLAGS = -std=c++17 -fno-rtti -DNDEBUG -Wall -Wno-unused-variable -Wno-unused-function -Wno-unused-value -fvisibility=hidden -Wno-error -Wno-nontrivial-memcall -Wno-module-import-in-extern-c
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Wall -Wno-unused-variable -Wno-unused-function -Wno-unused-value -fvisibility=hidden -Wno-error

# Frameworks
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation Security QuartzCore CoreGraphics CoreText AVFoundation Accelerate GLKit SystemConfiguration GameController

# Linker Flags (-undefined dynamic_lookup මගින් UIUtilities auto-link error එක වැළැක්වේ)
$(TWEAK_NAME)_LDFLAGS += -undefined dynamic_lookup Other/libdobby_fixed.a

# Source Files (Other/ ෆෝල්ඩරයේ ගොනුද compile කිරීමට එකතු කර ඇත)
$(TWEAK_NAME)_FILES = ImGuiDrawView.mm \
                      oxorany/oxorany.cpp \
                      $(wildcard Esp/*.mm) \
                      $(wildcard Esp/*.m) \
                      $(wildcard IMGUI/*.cpp) \
                      $(wildcard IMGUI/*.mm) \
                      $(wildcard Hosts/*.m) \
                      $(wildcard Other/*.mm) \
                      $(wildcard Other/*.m) \
                      $(wildcard Other/*.cpp) \
                      $(wildcard Other/*.c)

include $(THEOS_MAKE_PATH)/tweak.mk
