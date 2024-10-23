# This has to go quite early on, as otherwise we risk picking
# up an identically named header from a system include path.
# Also, these are propagated to sub-projects.
include_directories(. foundation math interaction zones core)

add_subdirectory(ui)
include_directories("${toplevel_ui_sources_BINARY_DIR}")

# crash_reporter is included unconditionally to collect translation sources from there.
add_subdirectory(crash_reporter)
add_subdirectory(foundation)
add_subdirectory(math)
add_subdirectory(imageproc)
add_subdirectory(dewarping)
add_subdirectory(interaction)
add_subdirectory(zones)
add_subdirectory(acceleration)
add_subdirectory(tests)

add_subdirectory(filters/fix_orientation)
add_subdirectory(filters/page_split)
add_subdirectory(filters/deskew)
add_subdirectory(filters/select_content)
add_subdirectory(filters/page_layout)
add_subdirectory(filters/output)


source_group("Generated" FILES ${resource_sources})
source_group("Sources" FILES ${common_sources} ${gui_only_sources} ${cli_only_sources})
source_group("Special Headers" FILES version.h config.h.in)

# Compatibility for CMAKE >= 3.10
if(POLICY CMP0071)
    cmake_policy(SET CMP0071 NEW)
endif(POLICY CMP0071)

# Core library
add_subdirectory(core)

# Main app
add_subdirectory(app)

# CLI app
if(BUILD_CLI)
	add_subdirectory(app_cli)
endif()


if(ENABLE_CRASH_REPORTER)
	find_path(
		SYMBOLS_PATH . PATHS "${build_outer_dir}/symbols"
		"${source_outer_dir}/symbols" NO_DEFAULT_PATH
		DOC "The directory to write symbol information into."
	)
	if(NOT SYMBOLS_PATH)
		message(FATAL_ERROR "SYMBOLS_PATH directory is not set.")
	endif()

	# We can't build it, because it requires ATL, which is not part
	# of the Visual Studio Express Edition, so we rely on a pre-built
	# version which can be found in the Mozilla repository.
	find_program(
		DUMP_SYMS_EXECUTABLE dump_syms PATHS "${build_outer_dir}" "${source_outer_dir}"
		DOC "Path to dump_syms.exe, which can be found in Mozilla repository."
	)
	if(NOT DUMP_SYMS_EXECUTABLE)
		message(
			FATAL_ERROR "dump_syms.exe wasn't found.  Specify its location manually by setting the DUMP_SYMS_EXECUTABLE variable.  dump_syms.exe may be found in the Mozilla repository under /toolkit/crashreporter/tools/win32"
		)
	endif()

	include_directories(crash_reporter crash_reporter/google-breakpad)
	target_link_libraries(scantailor crash_handler)
endif()


#=================== Translations ======================#
TRANSLATION_SOURCES(
	scantailor
	${common_sources} ${gui_only_sources} ${cli_only_sources}
)

file(GLOB TRANSLATION_FILES translations/scantailor_*.ts)
file(GLOB CR_TRANSLATION_FILES translations/crashreporter_*.ts)

FINALIZE_TRANSLATION_SET(scantailor ${TRANSLATION_FILES})
FINALIZE_TRANSLATION_SET(crashreporter ${CR_TRANSLATION_FILES})
UPDATE_TRANSLATIONS_TARGET(update_translations scantailor crashreporter)

set(ts_files ${TRANSLATION_FILES})
if(ENABLE_CRASH_REPORTER)
	list(APPEND ts_files ${CR_TRANSLATION_FILES})
endif(ENABLE_CRASH_REPORTER)

# Don't build *.qm files from *untranslated.ts
set(FILTERED_TRANSLATION_FILES)
foreach(ts_file ${ts_files})
	if("${ts_file}" MATCHES ".*untranslated.ts")
		# Just skip it.
	else("${ts_file}" MATCHES ".*untranslated.ts")
		list(APPEND FILTERED_TRANSLATION_FILES "${ts_file}")
	endif("${ts_file}" MATCHES ".*untranslated.ts")
endforeach(ts_file)

QT5_ADD_TRANSLATION(QM_FILES ${FILTERED_TRANSLATION_FILES})
add_custom_target(compile_translations ALL DEPENDS ${QM_FILES})

install(FILES ${QM_FILES} DESTINATION "share/scantailor/translations")
