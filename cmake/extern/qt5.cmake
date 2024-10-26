# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND BUILD_SHARED_LIBS)

	find_package(Qt5 COMPONENTS Core Gui Widgets Xml Network LinguistTools REQUIRED)
	if(ENABLE_OPENGL)
		find_package(Qt5 COMPONENTS OpenGL REQUIRED)
	endif()
	# Now, use the QT5::* targets.
	
else() # Local build

	if(ENABLE_OPENGL)
		set(ST_Qt5_OPENGL OpenGL)
	endif()

	find_package(Qt5 COMPONENTS Core Gui Widgets Xml Network ${ST_Qt5_OPENGL} LinguistTools
		NO_MODULE				# Don't use installed modules for the search
		NO_DEFAULT_PATH		# Only search in ${EXTERN}
		HINTS ${EXTERN}
		QUIET
	)
	
	if(Qt5_FOUND)
		
		# For a static build, we have to add more dependencies manually
		if(NOT BUILD_SHARED_LIBS AND MINGW)
			target_link_libraries(Qt5::Core INTERFACE "${EXTERN}/lib/libqtpcre2.a")
		endif()
		# Now, use the QT5::* targets.

		message(STATUS "Found Qt5: ${Qt5_DIR}")
		# Needed for dependency satisfaction after external project has been built
		add_custom_target(qt5-base-extern DEPENDS Qt5::Core Qt5::Widgets Qt5::GUI Qt5::XML Qt5::Network)
		
	else() # Qt5 has not been built yet. Configure for build.
		
		set(HAVE_DEPENDENCIES FALSE)
		
		# Depending on the environment and config, we need to set certain qt5 config options
		set(QT5_EXTRA_OPTS)
		
		if(ENABLE_OPENGL)
			set(QT5_EXTRA_OPTS ${QT5_EXTRA_OPTS} -opengl desktop)
		endif()

		if (NOT BUILD_SHARED_LIBS AND MINGW)
			# -static-runtime is only valid for Windows, but we don't want it for MSVC
			# because starting with Win 10, the runtimes we are using are included.
			set(QT5_EXTRA_OPTS ${QT5_EXTRA_OPTS} -static -static-runtime)
		elseif(NOT BUILD_SHARED_LIBS)
			set(QT5_EXTRA_OPTS ${QT5_EXTRA_OPTS} -static)
		endif()

		# MSVC bug where zstd causes corruption of qmimeprovider_database.cpp during build
		if(BUILD_SHARED_LIBS AND MSVC)
			set(QT5_EXTRA_OPTS ${QT5_EXTRA_OPTS} -no-zstd)
		endif()

		# Find number of available threads for multithreaded compilation of QT5
		include(ProcessorCount)
		ProcessorCount(N)
		math(EXPR THREADS "${N} - 1")
		if(NOT N EQUAL 0)
			set(JX "-j${THREADS}")
		endif()

		# Setting the right mkspecs; this does not cover all… by far… and might not be correct…
		set(QT5_MAKE)
		set(QT5_PLATFORM)
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
			set(QT5_MAKE nmake)
			set(QT5_PLATFORM win32-msvc)
		endif()
		
		if(MSVC)
			# Configure QT5 to use multiple processors when using nmake
			if(${CMAKE_GENERATOR} STREQUAL "NMake Makefiles")
				set(QT5_EXTRA_OPTS ${QT5_EXTRA_OPTS} -mp)	# Appended to the QT5 configure step
			else()
				# Use jom if available
				find_program(JOM NAMES jom)
				if(JOM)
					set(QT5_MAKE ${JOM})
				endif()
			endif()
		endif()
		
		if(NOT QT5_PLATFORM)
			message(FATAL_ERROR
				"Platform and compiler combination currently not supported!"
			)	
		endif()

		ExternalProject_Add(
			qt5-base-extern
			PREFIX ${EXTERN}
			URL https://download.qt.io/official_releases/qt/5.15/5.15.15/submodules/qtbase-everywhere-opensource-src-5.15.15.tar.xz
			URL_HASH SHA256=e5f941fecf694ecba97c550b45b0634e552166cc6c815bcfdc481edd62796ba1
			DOWNLOAD_DIR ${DOWNLOAD_DIR}
			# Qt bug with MinGW: https://bugreports.qt.io/browse/QTBUG-94031
			PATCH_COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN_PATCH_DIR}/qt5-base-extern/src/corelib/io/qfilesystemengine_win.cpp <SOURCE_DIR>/src/corelib/io
			# Make Qt configure find our static zlib
			COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN_PATCH_DIR}/qt5-base-extern/configure.json <SOURCE_DIR>
			# Make Qt configure find our static msvc jpeg and png lib
			COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN_PATCH_DIR}/qt5-base-extern/src/gui/configure.json <SOURCE_DIR>/src/gui
			# Under MSVC, sometimes the <BINARY_DIR>/bin folder gets created as a file during bootstrap which prevents linking of qmake.exe
			COMMAND ${CMAKE_COMMAND} -E make_directory <BINARY_DIR>/bin
			CONFIGURE_COMMAND ${EXTERN}/src/qt5-base-extern/configure -platform ${QT5_PLATFORM} -debug-and-release -force-debug-info -no-ltcg -prefix ${EXTERN} -no-gif -no-libmd4c -no-dbus -system-zlib -system-libpng -system-freetype -system-libjpeg -qt-pcre -no-harfbuzz -no-openssl -no-vulkan -nomake examples -nomake tests -silent -opensource -confirm-license ${QT5_EXTRA_OPTS} -I ${EXTERN_INC_DIR} -L ${EXTERN_LIB_DIR}
			BUILD_COMMAND ${QT5_MAKE}
			INSTALL_COMMAND ${QT5_MAKE} install
			UPDATE_COMMAND ""   # Don't rebuild on main project recompilation
			DEPENDS zlib-extern zstd-extern jpeg-extern png-extern freetype-extern
		)
		
		# Fix msvc shared build failing on missing zlib and zstd for rcc in build/bin dir
		if(MSVC AND BUILD_SHARED_LIBS)
			ExternalProject_Add_Step(
				qt5-base-extern post-patch
				DEPENDEES patch
				DEPENDERS build
				COMMAND ${CMAKE_COMMAND} -E copy_if_different ${EXTERN_BIN_DIR}/zlib.dll <BINARY_DIR>/bin
				COMMAND ${CMAKE_COMMAND} -E copy_if_different ${EXTERN_BIN_DIR}/zstd.dll <BINARY_DIR>/bin
			)
		endif()

		# When building with openGL on Windows, the imported QT5::Gui target sets some superfluous implibs
		# in IMPORTED_LINK_DEPENDENT_LIBRARIES_<CONFIG>, which results in them being copied to the staging
		# dir because they show up in TARGET_RUNTIME_DLLS.
		# Remove and create an empty module file to exclude these.
		if(WIN32 AND BUILD_SHARED_LIBS)
			ExternalProject_Add_Step(
				qt5-base-extern post-install
				DEPENDEES install
				COMMAND ${CMAKE_COMMAND} -E rm ${EXTERN_LIB_DIR}/cmake/Qt5Gui/Qt5GuiConfigExtras.cmake
				COMMAND ${CMAKE_COMMAND} -E touch ${EXTERN_LIB_DIR}/cmake/Qt5Gui/Qt5GuiConfigExtras.cmake
			)
		endif()

		ExternalProject_Add(
			qt-tools
			PREFIX ${EXTERN}
			URL https://download.qt.io/official_releases/qt/5.15/5.15.15/submodules/qttools-everywhere-opensource-src-5.15.15.tar.xz
			URL_HASH SHA256=71946704c6bd6c925910288b97dfcc2e357d4a28e22c8651a5813aae4f238028
			DOWNLOAD_DIR ${DOWNLOAD_DIR}
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
			if(BUILD_SHARED_LIBS)
				find_file(libc NAMES libc++.dll HINTS ENV PATH)					# clang
				find_file(libgcc NAMES libgcc_s_seh-1.dll HINTS ENV PATH)	# mingw & ucrt
				find_file(libstdc NAMES libstdc++-6.dll HINTS ENV PATH)		# mingw & ucrt
				list(APPEND RUNTIME_FILES ${libc} ${libgcc} ${libstdc} ${run_zlib} ${mcf})
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
				# This also copies the system runtime files, but we have to copy them for windeployqt above to work…
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
		
	endif()
endif()
