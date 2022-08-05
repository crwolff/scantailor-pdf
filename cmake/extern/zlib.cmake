# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only


if(NOT WIN32 AND NOT STATIC_BUILD)

	find_package(ZLIB REQUIRED)		# This only finds shared libs
	set(LIB_ZLIB ZLIB::ZLIB)
	list(APPEND ALL_EXTERN_INC_DIRS ${ZLIB_INCLUDE_DIRS})
	
else() # Local build, both shared and static

	ExternalProject_Add(
		zlib-extern
		PREFIX ${EXTERN}
		URL https://www.zlib.net/zlib-1.2.12.tar.gz
		URL_HASH SHA256=91844808532e5ce316b3c010929493c0244f3d37593afd6de04f71821d5136d9
		CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX=${EXTERN}
			# Somehow, zlib ignores the $<CONFIG> value with MSVC
			-DCMAKE_INSTALL_BINDIR=bin/$<CONFIG>
			-DCMAKE_INSTALL_LIBDIR=lib/$<CONFIG>
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)	
	
	# TODO: Check that these filenames are correct.
	if(MSVC)
		if($<CONFIG> STREQUAL "Debug")
			set(ST_ZLIB_DEBUG_POSTFIX "d")
		endif()
		set(ST_ZLIB_STATIC "zlibstatic${ST_ZLIB_DEBUG_POSTFIX}.lib")
		set(ST_ZLIB_IMPLIB "zlib${ST_ZLIB_DEBUG_POSTFIX}.lib")
		set(ST_ZLIB_SHARED "zlib${ST_ZLIB_DEBUG_POSTFIX}.dll")
	elseif(MINGW)
		set(ST_ZLIB_STATIC "libzlibstatic.a")
		set(ST_ZLIB_IMPLIB "libzlib.dll.a")
		set(ST_ZLIB_SHARED "libzlib1.dll")
	elseif(APPLE)
		set(ST_ZLIB_STATIC "libz.a")
		set(ST_ZLIB_SHARED "libz.dylib")
	else() # *nix and the rest
		set(ST_ZLIB_STATIC "libz.a")
		set(ST_ZLIB_SHARED "libz.so")
	endif()
	
	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(zlib SHARED IMPORTED)
	add_library(zlib-static STATIC IMPORTED)

	set_property(
		TARGET zlib zlib-static APPEND PROPERTY IMPORTED_CONFIGURATIONS $<CONFIG>
	)
	
	# Shared properties
	set_target_properties(zlib PROPERTIES
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		IMPORTED_LOCATION_$<CONFIG> "${EXTERN_LIB_DIR}/$<CONFIG>/${ST_ZLIB_SHARED}"
		# Ignored on non-WIN32 platforms
		IMPORTED_IMPLIB_$<CONFIG> "${EXTERN_LIB_DIR}/$<CONFIG>/${ST_ZLIB_IMPLIB}" 
	)
	
	# Static properties
	set_target_properties(zlib-static PROPERTIES
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		IMPORTED_LOCATION_$<CONFIG> "${EXTERN_LIB_DIR}/$<CONFIG>/${ST_ZLIB_STATIC}"
	)
	
	add_dependencies(zlib zlib-extern)
	add_dependencies(zlib-static zlib-extern)
	
	# Select the correct build type; this should switch the target,
	# if the user changes build type (e.g. -DBUILD_SHARED_LIBS=OFF)
	if(STATIC_BUILD)
		set(LIB_ZLIB zlib-static)
	else()
		set(LIB_ZLIB zlib)
	endif()

endif()
