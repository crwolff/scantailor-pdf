project("Math library")

include_directories("${CMAKE_CURRENT_BINARY_DIR}")

set(
	GENERIC_SOURCES
	math_config.h
	HomographicTransform.h
	SidesOfLine.cpp SidesOfLine.h
	ToLineProjector.cpp ToLineProjector.h
	ArcLengthMapper.cpp ArcLengthMapper.h
	LineBoundedByRect.cpp LineBoundedByRect.h
	LineBoundedByPolygon.cpp LineBoundedByPolygon.h
	PolylineIntersector.cpp PolylineIntersector.h
	LinearFunction.cpp LinearFunction.h
	QuadraticFunction.cpp QuadraticFunction.h
	XSpline.cpp XSpline.h
)
source_group("Sources" FILES ${GENERIC_SOURCES})

set(
	SPFIT_SOURCES
	spfit/FittableSpline.h
	spfit/FrenetFrame.cpp spfit/FrenetFrame.h
	spfit/ConstraintSet.cpp spfit/ConstraintSet.h
	spfit/SqDistApproximant.cpp spfit/SqDistApproximant.h
	spfit/ModelShape.h
	spfit/PolylineModelShape.cpp spfit/PolylineModelShape.h
	spfit/LinearForceBalancer.cpp spfit/LinearForceBalancer.h
	spfit/OptimizationResult.cpp spfit/OptimizationResult.h
	spfit/Optimizer.cpp spfit/Optimizer.h
	spfit/SplineFitter.cpp spfit/SplineFitter.h
)
source_group("Sources\\Spline Fitting Framework" FILES ${SPFIT_SOURCES})

set(
	ADIFF_SOURCES
	adiff/SparseMap.cpp adiff/SparseMap.h
	adiff/Function.cpp adiff/Function.h
)
source_group("Sources\\Differentiation Framework" FILES ${ADIFF_SOURCES})

add_library(math STATIC ${GENERIC_SOURCES} ${SPFIT_SOURCES} ${ADIFF_SOURCES})
target_link_libraries(math foundation Qt5::Core Eigen3::Eigen)

add_subdirectory(spfit/tests)
add_subdirectory(adiff/tests)
