# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only


if(NOT WIN32 AND NOT STATIC_BUILD)

	find_package(ZLIB REQUIRED)		# This only finds shared libs
	set(LIB_ZLIB ZLIB::ZLIB)
	list(APPEND ALL_EXTERN_INC_DIRS ${ZLIB_INCLUDE_DIRS})
	
else() # Local build

	ExternalProject_Add(
		zlib-extern
		PREFIX ${EXTERN}
		URL https://www.zlib.net/zlib-1.3.1.tar.xz
		URL_HASH SHA256=38ef96b8dfe510d42707d9c781877914792541133e1870841463bfa73f883e32
		DOWNLOAD_DIR ${DOWNLOAD_DIR}
		CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
			-DCMAKE_PREFIX_PATH=<INSTALL_DIR>
			-DCMAKE_BUILD_TYPE=Release   # Only build release type for external libs
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)	
	
	
	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_ZLIB_STATIC "zlibstatic.lib")	#checked
		set(ST_ZLIB_IMPLIB "zlib.lib")		 	#checked
		set(ST_ZLIB_SHARED "zlib.dll")			#checked
	elseif(MINGW)
		set(ST_ZLIB_STATIC "libzlibstatic.a")	#checked
		set(ST_ZLIB_IMPLIB "libzlib.dll.a")		#checked
		set(ST_ZLIB_SHARED "libzlib.dll")		#checked
	elseif(APPLE)
		set(ST_ZLIB_STATIC "libz.a")
		set(ST_ZLIB_SHARED "libz.dylib")
	else() # *nix and the rest
		set(ST_ZLIB_STATIC "libz.a")
		set(ST_ZLIB_SHARED "libz.so")
	endif()
	
	
	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	if(${BUILD_SHARED_LIBS})
		add_library(zlib SHARED IMPORTED)
		set_target_properties(zlib PROPERTIES
			IMPORTED_CONFIGURATIONS $<CONFIG>
			MAP_IMPORTED_CONFIG_DEBUG Release
			MAP_IMPORTED_CONFIG_MINSIZEREL Release
			MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
			INTERFACE_INCLUDE_DIRECTORIES ${EXTERN_INC_DIR}
			IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_ZLIB_SHARED}"
			# Ignored on non-WIN32 platforms
			IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_ZLIB_IMPLIB}" 
		)
		add_dependencies(zlib zlib-extern)
		set(LIB_ZLIB zlib)
	else()
		add_library(zlib-static STATIC IMPORTED)
		set_target_properties(zlib-static PROPERTIES
			IMPORTED_CONFIGURATIONS $<CONFIG>
			MAP_IMPORTED_CONFIG_DEBUG Release
			MAP_IMPORTED_CONFIG_MINSIZEREL Release
			MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
			INTERFACE_INCLUDE_DIRECTORIES ${EXTERN_INC_DIR}
			IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_ZLIB_STATIC}"
		)
		add_dependencies(zlib-static zlib-extern)
		set(LIB_ZLIB zlib-static)
	endif()

endif()
