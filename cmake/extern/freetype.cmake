# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(USE_SYSTEM_LIBS AND NOT STATIC_BUILD)

	find_package(Freetype REQUIRED)		# This only finds shared libs
	set(LIB_FREETYPE Freetype::Freetype)
	list(APPEND ALL_EXTERN_INC_DIRS ${FREETYPE_INCLUDE_DIRS})
	
else() # Local static build
	
	# TODO: Filenames for other platforms and dynamic library
	set(FREETYPE_FILE_NAME "")
	if(MSVC)
		set(FREETYPE_FILE_NAME "libfreetype.lib")
	elseif(MINGW)
		set(FREETYPE_FILE_NAME "libfreetype.a")
	endif()
	
	ExternalProject_Add(
		freetype-extern
		PREFIX ${EXTERN}
		URL https://sourceforge.net/projects/freetype/files/freetype2/2.11.1/freetype-2.11.1.tar.xz/download
		URL_MD5 24e79233d607ded439ef36ff1f3ab68f
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERN} -DCMAKE_PREFIX_PATH=${EXTERN} -DFT_DISABLE_BZIP2=TRUE -DFT_DISABLE_BROTLI=TRUE -DFT_DISABLE_HARFBUZZ=TRUE
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		DEPENDS ${LIB_ZLIB} ${LIB_PNG}
	)	

	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(freetype STATIC IMPORTED)
	set_property(TARGET freetype PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${FREETYPE_FILE_NAME}")
	list(APPEND ALL_EXTERN_INC_DIRS ${EXTERN_INC_DIR}/freetype2 ${EXTERN_INC_DIR}/freetype2/freetype)
	add_dependencies(freetype freetype-extern)
	target_link_libraries(freetype INTERFACE ${LIB_ZLIB} ${LIB_PNG})
	set(LIB_FREETYPE freetype)

endif()
