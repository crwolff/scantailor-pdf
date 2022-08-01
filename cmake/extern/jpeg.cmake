# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND NOT STATIC_BUILD)

	find_package(JPEG REQUIRED)		# This only finds shared libs
	set(LIB_JPEG JPEG::JPEG)
	list(APPEND ALL_EXTERN_INC_DIRS ${JPEG_INCLUDE_DIRS})
	
else() # Local build

	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_JPEG_STATIC "jpeg-static.lib")
		set(ST_JPEG_SHARED "jpeg.lib")
		set(ST_JPEG_DLL "jpeg.dll")
	elseif(MINGW)
		set(ST_JPEG_STATIC "libjpeg.a")
		set(ST_JPEG_SHARED "libjpeg.dll.a")
		set(ST_JPEG_DLL "libjpeg-8.dll")
	elseif(APPLE)
		set(ST_JPEG_STATIC "libjpeg.a")
		set(ST_JPEG_SHARED "libjpeg.dylib")
	else() # *nix and the rest
		set(ST_JPEG_STATIC "libjpeg.a")
		set(ST_JPEG_SHARED "libjpeg.so")
	endif()

	if(STATIC_BUILD)
		ExternalProject_Add(
			jpeg-extern
			PREFIX ${EXTERN}
			URL https://sourceforge.net/projects/libjpeg-turbo/files/2.1.2/libjpeg-turbo-2.1.2.tar.gz/download
			URL_MD5 e181bd78884dd5392a869209bfa41d4a
			CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERN} -DWITH_TURBOJPEG=OFF -DWITH_JPEG8=ON
			# Build only needed jpeg-static target; uses multiple threads if [mingw32-]make or ninja is used
			BUILD_COMMAND ${CMAKE_MAKE_PROGRAM} jpeg-static
			# Manually install only needed files; more files are installed below
			INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_if_different <BINARY_DIR>/${ST_JPEG_STATIC} ${EXTERN_LIB_DIR}/${ST_JPEG_STATIC}
			UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		)
	else() # Shared build
		ExternalProject_Add(
			jpeg-extern
			PREFIX ${EXTERN}
			URL https://sourceforge.net/projects/libjpeg-turbo/files/2.1.2/libjpeg-turbo-2.1.2.tar.gz/download
			URL_MD5 e181bd78884dd5392a869209bfa41d4a
			CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERN} -DWITH_TURBOJPEG=OFF -DWITH_JPEG8=ON
			# Build only needed jpeg target; uses multiple threads if [mingw32-]make or ninja is used
			BUILD_COMMAND ${CMAKE_MAKE_PROGRAM} jpeg
			# Manually install only needed files; more files are installed below
			INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_if_different <BINARY_DIR>/${ST_JPEG_SHARED} ${EXTERN_LIB_DIR}/${ST_JPEG_SHARED}
			COMMAND ${CMAKE_COMMAND} -E copy_if_different <BINARY_DIR>/${ST_JPEG_DLL} ${EXTERN_BIN_DIR}/${ST_JPEG_DLL}
			UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		)
	endif()
	
	# Install files common for shared and static build
	ExternalProject_Add_Step(
		jpeg-extern jpeg-install
		DEPENDEES install
		COMMAND ${CMAKE_COMMAND} -E copy_directory <BINARY_DIR>/CMakeFiles/Export/lib/cmake/libjpeg-turbo ${EXTERN_LIB_DIR}/cmake/libjpeg-turbo
		COMMAND ${CMAKE_COMMAND} -E copy_if_different <BINARY_DIR>/pkgscripts/libjpeg-turboConfigVersion.cmake ${EXTERN_LIB_DIR}/cmake/libjpeg-turbo/libjpeg-turboConfigVersion.cmake
		COMMAND ${CMAKE_COMMAND} -E copy_if_different <BINARY_DIR>/pkgscripts/libjpeg-turboConfig.cmake ${EXTERN_LIB_DIR}/cmake/libjpeg-turbo/libjpeg-turboConfig.cmake
		COMMAND ${CMAKE_COMMAND} -E copy_if_different <SOURCE_DIR>/jpeglib.h ${EXTERN_INC_DIR}/jpeglib.h
		COMMAND ${CMAKE_COMMAND} -E copy_if_different <SOURCE_DIR>/jerror.h ${EXTERN_INC_DIR}/jerror.h
		COMMAND ${CMAKE_COMMAND} -E copy_if_different <SOURCE_DIR>/jmorecfg.h ${EXTERN_INC_DIR}/jmorecfg.h
		COMMAND ${CMAKE_COMMAND} -E copy_if_different <BINARY_DIR>/jconfig.h ${EXTERN_INC_DIR}/jconfig.h
		COMMAND ${CMAKE_COMMAND} -E copy_if_different <BINARY_DIR>/pkgscripts/libjpeg.pc ${EXTERN_LIB_DIR}/pkgconfig/libjpeg.pc
	)

	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	if(STATIC_BUILD)
		add_library(jpeg STATIC IMPORTED)
		set_property(TARGET jpeg
			PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_JPEG_STATIC}"
		)
	else() # Shared
		add_library(jpeg SHARED IMPORTED)
		if(WIN32)
			set_target_properties(jpeg PROPERTIES
				IMPORTED_LOCATION "${EXTERN_BIN_DIR}/${ST_JPEG_DLL}"
				IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_JPEG_SHARED}"
			)
		else() # *nix
			set_property(TARGET jpeg
				PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_JPEG_SHARED}"
			)
		endif()
	endif()
	
	add_dependencies(jpeg jpeg-extern)
	set(LIB_JPEG jpeg)

endif()
