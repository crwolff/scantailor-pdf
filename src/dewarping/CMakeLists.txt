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

add_library(dewarping STATIC ${sources})
target_link_libraries(dewarping imageproc math foundation Qt5::Widgets Qt5::Xml Eigen3::Eigen)

translation_sources(scantailor ${sources})
