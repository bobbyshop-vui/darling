project(GameplayKit)

remove_sdk_framework(GameplayKit)

set(DYLIB_COMPAT_VERSION "1.0.0")
set(DYLIB_CURRENT_VERSION "1.0.0")

set(FRAMEWORK_VERSION "A")

generate_sdk_framework(GameplayKit
    VERSION ${FRAMEWORK_VERSION}
    HEADER "include/GameplayKit"
)

add_framework(GameplayKit
	FAT
	CURRENT_VERSION
	VERSION ${FRAMEWORK_VERSION}

	SOURCES
		src/GKComponent.m
		src/GKEntity.m
		src/GKNodeComponents.m
		src/GKScene.m
		src/GKGraphNode.m
		src/GKGraph.m
		src/GKObstacle.m
		src/GKObstacleGraph.m
		src/GKNoiseSource.m

	DEPENDENCIES
		system
		objc
		Foundation
)
