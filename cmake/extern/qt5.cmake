# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND NOT STATIC_BUILD)

	find_package(Qt5 COMPONENTS Core Gui Widgets Xml Network LinguistTools REQUIRED)
	if(ENABLE_OPENGL)
		find_package(Qt5 COMPONENTS OpenGL REQUIRED)
	endif()
	# Now, use the QT5::* targets.
	
else() # Local build
			
	if(EXISTS ${EXTERN}/lib/cmake/Qt5LinguistTools)
		# Tell find_package() where to find Qt5
		set(Qt5_DIR "${EXTERN}") #/src/qt5-base-extern-build/lib/cmake/Qt5")
		find_package(Qt5 COMPONENTS Core Gui Widgets Xml Network LinguistTools REQUIRED)
		if(ENABLE_OPENGL)
			find_package(Qt5 COMPONENTS OpenGL REQUIRED)
		endif()
		# For a static build, we have to add more dependencies manually
		if(STATIC_BUILD)
			target_link_libraries(Qt5::Gui INTERFACE ${LIB_PNG} "${EXTERN}/lib/libqtharfbuzz.a")
			target_link_libraries(Qt5::Core INTERFACE "${EXTERN}/lib/libqtpcre2.a")
		endif()
		# Now, use the QT5::* targets.
		
	else() # Qt5 has not been built yet. Configure for build.
		
		message(STATUS "Qt5 has not been fully built yet. "
							"After the first build without errors, just rerun the cmake configuration "
							"and generation steps and it should find Qt5 and build fine.")
		
		set(HAVE_DEPENDENCIES FALSE)
		
		set(QT5_STATIC_OPTIONS "")
		if (STATIC_BUILD)
			set(QT5_STATIC_OPTIONS -static -static-runtime)
		endif()


		# Find number of available threads for multithreaded compilation of QT5
		include(ProcessorCount)
		ProcessorCount(N)
		math(EXPR THREADS "${N} - 1")
		if(NOT N EQUAL 0)
			set(JX "-j${THREADS}")
		endif()

		# Setting the right mkspecs; this does not cover all… by far… and might not be correct…
		set(QT5_MAKE "")
		set(QT5_PLATFORM "")
		if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
			if (CMAKE_CXX_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC")
				set(QT5_MAKE nmake)
				set(QT5_PLATFORM win32-clang-msvc)
			elseif (CMAKE_CXX_COMPILER_FRONTEND_VARIANT STREQUAL "GNU")
				if(MINGW)
					set(QT5_MAKE mingw32-make ${JX})
					set(QT5_PLATFORM win32-clang-g++)
				elseif(UNIX)
					set(QT5_MAKE make ${JX})
					set(QT5_PLATFORM linux-clang)
				endif()
			endif()
		elseif(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
			set(QT5_MAKE make ${JX})
			set(QT5_PLATFORM macx-clang)
		elseif (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
			if(MINGW)
				set(QT5_MAKE mingw32-make ${JX})
				set(QT5_PLATFORM win32-g++)
			elseif(CYGWIN)
				set(QT5_MAKE make ${JX})
				set(QT5_PLATFORM cygwin-g++)
			elseif(UNIX)
				set(QT5_MAKE make ${JX})
				set(QT5_PLATFORM linux-g++)
			endif()
		elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Intel")
			set(QT5_PLATFORM win32-icc)
		elseif (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
			# find_program(JOM NAMES jom)
			# if(JOM)
				# set(QT5_MAKE ${JOM})
			# else()
			# endif()
			set(QT5_MAKE nmake)
			set(QT5_PLATFORM win32-msvc)
		endif()
		
		if(NOT QT5_PLATFORM)
			message(FATAL_ERROR
				"Platform and compiler combination currently not supported!"
			)	
		endif()

		ExternalProject_Add(
			qt5-base-extern
			PREFIX ${EXTERN}
			URL https://download.qt.io/official_releases/qt/5.15/5.15.5/submodules/qtbase-everywhere-opensource-src-5.15.5.tar.xz
			URL_HASH SHA256=0c42c799aa7c89e479a07c451bf5a301e291266ba789e81afc18f95049524edc
			# Qt bug with MinGW: https://bugreports.qt.io/browse/QTBUG-94031
			PATCH_COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN_PATCH_DIR}/qt5-base-extern/src/corelib/io/qfilesystemengine_win.cpp <SOURCE_DIR>/src/corelib/io/qfilesystemengine_win.cpp
			CONFIGURE_COMMAND ${EXTERN}/src/qt5-base-extern/configure -platform ${QT5_PLATFORM} -debug-and-release ${QT5_STATIC_OPTIONS} -force-debug-info -no-ltcg -prefix ${EXTERN} -no-gif -no-dbus -system-zlib -system-libpng -system-libjpeg -qt-pcre -no-openssl -opengl desktop -nomake examples -nomake tests -silent -opensource -confirm-license ${MP} -L ${EXTERN_LIB_DIR} -I ${EXTERN_INC_DIR}
			# The next to need to be set. Otherwise QT might use the wrong make.
			BUILD_COMMAND ${QT5_MAKE}
			INSTALL_COMMAND ${QT5_MAKE} install
			UPDATE_COMMAND ""   # Don't rebuild on main project recompilation
			DEPENDS ${LIB_ZLIB} ${LIB_JPEG} ${LIB_PNG} ${LIB_FREETYPE}
		)
		
		if(MINGW AND NOT STATIC_BUILD)
			ExternalProject_Add_Step(
				qt5-base-extern custom-patch
				DEPENDEES configure
				DEPENDERS build
				# Copy some libs into qt5 build bin dir; it seems to be missing for moc, etc. for the shared mingw build.
				COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN_BIN_DIR}/libzlib1.dll <BINARY_DIR>/bin/libzlib1.dll
				COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN_BIN_DIR}/libzstd.dll <BINARY_DIR>/bin/libzstd.dll
			)
		endif()
		
		ExternalProject_Add(
			qt-tools
			PREFIX ${EXTERN}
			URL https://download.qt.io/official_releases/qt/5.15/5.15.5/submodules/qttools-everywhere-opensource-src-5.15.5.tar.xz
			URL_HASH SHA256=6d0778b71b2742cb527561791d1d3d255366163d54a10f78c683a398f09ffc6c
			CONFIGURE_COMMAND ${EXTERN}/src/qt5-base-extern-build/bin/qmake -makefile -after "CONFIG += release" <SOURCE_DIR>/${QT_TOOLS}
			# The next to need to be set. Otherwise QT might use the wrong make.
			BUILD_COMMAND ${QT5_MAKE}
			INSTALL_COMMAND ${QT5_MAKE} install
			UPDATE_COMMAND ""   # Don't rebuild on main project recompilation
			DEPENDS qt5-base-extern
		)
		
		if(NOT BUILD_QT_TOOLS)
			# Build only linguist and its dependencies
			ExternalProject_Add_Step(
				qt-tools custom-patch
				DEPENDEES configure
				DEPENDERS build
				# Patch to build files to only build linguist tool and windeployqt and their dependencies
				COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN_PATCH_DIR}/qt-tools/src/src.pro ${EXTERN}/src/qt-tools/src/src.pro
				COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN_PATCH_DIR}/qt-tools/src/designer/src/src.pro ${EXTERN}/src/qt-tools/src/designer/src/src.pro
			)
		endif()
		
		# When using lhmouse's MinGW distribution, the threading lib cannot be statically linked.
		# Also, we might need some system runtimes. Gather all of them into a list.
		set(RUNTIME_FILES "")
		if(MINGW)
			find_file(mcf NAMES mcfgthread-12.dll libmcfgthread-1.dll HINTS ENV PATH)
			if(NOT STATIC_BUILD)
				find_file(libgcc NAMES libgcc_s_seh-1.dll HINTS ENV PATH)
				find_file(libstdc NAMES libstdc++-6.dll HINTS ENV PATH)
				find_file(run_zlib NAMES zlib1.dll HINTS ENV PATH)
				list(APPEND RUNTIME_FILES ${libgcc} ${libstdc} ${run_zlib} ${mcf})
			endif()
		endif()
		
		# Copy the runtime files if needed
		if(RUNTIME_FILES)
			ExternalProject_Add_Step(
				qt-tools post-install
				DEPENDEES install
				COMMAND ${CMAKE_COMMAND} -E copy_if_different ${RUNTIME_FILES} ${EXTERN_BIN_DIR}
			)
		endif()
		
		# Copy QT5 files if needed
		if(EXISTS ${EXTERN_BIN_DIR}/designer.exe)
			ExternalProject_Add_Step(
				qt-tools post-post-install
				DEPENDEES post-install
				# This also copies the system runtime files, but we have to copy them for windeployqt to work…
				COMMAND ${EXTERN_BIN_DIR}/windeployqt --release --no-translations --dir ${EXTERN_BIN_DIR} ${EXTERN_BIN_DIR}/designer.exe
			)
		endif()
		
		# Strip utility programs of Qt5 and some static libraries to reduce the huge size.
		# We don't need debug symbols in them. Debugging QT applications is still possible.
		if(MINGW OR GNU)
			# Adding ExternalProject_Add_Step() does not work as some files are stripped before linking.
			# This is probably due to parallel compilation of make.
			add_custom_command(
				TARGET qt-tools POST_BUILD
				COMMAND strip ARGS ./bin/*.exe
				COMMAND strip ARGS ./src/qt5-base-extern-build/bin/*.exe
				COMMAND strip ARGS ./src/qt-tools-build/bin/*.exe
				COMMAND strip ARGS ./src/qt-tools-build/lib/*.a
				WORKING_DIRECTORY ${EXTERN}
			)
		endif()
		
		## Print a message after Qt build to remind to run cmake again
		add_custom_command(
			TARGET qt-tools POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E cmake_echo_color --cyan
			" "
			"All dependencies have been built."
			"Please re-run cmake."
			" "
		)
	endif()

endif()
