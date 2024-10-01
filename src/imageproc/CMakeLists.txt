project("imageproc")

set(
	sources
	imageproc_config.h
	Constants.h Constants.cpp
	BadAllocIfNull.cpp BadAllocIfNull.h
	BinaryImage.cpp BinaryImage.h
	BinaryThreshold.cpp BinaryThreshold.h
	SlicedHistogram.cpp SlicedHistogram.h
	BWColor.h BWPixelProxy.h
	ConnComp.h Connectivity.h
	BitOps.cpp BitOps.h
	SeedFill.cpp SeedFill.h
	ConnCompEraser.cpp ConnCompEraser.h
	ConnCompEraserExt.cpp ConnCompEraserExt.h
	GrayImage.cpp GrayImage.h
	Grayscale.cpp Grayscale.h
	RasterOp.h RasterOpGeneric.h
	UpscaleIntegerTimes.cpp UpscaleIntegerTimes.h
	ReduceThreshold.cpp ReduceThreshold.h
	Shear.cpp Shear.h
	SkewFinder.cpp SkewFinder.h
	OrthogonalRotation.cpp OrthogonalRotation.h
	Scale.cpp Scale.h
	AffineTransform.cpp AffineTransform.h
	AbstractImageTransform.h
	AffineImageTransform.cpp AffineImageTransform.h
	AffineTransformedImage.cpp AffineTransformedImage.h
	Morphology.cpp Morphology.h
	IntegralImage.h
	Binarize.cpp Binarize.h
	PolygonUtils.cpp PolygonUtils.h
	PolygonRasterizer.cpp PolygonRasterizer.h
	HoughLineDetector.cpp HoughLineDetector.h
	HoughTransform.h
	GaussBlur.cpp GaussBlur.h
	Sobel.h
	MorphGradientDetect.cpp MorphGradientDetect.h
	PolynomialLine.cpp PolynomialLine.h
	PolynomialSurface.cpp PolynomialSurface.h
	SavGolKernel.cpp SavGolKernel.h
	SavGolFilter.cpp SavGolFilter.h
	WienerFilter.cpp WienerFilter.h
	DrawOver.cpp DrawOver.h
	AdjustBrightness.cpp AdjustBrightness.h
	SEDM.cpp SEDM.h
	ConnectivityMap.cpp ConnectivityMap.h
	InfluenceMap.cpp InfluenceMap.h
	MaxWhitespaceFinder.cpp MaxWhitespaceFinder.h
	RastLineFinder.cpp RastLineFinder.h
	ColorInterpolation.cpp ColorInterpolation.h
	LocalMinMaxGeneric.h
	SeedFillGeneric.cpp SeedFillGeneric.h
	WatershedSegmentation.cpp WatershedSegmentation.h
	TraverseBorders.h
	FindPeaksGeneric.h
	PlugHoles.h
	ColorMixer.h
	ColorForId.h
)

source_group(Sources FILES ${sources})

if(BUILD_SHARED_LIBS)
	add_definitions(-DSHARED_IMAGEPROC)
	add_definitions(-DBUILDING_IMAGEPROC)
endif()

add_library(imageproc ${LIB_TYPE} ${sources})
target_link_libraries(imageproc foundation Qt5::Core Qt5::Gui)
target_include_directories(imageproc INTERFACE ${EIGEN3_INCLUDE_DIR})

if(BUILD_SHARED_LIBS)
	# We want the DLL located where executables can find it.
	set_target_properties(
		imageproc PROPERTIES
		RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/$<CONFIG>
	)

	install(TARGETS imageproc DESTINATION lib/scantailor)
endif()

add_subdirectory(tests)
