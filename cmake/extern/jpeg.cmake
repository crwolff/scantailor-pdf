# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND BUILD_SHARED_LIBS)

	find_package(JPEG REQUIRED)		# This only finds shared libs
	
else() # Local build

	# Check if we built the package already
	find_package(libjpeg-turbo
		NO_MODULE				# Don't use installed modules for the search
		NO_DEFAULT_PATH		# Only search in ${EXTERN}
		HINTS ${EXTERN}
		QUIET
	)

	if(libjpeg-turbo_FOUND)

		if(BUILD_SHARED_LIBS)
			add_library(JPEG::JPEG ALIAS libjpeg-turbo::jpeg)
		else()
			add_library(JPEG::JPEG ALIAS libjpeg-turbo::jpeg-static)
		endif()
		message(STATUS "Found jpeg in ${libjpeg-turbo_DIR}")
		# Needed for dependency satisfaction after external project has been built
		add_custom_target(jpeg-extern DEPENDS JPEG::JPEG)

	else()	# jpeg has not been built yet. Configure for build.
	
		set(HAVE_DEPENDENCIES FALSE)

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
			BUILD_COMMAND
				${CMAKE_COMMAND} --build <BINARY_DIR> --config Release
			INSTALL_COMMAND
				${CMAKE_COMMAND} --install <BINARY_DIR> --config Release
			UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		)

		# Hardlink static lib to shared name so qt5 can pick up our jpeg under msvc
		# if(NOT BUILD_SHARED_LIBS AND MSVC)
		# 	ExternalProject_Add_Step(
		# 		jpeg-extern qt5-compat-install
		# 		DEPENDEES install
		# 		COMMAND ${CMAKE_COMMAND} -E create_hardlink ${EXTERN_LIB_DIR}/${ST_JPEG_STATIC} ${EXTERN_LIB_DIR}/${ST_JPEG_IMPLIB}
		# 	)
		# endif()
	endif()
endif()
