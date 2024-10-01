# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND NOT STATIC_BUILD)

	find_package(zstd)		# This only finds shared libs
	if(ZSTD_FOUND)
		set(LIB_ZSTD ZSTD::ZSTD)
		list(APPEND ALL_EXTERN_INC_DIRS ${ZSTD_INCLUDE_DIRS})
	endif()
	
else() # Local build
	
	ExternalProject_Add(
		zstd-extern
		PREFIX ${EXTERN}
		URL https://github.com/facebook/zstd/releases/download/v1.5.2/zstd-1.5.2.tar.gz
		URL_HASH SHA256=7c42d56fac126929a6a85dbc73ff1db2411d04f104fae9bdea51305663a83fd0
		DOWNLOAD_DIR ${DOWNLOAD_DIR}
		SOURCE_SUBDIR build/cmake
		CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
			-DCMAKE_PREFIX_PATH=<INSTALL_DIR>
         -DCMAKE_BUILD_TYPE=Release
			-DZSTD_BUILD_STATIC=${STATIC_BOOL}
			-DZSTD_BUILD_SHARED=${SHARED_BOOL}
			-DZSTD_BUILD_PROGRAMS=OFF
			-DZSTD_BUILD_TESTS=OFF
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)


	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_ZSTD_STATIC "zstd_static.lib")
		set(ST_ZSTD_IMPLIB "zstd.lib")
		set(ST_ZSTD_SHARED "zstd.dll")
	elseif(MINGW)
		set(ST_ZSTD_STATIC "libzstd.a")			#checked
		set(ST_ZSTD_IMPLIB "libzstd.dll.a")		#checked
		set(ST_ZSTD_SHARED "libzstd.dll")		#checked
	elseif(APPLE)
		set(ST_ZSTD_STATIC "libzstd.a")
		set(ST_ZSTD_SHARED "libzstd.dylib")
	else() # *nix and the rest
		set(ST_ZSTD_STATIC "libzstd.a")
		set(ST_ZSTD_SHARED "libzstd.so")
	endif()


	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(zstd ${LIB_TYPE} IMPORTED)
	add_library(ZSTD::ZSTD ALIAS zstd)
	set_target_properties(zstd PROPERTIES
		IMPORTED_CONFIGURATIONS $<CONFIG>
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		INTERFACE_INCLUDE_DIRECTORIES ${EXTERN_INC_DIR}
	)

	if(BUILD_SHARED_LIBS)
		set_target_properties(zstd PROPERTIES
			IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_ZSTD_SHARED}"
			# Ignored on non-WIN32 platforms
			IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_ZSTD_IMPLIB}"
		)
	else()
		set_target_properties(zstd PROPERTIES
			IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_ZSTD_STATIC}"
		)
	endif()

	add_dependencies(zstd zstd-extern)
	set(LIB_ZSTD zstd)

endif()
