# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND NOT STATIC_BUILD)

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
			-DCMAKE_INSTALL_PREFIX=${EXTERN}
			-DCMAKE_PREFIX_PATH=${EXTERN}
			-DCMAKE_BUILD_TYPE=Release   # Only build release type for external libs
			-DENABLE_SHARED=ON
			-DENABLE_STATIC=ON
			-DWITH_TURBOJPEG=OFF
			-DWITH_JPEG8=ON
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)


	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_JPEG_STATIC "jpeg-static.lib")
		set(ST_JPEG_SHARED "jpeg.lib")
		set(ST_JPEG_DLL "jpeg8.dll")
	elseif(MINGW)
		set(ST_JPEG_STATIC "libjpeg.a")		#checked
		set(ST_JPEG_SHARED "libjpeg.dll.a")	#checked
		set(ST_JPEG_DLL "libjpeg-8.dll")		#checked
	elseif(APPLE)
		set(ST_JPEG_STATIC "libjpeg.a")
		set(ST_JPEG_SHARED "libjpeg.8.dylib")
	else() # *nix and the rest
		set(ST_JPEG_STATIC "libjpeg.a")
		set(ST_JPEG_SHARED "libjpeg.so.8")
	endif()


	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(jpeg SHARED IMPORTED)
	add_library(jpeg-static STATIC IMPORTED)

	set_property(
		TARGET jpeg jpeg-static APPEND PROPERTY IMPORTED_CONFIGURATIONS $<CONFIG>
	)
	
	# Shared properties
	set_target_properties(jpeg PROPERTIES
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_JPEG_SHARED}"
		# Ignored on non-WIN32 platforms
		IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_JPEG_IMPLIB}" 
	)
	
	# Static properties
	set_target_properties(jpeg-static PROPERTIES
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_JPEG_STATIC}"
	)
	
	add_dependencies(jpeg jpeg-extern)
	add_dependencies(jpeg-static jpeg-extern)
	
	# Select the correct build type; this should switch the target,
	# if the user changes build type (e.g. -DBUILD_SHARED_LIBS=OFF)
	if(STATIC_BUILD)
		set(LIB_JPEG jpeg-static)
	else()
		set(LIB_JPEG jpeg)
	endif()

endif()
