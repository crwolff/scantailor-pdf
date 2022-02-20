# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(USE_SYSTEM_LIBS AND NOT STATIC_BUILD)

	find_package(Qt5 COMPONENTS Core Gui Widgets Xml Network LinguistTools REQUIRED)
	if(ENABLE_OPENGL)
		find_package(Qt5 COMPONENTS OpenGL REQUIRED)
	endif()
	# Use the QT5::* targets now
	
else() # Local static build
			
	ExternalProject_Add(
		qt5-base-extern
		PREFIX ${EXTERN}
		URL https://download.qt.io/archive/qt/5.12/5.12.12/submodules/qtbase-everywhere-src-5.12.12.zip
		URL_HASH SHA256=9552dd8ce926871004e1051b81a39e6161fb330e759d5e0a72e29abc97ffa293
		# Qt 5.12 with gcc 11 error: limits is not included by default any more
		PATCH_COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN}/src/patches/qt5-base-extern/src/corelib/global/qendian.h <SOURCE_DIR>/src/corelib/global/qendian.h
		COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN}/src/patches/qt5-base-extern/src/corelib/tools/qbytearraymatcher.h <SOURCE_DIR>/src/corelib/tools/qbytearraymatcher.h
		CONFIGURE_COMMAND ${EXTERN}/src/qt5-base-extern/configure -platform win32-g++ -debug-and-release -static -static-runtime -force-debug-info -no-ltcg -prefix ${EXTERN} -no-gif -no-dbus -system-zlib -system-libpng -system-libjpeg -qt-pcre -no-openssl -opengl desktop -nomake examples -nomake tests -silent -opensource -confirm-license ${MP} -L ${EXTERN_LIB_DIR} -I ${EXTERN_INC_DIR}
		BUILD_COMMAND ${CMAKE_MAKE_PROGRAM} ${JX}  # JX is only set when using [mingw32-]make
		# INSTALL_COMMAND ${CMAKE_MAKE_PROGRAM} install
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		DEPENDS ${LIB_ZLIB} ${LIB_JPEG} ${LIB_PNG} ${LIB_FREETYPE}
	)
	
	ExternalProject_Add(
		qt-tools
		PREFIX ${EXTERN}
		BINARY_DIR ${EXTERN}/src/qt5-base-extern-build
		URL https://download.qt.io/archive/qt/5.12/5.12.12/submodules/qttools-everywhere-src-5.12.12.zip
		URL_HASH SHA256=62559f75ff0a62bff95dbd6c44baf8aa7f3a1d8c8112ed74c6a0d7a6310db167
		CONFIGURE_COMMAND ${EXTERN}/src/qt5-base-extern-build/bin/qmake -makefile -after "CONFIG += release" ${EXTERN}/src/qt-tools/qttools.pro
		BUILD_COMMAND ${CMAKE_MAKE_PROGRAM} ${JX} # JX is only set when using [mingw32-]make
		# INSTALL_COMMAND ${CMAKE_MAKE_PROGRAM} install
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		DEPENDS qt5-base-extern
	)
	
	# This does not work on first build because find_package needs libs to already be built. We need to somehow stop and say a message after qt-tools to run cmake and build again.
	
	if(EXISTS ${EXTERN}/src/qt5-base-extern-build/lib/cmake/Qt5LinguistTools)
		# Tell find_package() where to find Qt5
		set(Qt5_DIR "${EXTERN}/src/qt5-base-extern-build/lib/cmake/Qt5")
		find_package(Qt5 COMPONENTS Core Gui Widgets Xml Network LinguistTools REQUIRED)
		if(ENABLE_OPENGL)
			find_package(Qt5 COMPONENTS OpenGL REQUIRED)
		endif()
		set(HAVE_QT5 TRUE)
	else() # Haven't built Qt5 yet
		message(STATUS "Qt5 has not been fully built yet and the build will fail the first time. This is normal. After the build, just rerun the cmake configuration and generation steps and it should find Qt5 and build fine.")
	endif()

endif()
