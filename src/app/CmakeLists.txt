project("Application")

set(
	gui_only_sources
	Application.cpp Application.h
	LoadFilesStatusDialog.cpp LoadFilesStatusDialog.h
	main.cpp
	MainWindow.cpp MainWindow.h
	NewOpenProjectPanel.cpp NewOpenProjectPanel.h
	OutOfMemoryDialog.cpp OutOfMemoryDialog.h
	ProjectCreationContext.cpp ProjectCreationContext.h
	ProjectFilesDialog.cpp ProjectFilesDialog.h
	ProjectOpeningContext.cpp ProjectOpeningContext.h
	RelinkablePathVisualization.cpp RelinkablePathVisualization.h
	RelinkingDialog.cpp RelinkingDialog.h
	RelinkingListView.cpp RelinkingListView.h
	RelinkingModel.cpp RelinkingModel.h
	RelinkingSortingModel.cpp RelinkingSortingModel.h
	SettingsDialog.cpp SettingsDialog.h
	SkinnedButton.cpp SkinnedButton.h
	StageListView.cpp StageListView.h
	SystemLoadWidget.cpp SystemLoadWidget.h
	ThumbnailSequence.cpp ThumbnailSequence.h
)

set(win32_resource_file "")
if(WIN32)
	set(rc_file "${CMAKE_SOURCE_DIR}/src/app/resources/win32/resources.rc")
	file(GLOB win32_resources resources/win32/*.ico)
	set_source_files_properties(
		"${rc_file}" PROPERTIES
		OBJECT_DEPENDS ${win32_resources}
	)
	set( win32_resource_file "${rc_file}")
endif(WIN32)

set(resource_files app/resources/resources.qrc app/resources/icons/COPYING)
if(WIN32)
	list(APPEND resource_files app/resources/win32/resources.rc)
endif()
source_group("Resources" FILES ${resource_files})

qt5_add_resources(resource_sources resources/resources.qrc)

if(WIN32)
	add_executable(
		scantailor WIN32 ${gui_only_sources} ${resource_sources} ${win32_resource_file}
	)
elseif(APPLE)
	set( ICON_NAME "ScanTailor.icns" )
	set( ICON_PATH "${PROJECT_SOURCE_DIR}/src/packaging/osx/${ICON_NAME}" )
	set_source_files_properties( ${ICON_PATH} PROPERTIES MACOSX_PACKAGE_LOCATION Resources )
	add_executable(
		scantailor MACOSX_BUNDLE ${gui_only_sources} ${resource_sources} ${ICON_PATH}
        )
        set_target_properties(scantailor-universal PROPERTIES MACOSX_BUNDLE_INFO_PLIST
                                  ${PROJECT_SOURCE_DIR}/src/packaging/osx/Info.plist.in)
else() # Other *nixs
	add_executable(
		scantailor ${gui_only_sources} ${resource_sources} ${win32_resource_file}
	)
endif()

target_link_libraries(
	scantailor
	acceleration page_layout output fix_orientation page_split
	deskew select_content stcore dewarping zones interaction
	imageproc math foundation
)

# We want the executable located where we copy all the DLLs.
set_target_properties(
	scantailor PROPERTIES
	RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/$<CONFIG>
)

## Copy all needed DLLs to the staging dir.
if(WIN32 AND BUILD_SHARED_LIBS)
	# Our external libraries
	set(RUNTIME_DEPS $<TARGET_RUNTIME_DLLS:scantailor>)
	
	if(MINGW)
		# lh-mouse's ucrt64 MinGW 
		find_file(mcf NAMES mcfgthread-12.dll libmcfgthread-1.dll HINTS ENV PATH NO_DEFAULT_PATH)
		# llvm clang MinGW
		find_file(libc NAMES libc++.dll HINTS ENV PATH NO_DEFAULT_PATH)
		find_file(libunwind NAMES libunwind.dll HINTS ENV PATH NO_DEFAULT_PATH)
		if(EXISTS ${mcf})
			list(APPEND RUNTIME_DEPS ${mcf})
		endif()
		if(EXISTS ${libc})
			list(APPEND RUNTIME_DEPS ${libc})
		endif()
		if(EXISTS ${libunwind})
			list(APPEND RUNTIME_DEPS ${libunwind})
		endif()
	endif()
		
	add_custom_command(TARGET scantailor POST_BUILD
		COMMAND ${CMAKE_COMMAND} -E copy_if_different ${RUNTIME_DEPS} $<TARGET_FILE_DIR:scantailor>
		COMMAND_EXPAND_LISTS
	)
	add_custom_command(
		TARGET scantailor POST_BUILD
		COMMAND ${CMAKE_COMMAND} -E cmake_echo_color --cyan
		"OUTPUT: "
		"${RUNTIME_DEPS}"
		" "
	)
	
	# QT5 stuff
	if(CMAKE_BUILD_TYPE STREQUAL "Debug")
   	set(qtdeploy_config --debug)
	endif()
	add_custom_command(TARGET scantailor POST_BUILD
	  COMMAND ${EXTERN_BIN_DIR}/windeployqt --no-translations ${qtdeploy_config} --dir $<TARGET_FILE_DIR:scantailor> $<TARGET_FILE:scantailor>
	)
		
	
endif()

install(TARGETS scantailor RUNTIME DESTINATION bin)
