# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only


if(USE_SYSTEM_LIBS AND NOT STATIC_BUILD)

	find_package(ZLIB REQUIRED)		# This only finds shared libs
	set(LIB_ZLIB ${ZLIB::ZLIB})
	list(APPEND ALL_EXTERN_INC_DIRS ${ZLIB_INCLUDE_DIRS})
	
else() # Local static build

	# TODO: Filenames for other platforms and dynamic library
	set(ZLIB_FILE_NAME "")
	if(MSVC)
		set(ZLIB_FILE_NAME "zlibstatic.lib")
	elseif(MINGW)
		set(ZLIB_FILE_NAME "libzlibstatic.a")
	endif()
	set(ZLIB_BIN_DIR ${EXTERN}/src/zlib-extern-build)
	set(ZLIB_SRC_DIR ${EXTERN}/src/zlib-extern)

	ExternalProject_Add(
		zlib-extern
		PREFIX ${EXTERN}
		URL https://zlib.net/zlib1211.zip
		URL_HASH SHA256=d7510a8ee1918b7d0cad197a089c0a2cd4d6df05fee22389f67f115e738b178d
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERN} -DBUILD_SHARED_LIBS=OFF
		# Only need zlibstatic target
		BUILD_COMMAND ${CMAKE_COMMAND} --build . -j ${THREADS} -t zlibstatic
		# We only install needed files
		INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_if_different ${ZLIB_BIN_DIR}/${ZLIB_FILE_NAME} ${EXTERN_LIB_DIR}/${ZLIB_FILE_NAME}
		COMMAND ${CMAKE_COMMAND} -E copy_if_different ${ZLIB_BIN_DIR}/zconf.h ${EXTERN_INC_DIR}/zconf.h
		COMMAND ${CMAKE_COMMAND} -E copy_if_different ${ZLIB_SRC_DIR}/zlib.h ${EXTERN_INC_DIR}/zlib.h
		COMMAND ${CMAKE_COMMAND} -E copy_if_different ${ZLIB_BIN_DIR}/zlib.pc ${EXTERN}/share/pkgconfig/zlib.pc
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)	

	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(zlib STATIC IMPORTED)
	set_property(TARGET zlib PROPERTY
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ZLIB_FILE_NAME}"
		# Include dir is set in base CmakeLists file
	)
	add_dependencies(zlib zlib-extern)
	set(LIB_ZLIB zlib)

endif()