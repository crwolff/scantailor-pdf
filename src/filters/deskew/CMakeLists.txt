project("Deskew Filter")

include_directories(BEFORE ${CMAKE_CURRENT_BINARY_DIR})

set(
	sources
	ImageView.cpp ImageView.h
	DewarpingMode.cpp DewarpingMode.h
	DewarpingView.cpp DewarpingView.h
	RotationThumbnail.cpp RotationThumbnail.h
	DewarpingThumbnail.cpp DewarpingThumbnail.h
	Filter.cpp Filter.h
	OptionsWidget.cpp OptionsWidget.h
	Settings.cpp Settings.h
	Task.cpp Task.h
	CacheDrivenTask.cpp CacheDrivenTask.h
	Dependencies.cpp Dependencies.h
	DistortionType.cpp DistortionType.h
	RotationParams.cpp RotationParams.h
	PerspectiveParams.cpp PerspectiveParams.h
	DewarpingParams.cpp DewarpingParams.h
	Params.cpp Params.h
	ApplyDialog.cpp ApplyDialog.h
	Utils.cpp Utils.h
)
source_group("Sources" FILES ${sources})

file(GLOB ui_files "ui/*.ui")
source_group("UI Files" FILES ${ui_files})

qt5_wrap_ui(ui_sources ${ui_files})

add_library(deskew STATIC ${sources} ${ui_sources})
target_link_libraries(deskew Qt5::Widgets Qt5::Xml)
target_include_directories(deskew PUBLIC ${Boost_INCLUDE_DIRS})

translation_sources(scantailor ${sources} ${ui_files})
