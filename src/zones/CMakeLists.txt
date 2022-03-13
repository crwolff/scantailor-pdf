project("zones")

include_directories("${CMAKE_CURRENT_BINARY_DIR}" "../core")

set(
	sources
	SplineVertex.cpp SplineVertex.h
	SplineSegment.cpp SplineSegment.h
	EditableSpline.cpp EditableSpline.h
	SerializableSpline.cpp SerializableSpline.h
	Zone.cpp Zone.h
	ZoneSet.cpp ZoneSet.h
	EditableZoneSet.cpp EditableZoneSet.h
	BasicSplineVisualizer.cpp BasicSplineVisualizer.h
	ZoneInteractionContext.cpp ZoneInteractionContext.h
	ZoneDefaultInteraction.cpp ZoneDefaultInteraction.h
	ZoneCreationInteraction.cpp ZoneCreationInteraction.h
	ZoneVertexDragInteraction.cpp ZoneVertexDragInteraction.h
	ZoneContextMenuInteraction.cpp ZoneContextMenuInteraction.h
	ZoneContextMenuItem.h
)

source_group(Sources FILES ${sources})

add_library(zones STATIC ${sources})
target_link_libraries(zones Qt5::Widgets Qt5::Xml)

translation_sources(scantailor ${sources})
