# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(USE_SYSTEM_LIBS AND NOT STATIC_BUILD)

	find_package(Qt5 COMPONENTS Core Gui Widgets Xml Network LinguistTools REQUIRED)
	if(ENABLE_OPENGL)
		find_package(Qt5 COMPONENTS OpenGL REQUIRED)
	endif()
	# Now, use the QT5::* targets.
	
else() # Local static build
			
	if(EXISTS ${EXTERN}/lib/cmake/Qt5LinguistTools)
		# Tell find_package() where to find Qt5
		set(Qt5_DIR "${EXTERN}") #/src/qt5-base-extern-build/lib/cmake/Qt5")
		find_package(Qt5 COMPONENTS Core Gui Widgets Xml Network LinguistTools REQUIRED)
		if(ENABLE_OPENGL)
			find_package(Qt5 COMPONENTS OpenGL REQUIRED)
		endif()
		# For a static build, we have to add more dependencies manually
		target_link_libraries(Qt5::Gui INTERFACE ${LIB_PNG} "${EXTERN}/lib/libqtharfbuzz.a")
		target_link_libraries(Qt5::Core INTERFACE "${EXTERN}/lib/libqtpcre2.a")
		# Now, use the QT5::* targets.
		set(HAVE_QT5 TRUE)
		
	else() # Qt5 has not been built yet. Configure for build.
		
		message(STATUS "Qt5 has not been fully built yet. "
							"After the first build without errors, just rerun the cmake configuration "
							"and generation steps and it should find Qt5 and build fine.")
							
		ExternalProject_Add(
		qt5-base-extern
		PREFIX ${EXTERN}
		URL https://download.qt.io/archive/qt/5.12/5.12.12/submodules/qtbase-everywhere-src-5.12.12.zip
		URL_HASH SHA256=9552dd8ce926871004e1051b81a39e6161fb330e759d5e0a72e29abc97ffa293
		# Qt 5.12 with gcc 11 error: limits is not included by compiler by default any more
		PATCH_COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN}/src/patches/qt5-base-extern/src/corelib/global/qendian.h <SOURCE_DIR>/src/corelib/global/qendian.h
		COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN}/src/patches/qt5-base-extern/src/corelib/tools/qbytearraymatcher.h <SOURCE_DIR>/src/corelib/tools/qbytearraymatcher.h
		# Two patches from https://github.com/msys2/MINGW-packages/commit/796a15ede3e71a56282c5553b87ca0fbe8fcba64
		# for static build with MinGW.
		COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN}/src/patches/qt5-base-extern/src/corelib/Qt5CoreConfigExtras.cmake.in <SOURCE_DIR>/src/corelib/Qt5CoreConfigExtras.cmake.in
		COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN}/src/patches/qt5-base-extern/mkspecs/features/data/cmake/Qt5BasicConfig.cmake.in <SOURCE_DIR>/mkspecs/features/data/cmake/Qt5BasicConfig.cmake.in
		# This patch is for static build from https://codereview.qt-project.org/c/qt/qtbase/+/286837/3/mkspecs/features/create_cmake.prf#215
		COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN}/src/patches/qt5-base-extern/mkspecs/features/create_cmake.prf
		<SOURCE_DIR>/mkspecs/features/create_cmake.prf
		CONFIGURE_COMMAND ${EXTERN}/src/qt5-base-extern/configure -platform win32-g++ -debug-and-release -static -static-runtime -force-debug-info -no-ltcg -prefix ${EXTERN} -no-gif -no-dbus -system-zlib -system-libpng -system-libjpeg -qt-pcre -no-openssl -opengl desktop -nomake examples -nomake tests -silent -opensource -confirm-license ${MP} -L ${EXTERN_LIB_DIR} -I ${EXTERN_INC_DIR}
		# This uses multiple threads with [mingw32-]make if main build was started with -jN option
		BUILD_COMMAND ${CMAKE_MAKE_PROGRAM}
		INSTALL_COMMAND ${CMAKE_MAKE_PROGRAM} install
		UPDATE_COMMAND ""   # Don't rebuild on main project recompilation
		DEPENDS ${LIB_ZLIB} ${LIB_JPEG} ${LIB_PNG} ${LIB_FREETYPE}
		)
		
		ExternalProject_Add(
			qt-tools
			PREFIX ${EXTERN}
			URL https://download.qt.io/archive/qt/5.12/5.12.12/submodules/qttools-everywhere-src-5.12.12.zip
			URL_HASH SHA256=62559f75ff0a62bff95dbd6c44baf8aa7f3a1d8c8112ed74c6a0d7a6310db167
			CONFIGURE_COMMAND ${EXTERN}/src/qt5-base-extern-build/bin/qmake -makefile -after "CONFIG += release" ${EXTERN}/src/qt-tools/qttools.pro
			# This uses multiple threads with [mingw32-]make if main build was started with -jN option
			BUILD_COMMAND ${CMAKE_MAKE_PROGRAM}
			# Install to Qt5 build dir so linguist is found by main project
			INSTALL_COMMAND ${CMAKE_MAKE_PROGRAM} install
			# INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory <BINARY_DIR>/bin ${EXTERN}/src/qt5-base-extern-build/bin
			# COMMAND ${CMAKE_COMMAND} -E copy_directory <BINARY_DIR>/lib/cmake ${EXTERN}/src/qt5-base-extern-build/lib/cmake
			UPDATE_COMMAND ""   # Don't rebuild on main project recompilation
			DEPENDS qt5-base-extern
		)
		
		# This does not work on first build because find_package needs libs to already be built. We need to stop and say a message after qt-tools to run cmake and build again.
		
		# When using ucrt MinGW distribution, the threading lib cannot be statically linked. Copy it to bin dir.
		if(MINGW)
			find_file(mcf mcfgthread-12.dll HINTS ENV PATH)
			if(EXISTS ${mcf})
				file(COPY ${mcf} DESTINATION ${EXTERN}/bin)
			endif()
		endif()
		
		# Strip utility programs of Qt5 and some static libraries to reduce the huge size.
		# We don't need debug symbols in them.
		if(MINGW OR GNU)
			# Adding ExternalProject_Add_Step() does not work as some files are stripped before linking.
			# This is probably due to parallel compilation of make
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
			"All dependencies have been built. "
			"Please re-run cmake."
		)
	endif()

endif()
