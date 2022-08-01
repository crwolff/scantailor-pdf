# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND NOT STATIC_BUILD)

	find_package(LibLZMA)		# This only finds shared libs
	if(LIBLZMA_FOUND)
		set(LIB_LZMA LibLZMA::LibLZMA)
		list(APPEND ALL_EXTERN_INC_DIRS ${LIBLZMA_INCLUDE_DIRS})
	endif()
	
else() # Local build
	
	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_LZMA_STATIC "lzma-static.lib")
		set(ST_LZMA_SHARED "lzma.lib")
		set(ST_LZMA_DLL "lzma.dll")
	elseif(MINGW)
		set(ST_LZMA_STATIC "liblzma.a")
		set(ST_LZMA_SHARED "libliblzma.dll.a")
		set(ST_LZMA_DLL "liblzma.dll")
	elseif(APPLE)
		set(ST_LZMA_STATIC "liblzma.a")
		set(ST_LZMA_SHARED "liblzma.dylib")
	else() # *nix and the rest
		set(ST_LZMA_STATIC "liblzma.a")
		set(ST_LZMA_SHARED "liblzma.so")
	endif()

	# Set string for ExternalProject_Add below
	if(STATIC_BUILD)
		set(LZMA_OPTION "static")
	else()
		set(LZMA_OPTION "shared")
	endif()

	ExternalProject_Add(
		lzma-extern
		PREFIX ${EXTERN}
		URL https://tukaani.org/xz/xz-5.2.5.tar.xz
		URL_HASH SHA256=3e1e518ffc912f86608a8cb35e4bd41ad1aec210df2a47aaa1f95e7f5576ef56
		# liblzma does not provide a CmakeLists.txt file. Use one from https://github.com/ShiftMediaProject/liblzma
		PATCH_COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN_PATCH_DIR}/lzma-extern/CMakeLists-${LZMA_OPTION}.txt ${EXTERN}/src/lzma-extern/CMakeLists.txt
		COMMAND ${CMAKE_COMMAND} -E copy_directory ${EXTERN_PATCH_DIR}/lzma-extern/cmake <SOURCE_DIR>/cmake
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERN} -DCMAKE_PREFIX_PATH=${EXTERN}
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)

	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	if(STATIC_BUILD)
		add_library(lzma STATIC IMPORTED)
		set_property(TARGET lzma
			PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_LZMA_STATIC}"
		)
	else() # Shared
		add_library(lzma SHARED IMPORTED)
		if(WIN32)
			set_target_properties(lzma PROPERTIES
				IMPORTED_LOCATION "${EXTERN_BIN_DIR}/${ST_LZMA_DLL}"
				IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_LZMA_SHARED}"
			)
		else() # *nix
			set_property(TARGET lzma
				PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_LZMA_SHARED}"
			)
		endif()
	endif()
	
	add_dependencies(lzma lzma-extern)
	set(LIB_LZMA lzma)

endif()
