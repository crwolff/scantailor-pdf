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

if(NOT STATIC_BUILD)
	add_definitions(-DSHARED_FOUNDATION)
	add_definitions(-DBUILDING_FOUNDATION)
endif()

add_library(foundation ${MAYBE_STATIC} ${sources})
target_link_libraries(foundation Qt5::Gui Qt5::Core Qt5::Xml)
target_include_directories(foundation PUBLIC ${Boost_INCLUDE_DIRS})

if(NOT STATIC_BUILD)
	# We want the DLL located where executables can find it.
	set_target_properties(
		foundation PROPERTIES
		RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
	)

	install(TARGETS foundation DESTINATION lib/scantailor)
endif()
