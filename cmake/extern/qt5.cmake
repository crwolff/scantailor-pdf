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
			set(QT5_STATIC_OPTIONS "-static -static-runtime")
		endif()
		
		ExternalProject_Add(
			qt5-base-extern
			PREFIX ${EXTERN}
			URL https://download.qt.io/official_releases/qt/5.15/5.15.2/submodules/qtbase-everywhere-src-5.15.2.tar.xz
			URL_HASH SHA256=909fad2591ee367993a75d7e2ea50ad4db332f05e1c38dd7a5a274e156a4e0f8
			# Qt < 6 with gcc 11 error: limits is not included by compiler by default any more.
			PATCH_COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN_PATCH_DIR}/qt5-base-extern/src/corelib/global/qfloat16.h <SOURCE_DIR>/src/corelib/global/qfloat16.h
			COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN_PATCH_DIR}/qt5-base-extern/src/corelib/global/qendian.h <SOURCE_DIR>/src/corelib/global/qendian.h
			COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN_PATCH_DIR}/qt5-base-extern/src/corelib/text/qbytearraymatcher.h <SOURCE_DIR>/src/corelib/text/qbytearraymatcher.h
			CONFIGURE_COMMAND ${EXTERN}/src/qt5-base-extern/configure -platform win32-g++ -debug-and-release ${QT5_STATIC_OPTIONS} -force-debug-info -no-ltcg -prefix ${EXTERN} -no-gif -no-dbus -system-zlib -system-libpng -system-libjpeg -qt-pcre -no-openssl -opengl desktop -nomake examples -nomake tests -silent -opensource -confirm-license ${MP} -L ${EXTERN_LIB_DIR} -I ${EXTERN_INC_DIR}
			UPDATE_COMMAND ""   # Don't rebuild on main project recompilation
			DEPENDS ${LIB_ZLIB} ${LIB_JPEG} ${LIB_PNG} ${LIB_FREETYPE}
		)
					
		ExternalProject_Add(
			qt-tools
			PREFIX ${EXTERN}
			URL https://download.qt.io/official_releases/qt/5.15/5.15.2/submodules/qttools-everywhere-src-5.15.2.tar.xz
			URL_HASH SHA256=c189d0ce1ff7c739db9a3ace52ac3e24cb8fd6dbf234e49f075249b38f43c1cc
			CONFIGURE_COMMAND ${EXTERN}/src/qt5-base-extern-build/bin/qmake -makefile -after "CONFIG += release" <SOURCE_DIR>/${QT_TOOLS}
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
