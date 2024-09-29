# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND NOT STATIC_BUILD)

	find_package(PNG REQUIRED)		# This only finds shared libs
	set(LIB_PNG PNG::PNG)
	list(APPEND ALL_EXTERN_INC_DIRS ${PNG_INCLUDE_DIRS})
	
else() # Local build
	
	# Shared and static
	ExternalProject_Add(
		png-extern
		PREFIX ${EXTERN}
		URL https://download.sourceforge.net/libpng/libpng-1.6.44.tar.xz
		URL_HASH SHA256=60c4da1d5b7f0aa8d158da48e8f8afa9773c1c8baa5d21974df61f1886b8ce8e
		DOWNLOAD_DIR ${DOWNLOAD_DIR}
		CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX=${EXTERN}
			-DCMAKE_PREFIX_PATH=${EXTERN}
			-DCMAKE_BUILD_TYPE=Release   # Only build release type for external libs
			-DPNG_STATIC=ON
			-DPNG_SHARED=ON
			-DSKIP_INSTALL_EXECUTABLES=ON
			-DSKIP_INSTALL_PROGRAMS=ON 
			-DPNG_TESTS=OFF
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		DEPENDS ${LIB_ZLIB} ${LIB_LZMA}
	)
		
	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_PNG_STATIC "png-static.lib")
		set(ST_PNG_IMPLIB "png.lib")
		set(ST_PNG_SHARED "png.dll")
	elseif(MINGW)
		set(ST_PNG_STATIC "libpng.a")
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
	add_library(png SHARED IMPORTED)
	add_library(png-static STATIC IMPORTED)

	set_property(
		TARGET png png-static APPEND PROPERTY IMPORTED_CONFIGURATIONS $<CONFIG>
	)
	
	# Shared properties
	set_target_properties(png PROPERTIES
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_PNG_SHARED}"
		# Ignored on non-WIN32 platforms
		IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_PNG_IMPLIB}" 
	)
	
	# Static properties
	set_target_properties(png-static PROPERTIES
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_PNG_STATIC}"
	)
	
	add_dependencies(png png-extern)
	add_dependencies(png-static png-extern)
	
	target_link_libraries(png INTERFACE ${LIB_ZLIB} ${LIB_LZMA})
	target_link_libraries(png-static INTERFACE ${LIB_ZLIB} ${LIB_LZMA})

	# Select the correct build type; this should switch the target,
	# if the user changes build type (e.g. -DBUILD_SHARED_LIBS=OFF)
	if(STATIC_BUILD)
		set(LIB_PNG png-static)
	else()
		set(LIB_PNG png)
	endif()

endif()
