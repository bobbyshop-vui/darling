project(MetalTools)

remove_sdk_framework(MetalTools
	PRIVATE
)

set(DYLIB_COMPAT_VERSION "1.0.0")
set(DYLIB_CURRENT_VERSION "1.0.0")

set(FRAMEWORK_VERSION "A")

generate_sdk_framework(MetalTools
    VERSION ${FRAMEWORK_VERSION}
    HEADER "include/MetalTools"
	PRIVATE
)

# These headers are not registered with `generate_sdk_framework`'s private-include
# machinery yet, so put the framework's own include directory on the search path.
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include")

add_framework(MetalTools
    FAT
    CURRENT_VERSION
    PRIVATE
    VERSION ${FRAMEWORK_VERSION}

    SOURCES
        src/MTLToolsObject.m

    DEPENDENCIES
        system
        objc
        Foundation
)
