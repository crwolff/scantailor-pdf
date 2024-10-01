# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND NOT STATIC_BUILD)

	find_package(Freetype REQUIRED)		# This only finds shared libs
	set(LIB_FREETYPE Freetype::Freetype)
	list(APPEND ALL_EXTERN_INC_DIRS ${FREETYPE_INCLUDE_DIRS})
	
else() # Local build
	
	ExternalProject_Add(
		freetype-extern
		URL https://download.savannah.gnu.org/releases/freetype/freetype-2.13.3.tar.xz
		URL_HASH SHA256=0550350666d427c74daeb85d5ac7bb353acba5f76956395995311a9c6f063289
		DOWNLOAD_DIR ${DOWNLOAD_DIR}
		PREFIX ${EXTERN}
		CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
			-DCMAKE_PREFIX_PATH=<INSTALL_DIR>
			-DCMAKE_BUILD_TYPE=Release
			-DFT_DISABLE_BZIP2=TRUE
			-DFT_DISABLE_PNG=TRUE
			-DFT_DISABLE_BROTLI=TRUE
			-DFT_DISABLE_HARFBUZZ=TRUE
			-DBUILD_SHARED_LIBS=${SHARED_BOOL}
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		DEPENDS ${LIB_ZLIB}
	)
	
	
	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_FREETYPE_STATIC "freetype-static.lib")
		set(ST_FREETYPE_IMPLIB "freetype.lib")
		set(ST_FREETYPE_SHARED "freetype.dll")
	elseif(MINGW) # Checked!
		set(ST_FREETYPE_STATIC "libfreetype.a")		#checked
		set(ST_FREETYPE_IMPLIB "libfreetype.dll.a")
		set(ST_FREETYPE_SHARED "libfreetype.dll")
	elseif(APPLE)
		set(ST_FREETYPE_STATIC "libfreetype.a")
		set(ST_FREETYPE_SHARED "libfreetype.dylib")
	else() # *nix and the rest
		set(ST_FREETYPE_STATIC "libfreetype.a")
		set(ST_FREETYPE_SHARED "libfreetype.so")
	endif()
	
	
	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(freetype ${LIB_TYPE} IMPORTED)
	add_library(Freetype::Freetype ALIAS freetype)
	set_target_properties(freetype PROPERTIES
		IMPORTED_CONFIGURATIONS $<CONFIG>
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		INTERFACE_INCLUDE_DIRECTORIES "${EXTERN_INC_DIR}/freetype2;${EXTERN_INC_DIR}/freetype2/freetype"
	)
	target_link_libraries(freetype INTERFACE ${LIB_ZLIB})

	if(BUILD_SHARED_LIBS)
		set_target_properties(freetype PROPERTIES
			IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_FREETYPE_SHARED}"
			# Ignored on non-WIN32 platforms
			IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_FREETYPE_IMPLIB}"
		)
	else() # Static
		set_target_properties(freetype PROPERTIES
			IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_FREETYPE_STATIC}"
		)
	endif()
	
	add_dependencies(freetype freetype-extern)
	set(LIB_FREETYPE freetype)

endif()
