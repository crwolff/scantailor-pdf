project("Output Filter")

include_directories(BEFORE ${CMAKE_CURRENT_BINARY_DIR})

set(
	sources
	ApplyColorsDialog.cpp ApplyColorsDialog.h
	ImageViewTab.h
	TabbedImageView.cpp TabbedImageView.h
	Filter.cpp Filter.h
	OptionsWidget.cpp OptionsWidget.h
	Task.cpp Task.h
	CacheDrivenTask.cpp CacheDrivenTask.h
	OutputGenerator.cpp OutputGenerator.h
	OutputMargins.h
	Settings.cpp Settings.h
	Thumbnail.cpp Thumbnail.h
	Utils.cpp Utils.h
	Params.cpp Params.h
	BlackWhiteOptions.cpp BlackWhiteOptions.h
	MixedOptions.cpp MixedOptions.h
	ColorGrayscaleOptions.cpp ColorGrayscaleOptions.h
	RenderParams.cpp RenderParams.h
	ColorParams.cpp ColorParams.h
	OutputImageParams.cpp OutputImageParams.h
	OutputFileParams.cpp OutputFileParams.h
	OutputParams.cpp OutputParams.h
	PictureLayerProperty.cpp PictureLayerProperty.h
	PictureZonePropFactory.cpp PictureZonePropFactory.h
	PictureZonePropDialog.cpp PictureZonePropDialog.h
	PictureZoneComparator.cpp PictureZoneComparator.h
	PictureZoneEditor.cpp PictureZoneEditor.h
	OnDemandPictureZoneEditor.cpp OnDemandPictureZoneEditor.h
	FillColorProperty.cpp FillColorProperty.h
	FillZonePropFactory.cpp FillZonePropFactory.h
	FillZoneComparator.cpp FillZoneComparator.h
	FillZoneEditor.cpp FillZoneEditor.h
	ColorPickupInteraction.cpp ColorPickupInteraction.h
	DespeckleState.cpp DespeckleState.h
	DespeckleView.cpp DespeckleView.h
	DespeckleVisualization.cpp DespeckleVisualization.h
	DespeckleLevel.cpp DespeckleLevel.h
)
source_group("Sources" FILES ${sources})

file(GLOB ui_files "ui/*.ui")
source_group("UI Files" FILES ${ui_files})

qt5_wrap_ui(ui_sources ${ui_files})

add_library(output STATIC ${sources} ${ui_sources})
target_link_libraries(output Qt5::Widgets Qt5::Xml Eigen3::Eigen)
target_include_directories(output PUBLIC ${Boost_INCLUDE_DIRS})
add_dependencies(output toplevel_ui_sources)

translation_sources(scantailor ${sources} ${ui_files})
