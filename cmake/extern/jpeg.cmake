# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND BUILD_SHARED_LIBS)

	find_package(JPEG REQUIRED)		# This only finds shared libs
	set(LIB_JPEG JPEG::JPEG)
	list(APPEND ALL_EXTERN_INC_DIRS ${JPEG_INCLUDE_DIRS})
	
else() # Local build

	ExternalProject_Add(
		jpeg-extern
		PREFIX ${EXTERN}
		URL https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/3.0.4/libjpeg-turbo-3.0.4.tar.gz
		URL_HASH SHA256=99130559e7d62e8d695f2c0eaeef912c5828d5b84a0537dcb24c9678c9d5b76b
		DOWNLOAD_DIR ${DOWNLOAD_DIR}
		CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
			-DCMAKE_PREFIX_PATH=<INSTALL_DIR>
			-DCMAKE_BUILD_TYPE=Release
			-DENABLE_SHARED=${SHARED_BOOL}
			-DENABLE_STATIC=${STATIC_BOOL}
			-DWITH_TURBOJPEG=OFF
			-DWITH_JPEG8=ON
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)


	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_JPEG_STATIC "jpeg-static.lib")	#checked
		set(ST_JPEG_IMPLIB "jpeg.lib")			#checked
		set(ST_JPEG_SHARED "jpeg8.dll")			#checked
	elseif(MINGW)
		set(ST_JPEG_STATIC "libjpeg.a")			#checked
		set(ST_JPEG_IMPLIB "libjpeg.dll.a")		#checked
		set(ST_JPEG_SHARED "libjpeg-8.dll")		#checked
	elseif(APPLE)
		set(ST_JPEG_STATIC "libjpeg.a")
		set(ST_JPEG_SHARED "libjpeg.8.dylib")
	else() # *nix and the rest
		set(ST_JPEG_STATIC "libjpeg.a")
		set(ST_JPEG_SHARED "libjpeg.so.8")
	endif()


	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(jpeg ${LIB_TYPE} IMPORTED)
	set_target_properties(jpeg PROPERTIES
		IMPORTED_CONFIGURATIONS $<CONFIG>
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		INTERFACE_INCLUDE_DIRECTORIES ${EXTERN_INC_DIR}
	)
	
	if(BUILD_SHARED_LIBS)
		set_target_properties(jpeg PROPERTIES
			IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_JPEG_SHARED}"
			# Ignored on non-WIN32 platforms
			IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_JPEG_IMPLIB}"
		)
	else() # STATIC	
		set_target_properties(jpeg PROPERTIES
			IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_JPEG_STATIC}"
		)
	endif()

	add_dependencies(jpeg jpeg-extern)
	set(LIB_JPEG jpeg)

endif()
