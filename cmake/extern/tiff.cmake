# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(USE_SYSTEM_LIBS AND NOT STATIC_BUILD)

	find_package(TIFF REQUIRED)		# This only finds shared libs
	set(LIB_TIFF TIFF::TIFF)
	list(APPEND ALL_EXTERN_INC_DIRS ${TIFF_INCLUDE_DIRS})
	
else() # Local static build
	
	# TODO: Filenames for other platforms and dynamic library
	set(TIFF_FILE_NAME "")
	if(MSVC)
		set(TIFF_FILE_NAME "libtiff.lib")
	elseif(MINGW)
		set(TIFF_FILE_NAME "libtiff.a")
	endif()

	set(TIFF_BIN_DIR ${EXTERN}/src/tiff-extern-build)
	set(TIFF_SRC_DIR ${EXTERN}/src/tiff-extern)

	ExternalProject_Add(
		tiff-extern
		PREFIX ${EXTERN}
		URL http://download.osgeo.org/libtiff/tiff-4.3.0.zip
		URL_HASH SHA256=882c0bcfa0e69f85a51a4e33d44673d10436c28d89d4a8d3814e40bad5a4338b
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERN} -DCMAKE_PREFIX_PATH=${EXTERN} -DBUILD_SHARED_LIBS=OFF -Dwebp=OFF -Dlzma=ON -Dzstd=ON -DCMAKE_DISABLE_FIND_PACKAGE_GLUT=TRUE
		# Build only needed tiff target; uses multiple threads if [mingw32-]make or ninja is used
		BUILD_COMMAND ${CMAKE_MAKE_PROGRAM} tiff
		# Install only needed files
		INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_if_different ${TIFF_BIN_DIR}/libtiff/${TIFF_FILE_NAME} ${EXTERN_LIB_DIR}/${TIFF_FILE_NAME}
		COMMAND ${CMAKE_COMMAND} -E copy_if_different ${TIFF_BIN_DIR}/libtiff/tiffconf.h ${EXTERN_INC_DIR}/tiffconf.h
		COMMAND ${CMAKE_COMMAND} -E copy_if_different ${TIFF_SRC_DIR}/libtiff/tiff.h ${EXTERN_INC_DIR}/tiff.h
		COMMAND ${CMAKE_COMMAND} -E copy_if_different ${TIFF_SRC_DIR}/libtiff/tiffio.h ${EXTERN_INC_DIR}/tiffio.h
		COMMAND ${CMAKE_COMMAND} -E copy_if_different ${TIFF_SRC_DIR}/libtiff/tiffvers.h ${EXTERN_INC_DIR}/tiffvers.h
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		DEPENDS ${LIB_ZLIB} ${LIB_JPEG} ${LIB_ZSTD} ${LIB_LZMA}
	)	

	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(tiff STATIC IMPORTED)
	set_property(TARGET tiff PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${TIFF_FILE_NAME}")
	add_dependencies(tiff tiff-extern)
	target_link_libraries(tiff INTERFACE ${LIB_ZLIB} ${LIB_JPEG} ${LIB_LZMA} ${LIB_ZSTD})
	set(LIB_TIFF tiff)

endif()
