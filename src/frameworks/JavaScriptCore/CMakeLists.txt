project(JavaScriptCore_stub)

set(DYLIB_COMPAT_VERSION "1.0.0")
set(DYLIB_CURRENT_VERSION "606.1.30")

set(FRAMEWORK_VERSION "A")

# Minimal JavaScriptCore so Xcode's GPUTools/MTLTools/SpriteKit can be loaded.
# The real engine lives in src/external/JavaScriptCore (COMPONENT_jsc); this stub
# only provides the symbols those binaries bind and fails gracefully when used.
add_framework(JavaScriptCore
	FAT
	CURRENT_VERSION
	VERSION ${FRAMEWORK_VERSION}

	SOURCES
		src/JSStubs.c
		src/JSClasses.m

	DEPENDENCIES
		system
		objc
		Foundation
)
