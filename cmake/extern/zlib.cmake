# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only


if(NOT WIN32 AND BUILD_SHARED_LIBS)

	find_package(ZLIB REQUIRED)		# This only finds shared libs
	
else() # Local build

	# This should set the search options for zlib globally
	set(ZLIB_USE_STATIC_LIBS ON CACHE BOOL "Make find_package find the correct build type of zlib." FORCE)
	set(ZLIB_ROOT ${EXTERN} CACHE FILEPATH "Use locally build zlib")
	if(BUILD_SHARED_LIBS)
		set(ZLIB_USE_STATIC_LIBS OFF CACHE BOOL "Make find_package find the correct build type of zlib." FORCE)
	endif()

	# Zlib has no cmake target files so we need to use basic find_package mode
	find_package(ZLIB	QUIET GLOBAL)

	if(ZLIB_FOUND)

		message(STATUS "Found zlib: ${ZLIB_LIBRARIES} (version ${ZLIB_VERSION})")
		# Needed for dependency satisfaction after external project has been built
		add_custom_target(zlib-extern DEPENDS ZLIB::ZLIB)

	else()	# zlib has not been built yet. Configure for build.
	
		set(HAVE_DEPENDENCIES FALSE)

		ExternalProject_Add(
			zlib-extern
			PREFIX ${EXTERN}
			URL https://www.zlib.net/zlib-1.3.1.tar.xz
			URL_HASH SHA256=38ef96b8dfe510d42707d9c781877914792541133e1870841463bfa73f883e32
			DOWNLOAD_DIR ${DOWNLOAD_DIR}
			CMAKE_ARGS
				-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
				-DCMAKE_PREFIX_PATH=<INSTALL_DIR>
				-DCMAKE_BUILD_TYPE=Release
			BUILD_COMMAND
				${CMAKE_COMMAND} --build <BINARY_DIR> --config Release
			INSTALL_COMMAND
				${CMAKE_COMMAND} --install <BINARY_DIR> --config Release
			UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		)
		
		# zlib installs both shared and static libs. If building static,
		# we need to remove the shared lib, so they don't get picked up by other packages
		# if(NOT BUILD_SHARED_LIBS)
		# 	ExternalProject_Add_Step(
		# 		zlib-extern remove-shared
		# 		DEPENDEES install
		# 		COMMAND ${CMAKE_COMMAND} -E rm -f ${EXTERN_BIN_DIR}/${ST_ZLIB_SHARED}
		# 		COMMAND ${CMAKE_COMMAND} -E rm -f ${EXTERN_LIB_DIR}/${ST_ZLIB_IMPLIB}
		# 	)
		# 	if(MSVC)
		# 		# hardlink the static lib to the shared lib name so it gets picked up by qt5 for msvc
		# 		ExternalProject_Add_Step(
		# 			zlib-extern qt5-compat-install
		# 			DEPENDEES remove-shared
		# 			COMMAND ${CMAKE_COMMAND} -E create_hardlink ${EXTERN_LIB_DIR}/${ST_ZLIB_STATIC} ${EXTERN_LIB_DIR}/${ST_ZLIB_IMPLIB}
		# 		)
		# 	endif()
		# endif()
	endif()
endif()
