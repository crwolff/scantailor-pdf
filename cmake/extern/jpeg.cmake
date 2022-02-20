# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only



if(USE_SYSTEM_LIBS AND NOT STATIC_BUILD)

	find_package(JPEG REQUIRED)		# This only finds shared libs
	set(LIB_JPEG ${JPEG::JPEG})
	list(APPEND ALL_EXTERN_INC_DIRS ${JPEG_INCLUDE_DIRS})
	
else() # Local static build

	# TODO: Filenames for other platforms and dynamic library
	set(JPEG_FILE_NAME "")
	if(MSVC)
		set(JPEG_FILE_NAME "jpeg-static.lib")
	elseif(MINGW)
		set(JPEG_FILE_NAME "libjpeg.a")
	endif()
	set(JPEG_BIN_DIR ${EXTERN}/src/jpeg-extern-build)
	set(JPEG_SRC_DIR ${EXTERN}/src/jpeg-extern)

	ExternalProject_Add(
		jpeg-extern
		PREFIX ${EXTERN}
		URL https://sourceforge.net/projects/libjpeg-turbo/files/2.1.2/libjpeg-turbo-2.1.2.tar.gz/download
		URL_MD5 e181bd78884dd5392a869209bfa41d4a
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERN} -DWITH_TURBOJPEG=OFF -DWITH_JPEG8=ON -DENABLE_SHARED=OFF
		# Build only needed jpeg-static target
		BUILD_COMMAND ${CMAKE_COMMAND} --build . -j ${THREADS} -t jpeg-static
		# Manually install only needed files
		INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_if_different ${JPEG_BIN_DIR}/${JPEG_FILE_NAME} ${EXTERN_LIB_DIR}/${JPEG_FILE_NAME}
		COMMAND ${CMAKE_COMMAND} -E copy_if_different ${JPEG_BIN_DIR}/pkgscripts/libjpeg.pc ${EXTERN_LIB_DIR}/pkgconfig/libjpeg.pc
		COMMAND ${CMAKE_COMMAND} -E copy_directory ${JPEG_BIN_DIR}/CMakeFiles/Export/lib/cmake/libjpeg-turbo ${EXTERN_LIB_DIR}/cmake/libjpeg-turbo
		COMMAND ${CMAKE_COMMAND} -E copy_if_different ${JPEG_BIN_DIR}/pkgscripts/libjpeg-turboConfigVersion.cmake ${EXTERN_LIB_DIR}/cmake/libjpeg-turbo/libjpeg-turboConfigVersion.cmake
		COMMAND ${CMAKE_COMMAND} -E copy_if_different ${JPEG_BIN_DIR}/pkgscripts/libjpeg-turboConfig.cmake ${EXTERN_LIB_DIR}/cmake/libjpeg-turbo/libjpeg-turboConfig.cmake
		COMMAND ${CMAKE_COMMAND} -E copy_if_different ${JPEG_SRC_DIR}/jpeglib.h ${EXTERN_INC_DIR}/jpeglib.h
		COMMAND ${CMAKE_COMMAND} -E copy_if_different ${JPEG_SRC_DIR}/jerror.h ${EXTERN_INC_DIR}/jerror.h
		COMMAND ${CMAKE_COMMAND} -E copy_if_different ${JPEG_SRC_DIR}/jmorecfg.h ${EXTERN_INC_DIR}/jmorecfg.h
		COMMAND ${CMAKE_COMMAND} -E copy_if_different ${JPEG_BIN_DIR}/jconfig.h ${EXTERN_INC_DIR}/jconfig.h
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)	

	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(jpeg STATIC IMPORTED)
	set_property(TARGET jpeg PROPERTY
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${JPEG_FILE_NAME}"
		# Include dir is set in base CmakeLists file
	)
	add_dependencies(jpeg jpeg-extern)
	set(LIB_JPEG jpeg)

endif()
