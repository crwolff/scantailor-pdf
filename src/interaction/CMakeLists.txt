project("Interaction")

include_directories(${CMAKE_CURRENT_BINARY_DIR})

set(
	sources
	DraggableObject.h
	DraggablePoint.cpp DraggablePoint.h
	DraggableLineSegment.cpp DraggableLineSegment.h
	ObjectDragHandler.cpp ObjectDragHandler.h
	InteractionHandler.cpp InteractionHandler.h
	InteractionState.cpp InteractionState.h
	DragHandler.cpp DragHandler.h
	DragWatcher.cpp DragWatcher.h
	ZoomHandler.cpp ZoomHandler.h
	InteractiveXSpline.cpp InteractiveXSpline.h
)

source_group(Sources FILES ${sources})

add_library(interaction STATIC ${sources})
target_link_libraries(interaction Qt5::Widgets Eigen3::Eigen)
target_include_directories(interaction PUBLIC ${Boost_INCLUDE_DIRS})

translation_sources(scantailor ${sources})
