# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND NOT STATIC_BUILD)

	find_package(PNG REQUIRED)		# This only finds shared libs
	set(LIB_PNG PNG::PNG)
	list(APPEND ALL_EXTERN_INC_DIRS ${PNG_INCLUDE_DIRS})
	
else() # Local build
	
	ExternalProject_Add(
		png-extern
		PREFIX ${EXTERN}
		URL https://download.sourceforge.net/libpng/libpng-1.6.44.tar.xz
		URL_HASH SHA256=60c4da1d5b7f0aa8d158da48e8f8afa9773c1c8baa5d21974df61f1886b8ce8e
		DOWNLOAD_DIR ${DOWNLOAD_DIR}
		CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
			-DCMAKE_PREFIX_PATH=<INSTALL_DIR>
			-DCMAKE_BUILD_TYPE=Release
			-DSKIP_INSTALL_EXECUTABLES=ON
			-DSKIP_INSTALL_PROGRAMS=ON
			-DPNG_TOOLS=OFF
			-DPNG_TESTS=OFF
			-DPNG_STATIC=${STATIC_BOOL}
			-DPNG_SHARED=${SHARED_BOOL}
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		DEPENDS ${LIB_ZLIB} ${LIB_LZMA}
	)
		
	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_PNG_STATIC "png-static.lib")
		set(ST_PNG_IMPLIB "png.lib")
		set(ST_PNG_SHARED "png.dll")
	elseif(MINGW)
		set(ST_PNG_STATIC "libpng.a")			#checked
		set(ST_PNG_IMPLIB "libpng.dll.a")
		set(ST_PNG_SHARED "libpng16.dll")
	elseif(APPLE)
		set(ST_PNG_STATIC "libpng.a")
		set(ST_PNG_SHARED "libpng.dylib")
	else() # *nix and the rest
		set(ST_PNG_STATIC "libpng.a")
		set(ST_PNG_SHARED "libpng.so")
	endif()


	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(png ${LIB_TYPE} IMPORTED)
	add_library(PNG::PNG ALIAS png)
	set_target_properties(png PROPERTIES
		IMPORTED_CONFIGURATIONS $<CONFIG>
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		INTERFACE_INCLUDE_DIRECTORIES ${EXTERN_INC_DIR}
	)
	target_link_libraries(png INTERFACE ${LIB_ZLIB} ${LIB_LZMA})

	if(BUILD_SHARED_LIBS)
		set_target_properties(png PROPERTIES
			IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_PNG_SHARED}"
			# Ignored on non-WIN32 platforms
			IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_PNG_IMPLIB}"
		)
	else()
		set_target_properties(png PROPERTIES
			IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_PNG_STATIC}"
		)
	endif()

	add_dependencies(png png-extern)
	set(LIB_PNG png)

endif()
