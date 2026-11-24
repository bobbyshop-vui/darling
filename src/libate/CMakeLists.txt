project(ate)

# Stub of Apple's texture encoder library (libate). Xcode's GPUToolsServices links
# it for texture compression in the GPU debugger; no encoder is available, so
# at_encoder_create() reports failure.
set(DYLIB_INSTALL_NAME "/usr/lib/libate.dylib")
set(DYLIB_COMPAT_VERSION "1.0.0")
set(DYLIB_CURRENT_VERSION "1.13.8")

add_darling_library(ate SHARED
	src/ate.c
)
make_fat(ate)
target_link_libraries(ate system)
install(TARGETS ate DESTINATION libexec/darling/usr/lib)
