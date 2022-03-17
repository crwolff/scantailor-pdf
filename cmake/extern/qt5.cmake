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
		
	else() # Qt5 has not been built yet. Configure for build.
		
		message(STATUS "Qt5 has not been fully built yet. "
							"After the first build without errors, just rerun the cmake configuration "
							"and generation steps and it should find Qt5 and build fine.")
		set(HAVE_DEPENDENCIES FALSE)
		
		ExternalProject_Add(
		qt5-base-extern
		PREFIX ${EXTERN}
		URL https://download.qt.io/official_releases/qt/5.15/5.15.2/submodules/qtbase-everywhere-src-5.15.2.tar.xz
		URL_HASH SHA256=909fad2591ee367993a75d7e2ea50ad4db332f05e1c38dd7a5a274e156a4e0f8
		# Qt < 6 with gcc 11 error: limits is not included by compiler by default any more.
		PATCH_COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN}/src/patches/qt5-base-extern/src/corelib/global/qfloat16.h <SOURCE_DIR>/src/corelib/global/qfloat16.h
		COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN}/src/patches/qt5-base-extern/src/corelib/global/qendian.h <SOURCE_DIR>/src/corelib/global/qendian.h
		COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN}/src/patches/qt5-base-extern/src/corelib/text/qbytearraymatcher.h <SOURCE_DIR>/src/corelib/text/qbytearraymatcher.h
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
			URL https://download.qt.io/official_releases/qt/5.15/5.15.2/submodules/qttools-everywhere-src-5.15.2.tar.xz
			URL_HASH SHA256=c189d0ce1ff7c739db9a3ace52ac3e24cb8fd6dbf234e49f075249b38f43c1cc
			CONFIGURE_COMMAND ${EXTERN}/src/qt5-base-extern-build/bin/qmake -makefile -after "CONFIG += release" <SOURCE_DIR>/${QT_TOOLS}
			# This uses multiple threads with [mingw32-]make if main build was started with -jN option
			BUILD_COMMAND ${CMAKE_MAKE_PROGRAM}
			# Install to Qt5 build dir so linguist is found by main project
			INSTALL_COMMAND ${CMAKE_MAKE_PROGRAM} install
			UPDATE_COMMAND ""   # Don't rebuild on main project recompilation
			DEPENDS qt5-base-extern
		)
		
		if(NOT BUILD_QT_TOOLS)
			# Build only linguist tool and its dependencies
			ExternalProject_Add_Step(
				qt-tools custom-patch
				DEPENDEES configure
				DEPENDERS build
				# Patch to build files to only build linguist tool and its dependencies
				COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN}/src/patches/qt-tools/src/src.pro ${EXTERN}/src/qt-tools/src/src.pro
				COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN}/src/patches/qt-tools/src/designer/src/src.pro ${EXTERN}/src/qt-tools/src/designer/src/src.pro
			)
		endif()
		
		# When using lhmouse's MinGW distribution, the threading lib cannot be statically linked. Copy it to bin dir.
		if(MINGW)
			find_file(mcf mcfgthread-12.dll HINTS ENV PATH)
			if(EXISTS ${mcf})
				file(COPY ${mcf} DESTINATION ${EXTERN}/bin)
			endif()
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
			"All dependencies have been built. "
			"Please re-run cmake."
		)
	endif()

endif()
