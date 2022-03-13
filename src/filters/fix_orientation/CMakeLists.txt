project("Fix Orientation Filter")

include_directories(BEFORE "${CMAKE_CURRENT_BINARY_DIR}" "../../core")

set(
	sources
	ImageView.cpp ImageView.h
	Filter.cpp Filter.h
	OptionsWidget.cpp OptionsWidget.h
	ApplyDialog.cpp ApplyDialog.h
	Settings.cpp Settings.h
	Task.cpp Task.h
	CacheDrivenTask.cpp CacheDrivenTask.h
)
source_group("Sources" FILES ${sources})

file(GLOB ui_files "ui/*.ui")
source_group("UI Files" FILES ${ui_files})

qt5_wrap_ui(ui_sources ${ui_files})

add_library(fix_orientation STATIC ${sources} ${ui_sources})
target_link_libraries(fix_orientation Qt5::Widgets Qt5::Xml)

translation_sources(scantailor ${sources} ${ui_files})
