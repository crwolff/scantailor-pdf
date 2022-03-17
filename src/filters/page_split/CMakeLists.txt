project("Page Split Filter")

include_directories(BEFORE "${CMAKE_CURRENT_BINARY_DIR}" "../../core")

set(
	sources
	SplitLineObject.h
	ImageView.cpp ImageView.h
	Thumbnail.cpp Thumbnail.h
	Params.cpp Params.h
	Dependencies.cpp Dependencies.h
	PageLayout.cpp PageLayout.h
	PageLayoutEstimator.cpp PageLayoutEstimator.h
	VertLineFinder.cpp VertLineFinder.h
	Filter.cpp Filter.h
	OptionsWidget.cpp OptionsWidget.h
	SplitModeDialog.cpp SplitModeDialog.h
	Settings.cpp Settings.h
	Task.cpp Task.h
	CacheDrivenTask.cpp CacheDrivenTask.h
	LayoutType.cpp LayoutType.h
	UnremoveButton.cpp UnremoveButton.h
	OrderBySplitTypeProvider.cpp OrderBySplitTypeProvider.h
)
source_group("Sources" FILES ${sources})

file(GLOB ui_files "ui/*.ui")
source_group("UI Files" FILES ${ui_files})

qt5_wrap_ui(ui_sources ${ui_files})

add_library(page_split STATIC ${sources} ${ui_sources})
target_link_libraries(page_split Qt5::Widgets Qt5::Xml)
target_include_directories(page_split PUBLIC ${Boost_INCLUDE_DIRS})

translation_sources(scantailor ${sources} ${ui_files})
