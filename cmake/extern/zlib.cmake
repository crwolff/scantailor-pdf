# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only


if(NOT WIN32 AND NOT STATIC_BUILD)

	find_package(ZLIB REQUIRED)		# This only finds shared libs
	set(LIB_ZLIB ZLIB::ZLIB)
	list(APPEND ALL_EXTERN_INC_DIRS ${ZLIB_INCLUDE_DIRS})
	
else() # Local build, both shared and static

	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_ZLIB_STATIC "zlibstatic.lib")
		set(ST_ZLIB_SHARED "zlib.lib")
		set(ST_ZLIB_DLL "zlib.dll")
	elseif(MINGW)
		set(ST_ZLIB_STATIC "libzlibstatic.a")
		set(ST_ZLIB_SHARED "libzlib.dll.a")
		set(ST_ZLIB_DLL "libzlib1.dll")
	elseif(APPLE)
		set(ST_ZLIB_STATIC "libz.a")
		set(ST_ZLIB_SHARED "libz.dylib")
	else() # *nix and the rest
		set(ST_ZLIB_STATIC "libz.a")
		set(ST_ZLIB_SHARED "libz.so")
	endif()

	ExternalProject_Add(
		zlib-extern
		PREFIX ${EXTERN}
		URL https://www.zlib.net/zlib-1.2.12.tar.gz
		URL_HASH SHA256=91844808532e5ce316b3c010929493c0244f3d37593afd6de04f71821d5136d9
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERN} -DBUILD_SHARED_LIBS=OFF
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)	
	
	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	if(STATIC_BUILD)
		add_library(zlib STATIC IMPORTED)
		set_property(TARGET zlib PROPERTY
			IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_ZLIB_STATIC}"
		)
		if(MSVC)
			set_property(TARGET zlib PROPERTY DEBUG_POSTFIX "d")
		endif()
	else() # Shared
		add_library(zlib SHARED IMPORTED)
		if(WIN32)
			set_target_properties(zlib PROPERTIES
				IMPORTED_LOCATION "${EXTERN_BIN_DIR}/${ST_ZLIB_DLL}"
				IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_ZLIB_SHARED}"
			)
			if(MSVC)
				set_property(TARGET zlib PROPERTY DEBUG_POSTFIX "d")
			endif()
		else() # *nix
			set_property(TARGET zlib
				PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_ZLIB_SHARED}"
			)
		endif()
	endif()
	
	add_dependencies(zlib zlib-extern)
	set(LIB_ZLIB zlib)

endif()
