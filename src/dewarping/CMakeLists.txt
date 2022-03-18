project("Dewarping library")

include_directories(${CMAKE_CURRENT_BINARY_DIR})

set(
	sources
	dewarping_config.h
	Curve.cpp Curve.h
	DetectVerticalBounds.cpp DetectVerticalBounds.h
	DepthPerception.cpp DepthPerception.h
	DistortionModel.cpp DistortionModel.h
	DistortionModelBuilder.cpp DistortionModelBuilder.h
	TextLineTracer.cpp TextLineTracer.h
	TextLineRefiner.cpp TextLineRefiner.h
	TextLineSegmenter.cpp TextLineSegmenter.h
	TopBottomEdgeTracer.cpp TopBottomEdgeTracer.h
	CylindricalSurfaceDewarper.cpp CylindricalSurfaceDewarper.h
	RasterDewarper.cpp RasterDewarper.h
	DewarpingImageTransform.cpp DewarpingImageTransform.h
)
source_group("Sources" FILES ${sources})

if(NOT STATIC_BUILD)
	add_definitions(-DSHARED_DEWARPING)
	add_definitions(-DBUILDING_DEWARPING)
endif()

add_library(dewarping ${MAYBE_STATIC} ${sources})
target_link_libraries(dewarping imageproc math foundation Qt5::Widgets Qt5::Xml)
target_include_directories(dewarping INTERFACE ${EIGEN3_INCLUDE_DIR})

if(NOT STATIC_BUILD)
	# We want the DLL located where executables can find it.
	set_target_properties(
		dewarping PROPERTIES
		RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
	)

	install(TARGETS dewarping DESTINATION lib/scantailor)
endif()

translation_sources(scantailor ${sources})
