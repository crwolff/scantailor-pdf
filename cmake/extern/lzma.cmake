# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND BUILD_SHARED_LIBS)

	find_package(LibLZMA)		# This only finds shared libs
	if(LIBLZMA_FOUND)
		set(LIB_LZMA LibLZMA::LibLZMA)
		list(APPEND ALL_EXTERN_INC_DIRS ${LIBLZMA_INCLUDE_DIRS})
	endif()
	
else() # Local build
	
	set(LZMA-EXTERN lzma-extern)
	
	ExternalProject_Add(
		${LZMA-EXTERN}
		URL https://github.com/tukaani-project/xz/releases/download/v5.6.2/xz-5.6.2.tar.xz
		URL_HASH SHA256=a9db3bb3d64e248a0fae963f8fb6ba851a26ba1822e504dc0efd18a80c626caf
		DOWNLOAD_DIR ${DOWNLOAD_DIR}
		PREFIX ${EXTERN}
		CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
			-DCMAKE_PREFIX_PATH=<INSTALL_DIR>
			-DCMAKE_BUILD_TYPE=Release
			-DENABLE_NLS=OFF
			-DBUILD_SHARED_LIBS=${SHARED_BOOL}
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)
	
	
	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_LZMA_STATIC "liblzma.lib")	#checked
		set(ST_LZMA_IMPLIB "liblzma.lib")	#checked
		set(ST_LZMA_SHARED "liblzma.dll")	#checked
	elseif(MINGW)
		set(ST_LZMA_STATIC "liblzma.a")			#checked
		set(ST_LZMA_IMPLIB "liblzma.dll.a")	#checked
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
	add_library(lzma ${LIB_TYPE} IMPORTED)
	set_target_properties(lzma PROPERTIES
		IMPORTED_CONFIGURATIONS $<CONFIG>
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		INTERFACE_INCLUDE_DIRECTORIES ${EXTERN_INC_DIR}
	)

	if(BUILD_SHARED_LIBS)
		set_target_properties(lzma PROPERTIES
			IMPORTED_LOCATION_RELEASE "${EXTERN_BIN_DIR}/${ST_LZMA_SHARED}"
			# Ignored on non-WIN32 platforms
			IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_LZMA_IMPLIB}"
		)
	else()
		set_target_properties(lzma PROPERTIES
			IMPORTED_LOCATION_RELEASE "${EXTERN_LIB_DIR}/${ST_LZMA_STATIC}"
		)
	endif()

	add_dependencies(lzma ${LZMA-EXTERN})
	set(LIB_LZMA lzma)

endif()
