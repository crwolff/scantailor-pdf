# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(USE_SYSTEM_LIBS AND NOT STATIC_BUILD)

	find_package(LibLZMA)		# This only finds shared libs
	if(LIBLZMA_FOUND)
		set(LIB_LZMA LibLZMA::LibLZMA)
		list(APPEND ALL_EXTERN_INC_DIRS ${LIBLZMA_INCLUDE_DIRS})
	endif()
	
else() # Local static build
	
	# TODO: Filenames for other platforms and dynamic library
	set(LZMA_FILE_NAME "")
	if(MSVC)
		set(LZMA_FILE_NAME "lzma.lib")
	elseif(MINGW)
		set(LZMA_FILE_NAME "liblzma.a")
	endif()

	ExternalProject_Add(
		lzma-extern
		PREFIX ${EXTERN}
		URL https://tukaani.org/xz/xz-5.2.5.tar.xz
		URL_HASH SHA256=3e1e518ffc912f86608a8cb35e4bd41ad1aec210df2a47aaa1f95e7f5576ef56
		PATCH_COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN}/src/patches/lzma-extern/CMakeLists.txt ${EXTERN}/src/lzma-extern/CMakeLists.txt
		COMMAND ${CMAKE_COMMAND} -E copy_directory ${EXTERN}/src/patches/lzma-extern/cmake <SOURCE_DIR>/cmake
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERN} -DCMAKE_PREFIX_PATH=${EXTERN} -DBUILD_SHARED_LIBS=OFF
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)	

	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(lzma STATIC IMPORTED)
	set_property(TARGET lzma PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${LZMA_FILE_NAME}")
	add_dependencies(lzma lzma-extern)
	set(LIB_LZMA lzma)

endif()
