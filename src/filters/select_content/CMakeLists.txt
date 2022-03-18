project("Select Content Filter")

include_directories(BEFORE ${CMAKE_CURRENT_BINARY_DIR})

set(
	sources
	ImageView.cpp ImageView.h
	Filter.cpp Filter.h
	DetectionMode.cpp DetectionMode.h
	OptionsWidget.cpp OptionsWidget.h
	ApplyDialog.cpp ApplyDialog.h
	ContentBoxFinder.cpp ContentBoxFinder.h
	PageFinder.cpp PageFinder.h
	Task.cpp Task.h
	CacheDrivenTask.cpp CacheDrivenTask.h
	Dependencies.cpp Dependencies.h
	Params.cpp Params.h
	Settings.cpp Settings.h
	Thumbnail.cpp Thumbnail.h
	OrderByWidthProvider.cpp OrderByWidthProvider.h
	OrderByHeightProvider.cpp OrderByHeightProvider.h
)
source_group("Sources" FILES ${sources})

file(GLOB ui_files "ui/*.ui")
source_group("UI Files" FILES ${ui_files})

qt5_wrap_ui(ui_sources ${ui_files})

add_library(select_content STATIC ${sources} ${ui_sources})
target_link_libraries(select_content Qt5::Widgets Qt5::Xml)
target_include_directories(select_content PUBLIC ${Boost_INCLUDE_DIRS})

translation_sources(scantailor ${sources} ${ui_files})
