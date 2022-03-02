# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(USE_SYSTEM_LIBS AND NOT STATIC_BUILD)

	find_package(PNG REQUIRED)		# This only finds shared libs
	set(LIB_PNG ${PNG::PNG})
	list(APPEND ALL_EXTERN_INC_DIRS ${PNG_INCLUDE_DIRS})
	
else() # Local static build
	
	# TODO: Filenames for other platforms and dynamic library
	set(PNG_FILE_NAME "")
	if(MSVC)
		set(PNG_FILE_NAME "libpng.lib")
	elseif(MINGW)
		set(PNG_FILE_NAME "libpng.a")
	endif()
	
	ExternalProject_Add(
		png-extern
		PREFIX ${EXTERN}
		URL https://download.sourceforge.net/libpng/lpng1637.zip
		URL_HASH SHA256=3b4b1cbd0bae6822f749d39b1ccadd6297f05e2b85a83dd2ce6ecd7d09eabdf2
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERN} -DCMAKE_PREFIX_PATH=${EXTERN} -DPNG_STATIC=ON -DPNG_SHARED=OFF -DSKIP_INSTALL_EXECUTABLES=ON -DSKIP_INSTALL_PROGRAMS=ON  -DPNG_TESTS=OFF
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		DEPENDS ${LIB_ZLIB}
	)	

	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(png STATIC IMPORTED)
	set_property(TARGET png PROPERTY
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${PNG_FILE_NAME}"
		# Include dir is set in base CmakeLists file
	)
	add_dependencies(png png-extern)
	target_link_libraries(png INTERFACE ${LIB_ZLIB})
	set(LIB_PNG png)

endif()
