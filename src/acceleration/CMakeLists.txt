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

if(NOT BUILD_STATIC)
	add_definitions(-DSHARED_ACCELERATION)
	add_definitions(-DBUILDING_ACCELERATION)
endif()

add_library(acceleration ${MAYBE_STATIC} ${sources})
target_link_libraries(acceleration dewarping imageproc Qt5::Core Qt5::Gui)

if(NOT STATIC_BUILD)
	# We want the DLL located where executables can find it.
	set_target_properties(
		acceleration PROPERTIES
		RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
	)

	install(TARGETS acceleration DESTINATION lib/scantailor)
endif()