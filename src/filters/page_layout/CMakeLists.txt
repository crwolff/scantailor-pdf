project("Page Layout Filter")

include_directories(BEFORE ${CMAKE_CURRENT_BINARY_DIR})

set(
	sources
	Utils.cpp Utils.h
	ImageView.cpp ImageView.h
	Filter.cpp Filter.h
	OptionsWidget.cpp OptionsWidget.h
	Task.cpp Task.h
	CacheDrivenTask.cpp CacheDrivenTask.h
	Params.cpp Params.h
	Settings.cpp Settings.h
	Thumbnail.cpp Thumbnail.h
	ApplyDialog.cpp ApplyDialog.h
	Alignment.cpp Alignment.h
	MatchSizeMode.cpp MatchSizeMode.h
	PageLayout.cpp PageLayout.h
	OrderByWidthProvider.cpp OrderByWidthProvider.h
	OrderByHeightProvider.cpp OrderByHeightProvider.h
)
source_group("Sources" FILES ${sources})

file(GLOB ui_files "ui/*.ui")
source_group("UI Files" FILES ${ui_files})

qt5_wrap_ui(ui_sources ${ui_files})

add_library(page_layout STATIC ${sources} ${ui_sources})
target_link_libraries(page_layout Qt5::Widgets Qt5::Xml)
target_include_directories(page_layout PUBLIC ${Boost_INCLUDE_DIRS})

translation_sources(scantailor ${sources} ${ui_files})
