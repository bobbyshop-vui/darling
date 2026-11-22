project(CoreThemeDefinition)

set(DYLIB_COMPAT_VERSION "1.0.0")
set(DYLIB_CURRENT_VERSION "346.26.0")

add_framework(CoreThemeDefinition
	FAT
	CURRENT_VERSION
	PRIVATE
	VERSION A

	SOURCES
		src/CoreThemeDefinition.m

	DEPENDENCIES
		system
		objc
		Foundation
)
