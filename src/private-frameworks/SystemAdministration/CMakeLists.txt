project(SystemAdministration)

remove_sdk_framework(SystemAdministration
	PRIVATE
)

set(DYLIB_COMPAT_VERSION "1.0.0")
set(DYLIB_CURRENT_VERSION "1.0.0")

set(FRAMEWORK_VERSION "A")

generate_sdk_framework(SystemAdministration
    VERSION ${FRAMEWORK_VERSION}
    HEADER "include/SystemAdministration"
	PRIVATE
)

# These headers are not registered with `generate_sdk_framework`'s private-include
# machinery yet, so put the framework's own include directory on the search path.
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include")

add_framework(SystemAdministration
    FAT
    CURRENT_VERSION
    PRIVATE
    VERSION ${FRAMEWORK_VERSION}

    SOURCES
        src/ADMUser.m

    DEPENDENCIES
        system
        objc
        Foundation
)
