project("Foundation library")

include_directories(${CMAKE_CURRENT_BINARY_DIR})

set(
	sources
	foundation_config.h
	NonCopyable.h IntrusivePtr.h RefCountable.h
	CopyableByMemcpy.h
	ObjectSwapper.h
	ObjectSwapperFactory.cpp ObjectSwapperFactory.h
	ObjectSwapperImpl.h
	ObjectSwapperImplGrid.h
	ObjectSwapperImplQImage.cpp ObjectSwapperImplQImage.h
	AlignedArray.h
	CachingFactory.h
	FastQueue.h
	SafeDeletingQObjectPtr.h
	ScopedIncDec.h ScopedDecInc.h
	Span.h VirtualFunction.h FlagOps.h
	AutoRemovingFile.cpp AutoRemovingFile.h
	Proximity.cpp Proximity.h
	RoundingHasher.cpp RoundingHasher.h
	Property.h
	PropertyFactory.cpp PropertyFactory.h
	PropertySet.cpp PropertySet.h
	PerformanceTimer.cpp PerformanceTimer.h
	GridLineTraverser.cpp GridLineTraverser.h
	LineIntersectionScalar.cpp LineIntersectionScalar.h
	XmlMarshaller.cpp XmlMarshaller.h
	XmlUnmarshaller.cpp XmlUnmarshaller.h
	DebugImages.cpp DebugImages.h
	RelativeMargins.h
	MaxAccumulator.h
	MinMaxAccumulator.h
	NumericTraits.h
	VecNT.h
	ToVec.h
	ToPoint.h
	PriorityQueue.h
	Grid.h
	GridAccessor.h
	ValueConv.h
	IndexSequence.h
)
source_group("Sources" FILES ${sources})

add_library(foundation STATIC ${sources})
target_link_libraries(foundation Qt5::Gui Qt5::Core Qt5::Xml Eigen3::Eigen)
target_include_directories(foundation PUBLIC ${Boost_INCLUDE_DIRS})

