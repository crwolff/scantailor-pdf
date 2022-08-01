project(CrashReporter)

add_definitions(-DUNICODE -D_UNICODE)
include_directories(google-breakpad)

macro(LIST_ITEMS_PREPEND LIST PREFIX)
	set(tmp_list_)
	foreach(item ${${LIST}})
		list(APPEND tmp_list_ "${PREFIX}${item}")
	endforeach(item)
	set(${LIST} ${tmp_list_})
endmacro(LIST_ITEMS_PREPEND)

set(eh_sources exception_handler.cc exception_handler.h)
LIST_ITEMS_PREPEND(eh_sources google-breakpad/client/windows/handler/)

set(cg_sources crash_generation_client.cc crash_generation_client.h)
LIST_ITEMS_PREPEND(cg_sources google-breakpad/client/windows/crash_generation/)

set(common_sources guid_string.cc guid_string.h)
LIST_ITEMS_PREPEND(common_sources google-breakpad/common/windows/)

if(ENABLE_CRASH_REPORTER)
	add_library(crash_handler ${eh_sources} ${cg_sources} ${common_sources})
endif(ENABLE_CRASH_REPORTER)

set(
	crash_reporter_sources
	main.cpp CrashReportDialog.cpp CrashReportDialog.h
	MultipartFormData.cpp MultipartFormData.h
)
source_group("Sources" FILES ${crash_reporter_sources})

file(GLOB ui_files "ui/*.ui")
source_group("Ui Files" FILES ${ui_files})

add_subdirectory(ui)
include_directories("${CMAKE_CURRENT_BINARY_DIR}") # for ui files

if(ENABLE_CRASH_REPORTER)
	QT5_WRAP_UI(ui_sources ${ui_files})

	add_executable(CrashReporter WIN32 ${crash_reporter_sources} ${ui_sources})
	target_link_libraries(
		CrashReporter Qt5::Widgets Qt5::Xml Qt5::Network
		${PNG_LIBRARY} ${JPEG_LIBRARY} winmm imm32 ws2_32
	)
	
	# We want the executable located where we copy all the DLLs.
	set_target_properties(
		CrashReporter PROPERTIES
		RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/$<CONFIG>
	)
endif()

TRANSLATION_SOURCES(crashreporter ${crash_reporter_sources} ${ui_files})
