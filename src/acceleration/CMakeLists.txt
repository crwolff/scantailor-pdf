project(Acceleration)

include_directories(.)

if(ENABLE_OPENCL)
	add_subdirectory(opencl)
endif()

set(
	sources
	acceleration_config.h
	AccelerationPlugin.h
	AcceleratableOperations.h
	NonAcceleratedOperations.cpp NonAcceleratedOperations.h
	DefaultAccelerationProvider.cpp DefaultAccelerationProvider.h
)
source_group("Sources" FILES ${sources})
TRANSLATION_SOURCES(scantailor ${sources})

add_library(acceleration STATIC ${sources})
target_link_libraries(acceleration dewarping imageproc Qt5::Core Qt5::Gui)
