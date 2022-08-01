# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND NOT STATIC_BUILD)

	find_package(PNG REQUIRED)		# This only finds shared libs
	set(LIB_PNG PNG::PNG)
	list(APPEND ALL_EXTERN_INC_DIRS ${PNG_INCLUDE_DIRS})
	
else() # Local build
		
	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_PNG_STATIC "png-static.lib")
		set(ST_PNG_SHARED "png.lib")
		set(ST_PNG_DLL "png.dll")
	elseif(MINGW)
		set(ST_PNG_STATIC "libpng.a")
		set(ST_PNG_SHARED "libpng.dll.a")
		set(ST_PNG_DLL "libpng16.dll")
	elseif(APPLE)
		set(ST_PNG_STATIC "libpng.a")
		set(ST_PNG_SHARED "libpng.dylib")
	else() # *nix and the rest
		set(ST_PNG_STATIC "libpng.a")
		set(ST_PNG_SHARED "libpng.so")
	endif()
	
	ExternalProject_Add(
		png-extern
		PREFIX ${EXTERN}
		URL https://download.sourceforge.net/libpng/lpng1637.zip
		URL_HASH SHA256=3b4b1cbd0bae6822f749d39b1ccadd6297f05e2b85a83dd2ce6ecd7d09eabdf2
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERN} -DCMAKE_PREFIX_PATH=${EXTERN} -DPNG_STATIC=${STATIC_BOOL} -DPNG_SHARED=${SHARED_BOOL} -DSKIP_INSTALL_EXECUTABLES=ON -DSKIP_INSTALL_PROGRAMS=ON  -DPNG_TESTS=OFF
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		DEPENDS ${LIB_ZLIB}
	)

	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.	
	if(STATIC_BUILD)
		add_library(png STATIC IMPORTED)
		set_property(TARGET png
			PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_PNG_STATIC}"
		)
	else() # Shared
		add_library(png SHARED IMPORTED)
		if(WIN32)
			set_target_properties(png PROPERTIES
				IMPORTED_LOCATION "${EXTERN_BIN_DIR}/${ST_PNG_DLL}"
				IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_PNG_SHARED}"
			)
		else() # *nix
			set_property(TARGET png
				PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_PNG_SHARED}"
			)
		endif()
	endif()
	
	add_dependencies(png png-extern)
	target_link_libraries(png INTERFACE ${LIB_ZLIB})
	set(LIB_PNG png)

endif()
