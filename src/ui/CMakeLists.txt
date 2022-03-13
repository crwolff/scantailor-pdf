project(toplevel_ui_sources) # Don't rename - it's referenced elsewhere.

file(GLOB ui_files "*.ui")
source_group("UI Files" FILES ${ui_files})

qt5_wrap_ui(ui_sources ${ui_files})
add_custom_target(toplevel_ui_sources SOURCES ${ui_sources})

translation_sources(scantailor ${ui_files})
