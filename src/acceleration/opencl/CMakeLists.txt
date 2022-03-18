project("OpenCL")

remove_definitions(-DBUILDING_ACCELERATION)

# We ship Khronos versions of OpenCL headers to work-around issues
# with NVidia's OpenCL headers. Even the Khronos headers weren't
# problem-free. The winning combination was cl2.hpp from OpenCL 2.1
# and the rest of the headers from OpenCL 1.1.
file(GLOB khronos_headers khronos/CL/*.h khronos/CL/*.hpp)

set(
	host_sources
#	${khronos_headers}
	OpenCLGrid.h
	OpenCLGaussBlur.cpp OpenCLGaussBlur.h
	OpenCLTextFilterBank.cpp OpenCLTextFilterBank.h
	OpenCLDewarp.cpp OpenCLDewarp.h
	OpenCLAffineTransform.cpp OpenCLAffineTransform.h
	OpenCLSavGolFilter.cpp OpenCLSavGolFilter.h
	Transpose.cpp Transpose.h
	Copy.cpp Copy.h
	RenderPolynomialSurface.cpp RenderPolynomialSurface.h
	BinaryFill.cpp BinaryFill.h
	BinaryRasterOp.cpp BinaryRasterOp.h
	HitMissTransform.cpp HitMissTransform.h
	Utils.cpp Utils.h
)

set(
	plugin_sources
	OpenCLAcceleratedOperations.cpp OpenCLAcceleratedOperations.h
	OpenCLPlugin.cpp OpenCLPlugin.h
)

source_group("Sources" FILES ${host_sources} ${plugin_sources})
translation_sources(scantailor ${plugin_sources})

file(GLOB device_sources device_code/*.cl)
source_group("Sources\\Device" "${device_sources}")
source_group("Resources" FILES resources.qrc)

include_directories(khronos)
add_definitions(-DCL_HPP_ENABLE_EXCEPTIONS)
add_definitions(-DCL_HPP_TARGET_OPENCL_VERSION=110)
add_definitions(-DCL_HPP_MINIMUM_OPENCL_VERSION=110)


qt5_add_resources(resource_sources resources.qrc)
source_group("Generated" FILES ${resource_sources})

add_library(opencl STATIC ${host_sources} ${device_sources} ${resource_sources})
target_link_libraries(opencl acceleration Qt5::Core Qt5::Gui ${OpenCL_LIBRARY})
target_include_directories(opencl INTERFACE ${EIGEN3_INCLUDE_DIR})

add_library(opencl_plugin MODULE ${plugin_sources} resources.qrc)
target_link_libraries(opencl_plugin opencl dewarping imageproc)

# Output to the root of the build directory, where it can be found by QPluginLoader.
set_target_properties(
	opencl_plugin PROPERTIES
	LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)

install(TARGETS opencl_plugin LIBRARY DESTINATION lib/scantailor)

add_subdirectory(tests)
