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
		SOURCE_SUBDIR build/cmake
		CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX=${EXTERN}
         -DCMAKE_BUILD_TYPE=Release   # Only build release type for external libs
			-DZSTD_BUILD_STATIC=ON
			-DZSTD_BUILD_SHARED=ON
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
	add_library(zstd SHARED IMPORTED)
	add_library(zstd-static STATIC IMPORTED)

	set_property(
		TARGET zstd zstd-static APPEND PROPERTY IMPORTED_CONFIGURATIONS $<CONFIG>
	)
	
	# Shared properties
	set_target_properties(zstd PROPERTIES
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_ZSTD_SHARED}"
		# Ignored on non-WIN32 platforms
		IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_ZSTD_IMPLIB}" 
	)
	
	# Static properties
	set_target_properties(zstd-static PROPERTIES
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_ZSTD_STATIC}"
	)
	
	add_dependencies(zstd zstd-extern)
	add_dependencies(zstd-static zstd-extern)
	
	# Select the correct build type; this should switch the target,
	# if the user changes build type (e.g. -DBUILD_SHARED_LIBS=OFF)
	if(STATIC_BUILD)
		set(LIB_ZSTD zstd-static)
	else()
		set(LIB_ZSTD zstd)
	endif()
endif()
