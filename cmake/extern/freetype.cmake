# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND NOT STATIC_BUILD)

	find_package(Freetype REQUIRED)		# This only finds shared libs
	set(LIB_FREETYPE Freetype::Freetype)
	list(APPEND ALL_EXTERN_INC_DIRS ${FREETYPE_INCLUDE_DIRS})
	
else() # Local build
	
	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_FREETYPE_STATIC "freetype-static.lib")
		set(ST_FREETYPE_SHARED "freetype.lib")
		set(ST_FREETYPE_DLL "freetype.dll")
	elseif(MINGW) # Checked!
		set(ST_FREETYPE_STATIC "libfreetype.a")
		set(ST_FREETYPE_SHARED "libfreetype.dll.a")
		set(ST_FREETYPE_DLL "libfreetype.dll")
	elseif(APPLE)
		set(ST_FREETYPE_STATIC "libfreetype.a")
		set(ST_FREETYPE_SHARED "libfreetype.dylib")
	else() # *nix and the rest
		set(ST_FREETYPE_STATIC "libfreetype.a")
		set(ST_FREETYPE_SHARED "libfreetype.so")
	endif()

	ExternalProject_Add(
		freetype-extern
		PREFIX ${EXTERN}
		URL https://sourceforge.net/projects/freetype/files/freetype2/2.11.1/freetype-2.11.1.tar.xz/download
		URL_MD5 24e79233d607ded439ef36ff1f3ab68f
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERN} -DCMAKE_PREFIX_PATH=${EXTERN} -DFT_DISABLE_BZIP2=TRUE -DFT_DISABLE_BROTLI=TRUE -DFT_DISABLE_HARFBUZZ=TRUE -DBUILD_SHARED_LIBS=${SHARED_BOOL}
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		DEPENDS ${LIB_ZLIB} ${LIB_PNG}
	)
		
	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	if(STATIC_BUILD)
		add_library(freetype STATIC IMPORTED)
		set_property(TARGET freetype
			PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_FREETYPE_STATIC}"
		)
	else() # Shared
		add_library(freetype SHARED IMPORTED)
		if(WIN32)
			set_target_properties(freetype PROPERTIES
				IMPORTED_LOCATION "${EXTERN_BIN_DIR}/${ST_FREETYPE_DLL}"
				IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_FREETYPE_SHARED}"
			)
		else() # *nix
			set_property(TARGET freetype
				PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_FREETYPE_SHARED}"
			)
		endif()
	endif()
	
	list(APPEND ALL_EXTERN_INC_DIRS ${EXTERN_INC_DIR}/freetype2 ${EXTERN_INC_DIR}/freetype2/freetype)
	add_dependencies(freetype freetype-extern)
	target_link_libraries(freetype INTERFACE ${LIB_ZLIB} ${LIB_PNG})
	set(LIB_FREETYPE freetype)

endif()
