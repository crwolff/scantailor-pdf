# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND NOT STATIC_BUILD)

	find_package(LibLZMA)		# This only finds shared libs
	if(LIBLZMA_FOUND)
		set(LIB_LZMA LibLZMA::LibLZMA)
		list(APPEND ALL_EXTERN_INC_DIRS ${LIBLZMA_INCLUDE_DIRS})
	endif()
	
else() # Local build

	# Shared
	ExternalProject_Add(
		lzma-extern-static
		PREFIX ${EXTERN}
		URL https://github.com/tukaani-project/xz/releases/download/v5.6.2/xz-5.6.2.tar.xz
		URL_HASH SHA256=a9db3bb3d64e248a0fae963f8fb6ba851a26ba1822e504dc0efd18a80c626caf
		CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX=${EXTERN}
			-DCMAKE_PREFIX_PATH=${EXTERN}
			-DCMAKE_BUILD_TYPE=Release   # Only build release type for external libs
			-DBUILD_SHARED_LIBS=OFF
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)

	# Static
	ExternalProject_Add(
		lzma-extern
		PREFIX ${EXTERN}
		URL https://github.com/tukaani-project/xz/releases/download/v5.6.2/xz-5.6.2.tar.xz
		URL_HASH SHA256=a9db3bb3d64e248a0fae963f8fb6ba851a26ba1822e504dc0efd18a80c626caf
		CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX=${EXTERN}
			-DCMAKE_PREFIX_PATH=${EXTERN}
			-DCMAKE_BUILD_TYPE=Release   # Only build release type for external libs
			-DBUILD_SHARED_LIBS=ON
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)
	
	
	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_LZMA_STATIC "liblzma.lib")	#checked
		set(ST_LZMA_IMPLIB "lzma.lib")
		set(ST_LZMA_SHARED "lzma.dll")
	elseif(MINGW)
		set(ST_LZMA_STATIC "liblzma.a")			#checked
		set(ST_LZMA_IMPLIB "libliblzma.dll.a")	#checked
		set(ST_LZMA_SHARED "liblzma.dll")		#checked
	elseif(APPLE)
		set(ST_LZMA_STATIC "liblzma.a")
		set(ST_LZMA_SHARED "liblzma.dylib")
	else() # *nix and the rest
		set(ST_LZMA_STATIC "liblzma.a")
		set(ST_LZMA_SHARED "liblzma.so")
	endif()
	
	
	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(lzma SHARED IMPORTED)
	add_library(lzma-static STATIC IMPORTED)

	set_property(
		TARGET lzma lzma-static APPEND PROPERTY IMPORTED_CONFIGURATIONS $<CONFIG>
	)
	
	# Shared properties
	set_target_properties(lzma PROPERTIES
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_LZMA_SHARED}"
		# Ignored on non-WIN32 platforms
		IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_LZMA_IMPLIB}" 
	)
	
	# Static properties
	set_target_properties(lzma-static PROPERTIES
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_LZMA_STATIC}"
	)
	
	add_dependencies(lzma lzma-extern)
	add_dependencies(lzma-static lzma-extern-static)
	
	# Select the correct build type; this should switch the target,
	# if the user changes build type (e.g. -DBUILD_SHARED_LIBS=OFF)
	if(STATIC_BUILD)
		set(LIB_LZMA lzma-static)
	else()
		set(LIB_LZMA lzma)
	endif()

endif()
