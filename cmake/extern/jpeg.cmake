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
		set(ST_JPEG_DLL "jpeg8.dll")
	elseif(MINGW)
		set(ST_JPEG_STATIC "libjpeg.a")
		set(ST_JPEG_SHARED "libjpeg.dll.a")
		set(ST_JPEG_DLL "libjpeg-8.dll")
	elseif(APPLE)
		set(ST_JPEG_STATIC "libjpeg.a")
		set(ST_JPEG_SHARED "libjpeg.8.dylib")
	else() # *nix and the rest
		set(ST_JPEG_STATIC "libjpeg.a")
		set(ST_JPEG_SHARED "libjpeg.so.8")
	endif()

	ExternalProject_Add(
		jpeg-extern
		PREFIX ${EXTERN}
		URL https://sourceforge.net/projects/libjpeg-turbo/files/2.1.2/libjpeg-turbo-2.1.2.tar.gz/download
		URL_MD5 e181bd78884dd5392a869209bfa41d4a
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERN} -DWITH_TURBOJPEG=OFF -DWITH_JPEG8=ON -DENABLE_PROGRAMS=OFF
		# Disable building and installing all programs
		PATCH_COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN_PATCH_DIR}/jpeg-extern/CMakeLists.txt <SOURCE_DIR>/CMakeLists.txt
		COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN_PATCH_DIR}/jpeg-extern/sharedlib/CMakeLists.txt <SOURCE_DIR>/sharedlib/CMakeLists.txt
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
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
