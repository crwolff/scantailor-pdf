# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND NOT STATIC_BUILD)

    find_package(ZSTD)		# This only finds shared libs
	if(ZSTD_FOUND)
		set(LIB_ZSTD ZSTD::ZSTD)
		list(APPEND ALL_EXTERN_INC_DIRS ${ZSTD_INCLUDE_DIRS})
	endif()
	
else() # Local build
	
	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_ZSTD_STATIC "zstd.lib")
		set(ST_ZSTD_SHARED "zstd.lib")
		set(ST_ZSTD_DLL "zstd.dll")
	elseif(MINGW)
		set(ST_ZSTD_STATIC "libzstd.a")
		set(ST_ZSTD_SHARED "libzstd.dll.a")
		set(ST_ZSTD_DLL "libzstd.dll")
	elseif(APPLE)
		set(ST_ZSTD_STATIC "libzstd.a")
		set(ST_ZSTD_SHARED "libzstd.dylib")
	else() # *nix and the rest
		set(ST_ZSTD_STATIC "libzstd.a")
		set(ST_ZSTD_SHARED "libzstd.so")
	endif()

	ExternalProject_Add(
		zstd-extern
		PREFIX ${EXTERN}
		URL https://github.com/facebook/zstd/releases/download/v1.5.2/zstd-1.5.2.tar.gz
		URL_HASH SHA256=7c42d56fac126929a6a85dbc73ff1db2411d04f104fae9bdea51305663a83fd0
		SOURCE_SUBDIR build/cmake
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERN} -DZSTD_BUILD_STATIC=${STATIC_BOOL} -DZSTD_BUILD_SHARED=${SHARED_BOOL} -DZSTD_BUILD_PROGRAMS=OFF -DZSTD_BUILD_TESTS=OFF
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)

	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	if(STATIC_BUILD)
		add_library(zstd STATIC IMPORTED)
		set_property(TARGET zstd
			PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_ZSTD_STATIC}"
		)
	else() # Shared
		add_library(zstd SHARED IMPORTED)
		if(WIN32)
			set_target_properties(zstd PROPERTIES
				IMPORTED_LOCATION "${EXTERN_BIN_DIR}/${ST_ZSTD_DLL}"
				IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_ZSTD_SHARED}"
			)
		else() # *nix
			set_property(TARGET zstd
				PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_ZSTD_SHARED}"
			)
		endif()
	endif()
	
	add_dependencies(zstd zstd-extern)
	set(LIB_ZSTD zstd)

endif()
