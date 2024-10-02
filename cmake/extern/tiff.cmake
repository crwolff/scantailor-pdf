# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND BUILD_SHARED_LIBS)

	find_package(TIFF REQUIRED)		# This only finds shared libs
	set(LIB_TIFF TIFF::TIFF)
	list(APPEND ALL_EXTERN_INC_DIRS ${TIFF_INCLUDE_DIRS})
	
else() # Local build
		
	ExternalProject_Add(
		tiff-extern
		URL https://download.osgeo.org/libtiff/tiff-4.7.0.tar.xz
		URL_HASH SHA256=273a0a73b1f0bed640afee4a5df0337357ced5b53d3d5d1c405b936501f71017
		DOWNLOAD_DIR ${DOWNLOAD_DIR}
		PREFIX ${EXTERN}
		CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
			-DCMAKE_PREFIX_PATH=<INSTALL_DIR>
			-DCMAKE_BUILD_TYPE=Release
			-DBUILD_SHARED_LIBS=${SHARED_BOOL}
			-Dwebp=OFF
			-Dlzma=ON
			-Dzstd=ON
			-Dtiff-tools=OFF
			-Dtiff-tests=OFF
			-Dtiff-contrib=OFF
			-Dtiff-docs=OFF
			-DCMAKE_DISABLE_FIND_PACKAGE_GLUT=TRUE
			-DCMAKE_DISABLE_FIND_PACKAGE_Deflate=TRUE
			-DCMAKE_DISABLE_FIND_PACKAGE_JBIG=TRUE
			-DCMAKE_DISABLE_FIND_PACKAGE_LERC=TRUE
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		DEPENDS ${LIB_ZLIB} ${LIB_JPEG} ${LIB_ZSTD} ${LIB_LZMA}
	)

	
	# Tiff sets some weird targets as linking dependencies; replace with our own
	if(MINGW AND NOT BUILD_SHARED_LIBS)
		ExternalProject_Add_Step(
			tiff-extern after-install-patch
			DEPENDEES install
			COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN_PATCH_DIR}/tiff/TiffTargets.cmake ${EXTERN}/lib/cmake/tiff/TiffTargets.cmake
		)
	endif()

	# TODO: Filenames for other platforms and dynamic library
	if(MSVC)
		set(ST_TIFF_STATIC "tiff.lib")	#checked
		set(ST_TIFF_IMPLIB "tiff.lib")	#checked
		set(ST_TIFF_SHARED "tiff.dll")	#checked
	elseif(MINGW)
		set(ST_TIFF_STATIC "libtiff.a")		#checked
		set(ST_TIFF_IMPLIB "libtiff.dll.a")
		set(ST_TIFF_SHARED "libtiff.dll")
	elseif(APPLE)
		set(ST_TIFF_STATIC "libtiff.a")
		set(ST_TIFF_SHARED "libtiff.dylib")
	else() # *nix and the rest
		set(ST_TIFF_STATIC "libtiff.a")
		set(ST_TIFF_SHARED "libtiff.so")
	endif()


	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(tiff ${LIB_TYPE} IMPORTED)
	set_target_properties(tiff PROPERTIES
		IMPORTED_CONFIGURATIONS $<CONFIG>
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		INTERFACE_INCLUDE_DIRECTORIES ${EXTERN_INC_DIR}
	)
	target_link_libraries(tiff INTERFACE ${LIB_ZLIB} ${LIB_JPEG} ${LIB_LZMA} ${LIB_ZSTD})
	
	if(BUILD_SHARED_LIBS)
		set_target_properties(tiff PROPERTIES
			IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_TIFF_SHARED}"
			# Ignored on non-WIN32 platforms
			IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_TIFF_IMPLIB}"
		)
	else()
		set_target_properties(tiff PROPERTIES
			IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_TIFF_STATIC}"
		)
	endif()

	add_dependencies(tiff tiff-extern)
	set(LIB_TIFF tiff)

endif()
