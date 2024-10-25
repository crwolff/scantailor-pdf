# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND BUILD_SHARED_LIBS)

	find_package(TIFF REQUIRED)		# This only finds shared libs
	
else() # Local build

	# Check if we built the package already
	find_package(tiff
		NO_MODULE				# Don't use installed modules for the search
		NO_DEFAULT_PATH		# Only search in ${EXTERN}
		HINTS ${EXTERN}
		QUIET
	)

	if(tiff_FOUND)

		# Add alias for podofo compatibility
		add_library(TIFF::TIFF ALIAS TIFF::tiff)
		# Fix Tiff not linking against lzma and zstd
		target_link_libraries(TIFF::tiff INTERFACE liblzma::liblzma zstd)

		message(STATUS "Found tiff in ${tiff_DIR}")
		# Needed for dependency satisfaction after external project has been built
		add_custom_target(tiff-extern DEPENDS TIFF::tiff)

	else()	# tiff has not been built yet. Configure for build.
	
		set(HAVE_DEPENDENCIES FALSE)

		ExternalProject_Add(
			tiff-extern
			URL https://download.osgeo.org/libtiff/tiff-4.7.0.tar.xz
			URL_HASH SHA256=273a0a73b1f0bed640afee4a5df0337357ced5b53d3d5d1c405b936501f71017
			DOWNLOAD_DIR ${DOWNLOAD_DIR}
			PREFIX ${EXTERN}
			# Fix MSVC static linking ot lzma
			PATCH_COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN_PATCH_DIR}/tiff/libtiff/CMakeLists.txt <SOURCE_DIR>/libtiff
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
				-DCMAKE_MODULE_PATH=
				-DZLIB_USE_STATIC_LIBS=${ZLIB_USE_STATIC_LIBS}
			BUILD_COMMAND
				${CMAKE_COMMAND} --build <BINARY_DIR> --config Release
			INSTALL_COMMAND
				${CMAKE_COMMAND} --install <BINARY_DIR> --config Release
			UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
			DEPENDS zlib-extern jpeg-extern zstd-extern lzma-extern
		)

		
		# <LINK_ONLY> dependencies cannot be found in external projects,
		# if they don't find_package() for them. Fix it.
		if(NOT BUILD_SHARED_LIBS)
			ExternalProject_Add_Step(
				tiff-extern after-install-patch
				DEPENDEES install
				COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN_PATCH_DIR}/tiff/TiffTargets.cmake ${EXTERN}/lib/cmake/tiff/
			)
		endif()
	endif()
endif()
