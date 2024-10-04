cmake_minimum_required(VERSION 3.21.0)

if(POLICY CMP0003)
	# Allow linking with full library path instead of -L/path -llibrary
	cmake_policy(SET CMP0003 NEW)
endif()

if(POLICY CMP0048)
	# When PROJECT() is missing the VERSION argument, set the corresponding
	# CMake variables to zero.
	cmake_policy(SET CMP0048 NEW)
endif()

if(POLICY CMP0135)
	# ExternalProject_Add() download timestamp handling changed in 3.24
	# https://cmake.org/cmake/help/latest/policy/CMP0135.html
	cmake_policy(SET CMP0135 NEW)
endif()


project("Scan Tailor PDF")


#============== Cmake files for custom functions ==================#

include(CheckIncludeFile)
include(CheckIncludeFileCXX)
include(TestCXXAcceptsFlag)
include(CMakeDependentOption)
include(FetchContent)
include(cmake/FindPthreads.cmake)
include(cmake/SetDefaultBuildType.cmake)
include(cmake/SetDefaultGccFlags.cmake)
include(cmake/ToNativePath.cmake)
include(cmake/UpdateTranslations.cmake)
include(cmake/CopyToBuildDir.cmake)
include(cmake/LibToDLL.cmake)

#===================== User cmake options =========================#

# Folder where the perl executable is located.
# Use this with -DST_PERL_PATH=[perlpath] if you get an error that Perl cannot be found.
set(ST_PERL_PATH "")

# This will always build the project supplied external dependencies, including QT.
# Most Find*.cmake modules only find dynamic libraries. So the maintenance effort
# is too big to find system static libraries across all supported platforms and
# compilers. Currently only works on WIN32.
option(BUILD_SHARED_LIBS "Build a shared version of Scan Tailor PDF." ON)

# We usually only build linguist and windeployqt because we need it for the translations.
# Turn this on, if you wish to build all qt tools (assistant, designer, etc.).
option(BUILD_QT_TOOLS "Build and install all QT tools, including assistant, designer, etc.)." OFF)

# Crash reporter, only Windows + MSVC supported for now.
# Must go before generating config.h, as ENABLE_CRASH_REPORTER
# goes in there.
if(MSVC)
	option(ENABLE_CRASH_REPORTER "Enable crash reporter (only for official builds)" OFF)
endif(MSVC)

# Currently broken…
#option(BUILD_CLI "Build the command line Scan Tailor PDF executable." OFF)


#================ Reflect above options in settings ===============#

## BUILD_SHARED_LIBS: static and shared builds
set(STATIC_BOOL OFF)
set(SHARED_BOOL ON)
set(LIB_TYPE SHARED)

# Settings for static build
if(NOT BUILD_SHARED_LIBS)
	set(STATIC_BOOL ON)
	set(SHARED_BOOL OFF)
	set(LIB_TYPE STATIC)
	if (MINGW)
		# Even link against static libgcc and libstdc++ on Windows since these are not available by default.
		set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static-libgcc -static-libstdc++ -static")
	# elseif(MSVC)
		# # Link against static C and C++ runtimes
		# add_compile_options(/MT)
	endif()
endif()

#======================= Compiler flags ===========================#

set(
	CMAKE_USER_MAKE_RULES_OVERRIDE
	"${CMAKE_SOURCE_DIR}/cmake/default_cflags.cmake"
)
set(
	CMAKE_USER_MAKE_RULES_OVERRIDE_CXX
	"${CMAKE_SOURCE_DIR}/cmake/default_cxxflags.cmake"
)

set(CMAKE_CXX_STANDARD 11)

ST_SET_DEFAULT_BUILD_TYPE(Release)
if(CMAKE_COMPILER_IS_GNUCC)
	ST_SET_DEFAULT_GCC_FLAGS()
endif(CMAKE_COMPILER_IS_GNUCC)

if(MSVC)
	# Disable checked iterators for extra performance.
	add_definitions(-D_SECURE_SCL=0)
endif()

if(DEBUG_CLI)
	add_definitions(-DDEBUG_CLI)
endif(DEBUG_CLI)

enable_testing()




# Keep the paths outside of the build directory in RPATH
# when installing. That's useful for building with say
# a custom build of Qt.
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# Scan Tailor needs to find its shared libraries.
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib/scantailor")

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/modules")



#====================== Configure version =========================#

# An undocumented side-effect of CONFIGURE_FILE() is that it makes
# the whole project depend on the file we are parsing / copying.
configure_file(
	"${PROJECT_SOURCE_DIR}/version.h"
	"${PROJECT_BINARY_DIR}/.version.h" COPYONLY
)

# Prevent this leftover from old builds to be used in favour
# of the one in ${PROJECT_SOURCE_DIR}
if(NOT "${PROJECT_BINARY_DIR}" STREQUAL "${PROJECT_SOURCE_DIR}")
	file(REMOVE "${PROJECT_BINARY_DIR}/version.h")
endif()

# Extract VERSION and VERSION_QUAD from version.h
file(READ "${PROJECT_SOURCE_DIR}/version.h" version_h_contents)
string(
	REGEX REPLACE
	".*#define[ \\t]+VERSION[ \\t]+\"([^\"]*)\".*"
	"\\1" VERSION "${version_h_contents}"
)
if("${VERSION}" STREQUAL "${version_h_contents}")
	message(FATAL_ERROR "Failed to extract VERSION from version.h")
endif()

# VERSION_QUAD must be either empty or be in the form of X.Y.Z.Y
string(
	REGEX REPLACE
	".*#define[ \\t]+VERSION_QUAD[ \\t]+\"(([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)?)\".*"
	"\\1" VERSION_QUAD "${version_h_contents}"
)
if("${VERSION_QUAD}" STREQUAL "${version_h_contents}")
	message(FATAL_ERROR "Failed to extract VERSION_QUAD from version.h")
endif()


# For config.h
include_directories("${CMAKE_CURRENT_BINARY_DIR}")




#==================================================================#
#====================== Dependency search =========================#
#==================================================================#

set(EXTERN ${CMAKE_CURRENT_BINARY_DIR}/extern)
if(NOT BUILD_SHARED_LIBS AND NOT HAVE_DEPENDENCIES)
	message(STATUS "External dependencies will be stored in ${EXTERN}")
endif()

# https://cmake.org/cmake/help/latest/module/ExternalProject.html
include(ExternalProject)

# This dir structure follows the GNU installation structure
# It uses the default ExternalProject_add() dir structure.
set(EXTERN_INC_DIR ${EXTERN}/include)
set(EXTERN_LIB_DIR ${EXTERN}/lib)
set(EXTERN_BIN_DIR ${EXTERN}/bin)

# Make sure, find_*() functions can find external dependencies
set(CMAKE_PREFIX_PATH ${EXTERN})

# Location of patches for building external libraries
set(EXTERN_PATCH_DIR ${CMAKE_SOURCE_DIR}/extern-patches)

# List of include directories for all external libraries
list(APPEND ALL_EXTERN_INC_DIRS ${EXTERN_INC_DIR})

# ExternalProjects with a build command need to append the .vcxproj to the target
# so they can be build with msbuild. Define it here and use in the extern cmake files.
# The variable is empty for non MSVC builds.
set(vcxproj "")
if(MSVC)
	set(vcxproj ".vcxproj")
endif()

# Assume we have all dependencies. If a dependency is not found below,
# this variable is set to false and cmake won't configure the actual
# Scan Tailor build.
set(HAVE_DEPENDENCIES TRUE)

# External library targets
# The following cmake files will search for and/or download and build
# all external dependencies. They set all LIB_* variables and add all
# needed include directories to the ALL_EXTERN_INC_DIRS variable.

# All downloaded external dependencies are stored in ./extern-src
set(DOWNLOAD_DIR "${CMAKE_SOURCE_DIR}/extern-pkg")


set(LIB_SSL "")
set(LIB_CRYP "")
include(cmake/extern/openssl.cmake)

set(LIB_ZLIB "")
include(cmake/extern/zlib.cmake)

set(LIB_JPEG "")
include(cmake/extern/jpeg.cmake)

set(LIB_PNG "")
include(cmake/extern/png.cmake)

set(LIB_LZMA "")
include(cmake/extern/lzma.cmake)

set(LIB_ZSTD "")
include(cmake/extern/zstd.cmake)

set(LIB_TIFF "")
include(cmake/extern/tiff.cmake)

set(LIB_OPENJP "")
include(cmake/extern/openjp.cmake)

set(LIB_FREETYPE "")
include(cmake/extern/freetype.cmake)

set(LIB_XML2 "")
include(cmake/extern/xml2.cmake)

set(LIB_PODOFO "")
include(cmake/extern/podofo.cmake)

# OpenCL is currently only supported on Windows with MSVC or MinGW
# For MSVC, you need to have an opencl SDK installed.
if(MSVC OR MINGW)
	set(LIB_OPENCL "")
	include(cmake/extern/opencl.cmake)
	cmake_dependent_option(
		ENABLE_OPENCL "OpenCL may be used for acceleration of image processing" ON
		"OpenCL_FOUND" OFF
	)
endif()

set(EIGEN3_INCLUDE_DIR "")
include(cmake/extern/eigen3.cmake)

include(FindOpenGL)
cmake_dependent_option(
	ENABLE_OPENGL "OpenGL may be used for UI acceleration" ON
	"OPENGL_FOUND" OFF
)

set(LIB_BOOST "")
include(cmake/extern/boost.cmake)

set(CMAKE_AUTOMOC ON)
set(qt_min_version 5.3)
include(cmake/extern/qt5.cmake)


#============================ Threads ===============================#

if(UNIX)
	FindPthreads()
	if(PTHREADS_FOUND)
		add_definitions(${PTHREADS_CFLAGS})
		link_libraries(${PTHREADS_LIBS})
	else(PTHREADS_FOUND)
		message(
			FATAL_ERROR
			"Could not detect threading flags.\n"
			"Try specifying them manually in PTHREADS_CFLAGS and PTHREADS_LIBS."
		)
	endif(PTHREADS_FOUND)
elseif(WIN32 AND MSVC)
	add_definitions(-DNOMINMAX)
endif(UNIX)


# Other includes and options
set(EXTRA_LIBS "")

if(MINGW AND NOT BUILD_SHARED_LIBS)
	list(APPEND EXTRA_LIBS winmm imm32 ws2_32 ole32 oleaut32 uuid gdi32 comdlg32 winspool)
endif()

list(APPEND EXTRA_LIBS ${LIB_ZLIB} ${LIB_JPEG} ${LIB_PNG} ${LIB_TIFF}
	${LIB_ZSTD} ${LIB_LZMA} ${LIB_OPENJP} ${LIB_XML2} ${LIB_SSL} ${LIB_CRYP} ${LIB_PODOFO}
)

set(MAYBE_QT_OPENGL_MODULE "")
if(ENABLE_OPENGL)
	list(APPEND EXTRA_LIBS ${OPENGL_LIBRARIES})
	set(MAYBE_QT_OPENGL_MODULE Qt5::OpenGL)
endif()


#==================================================================#
#========================== Scantailor ============================#
#==================================================================#

if(HAVE_DEPENDENCIES) # Check that we have found/built Qt5
# We have to do this because we might have to build Qt5 on first cmake run.

# Prepare config.h
if(WIN32)
	set(TRANSLATION_DIRS ".:translations")
	set(PLUGIN_DIRS ".")
else()
	set(TRANSLATION_DIRS ".:${CMAKE_INSTALL_PREFIX}/share/scantailor/translations")
	set(PLUGIN_DIRS ".:${CMAKE_INSTALL_PREFIX}/lib/scantailor")
endif()

configure_file(config.h.in ${CMAKE_BINARY_DIR}/config.h @ONLY)

# Scan Tailor PDF sources and targets
add_subdirectory(src)



#================== Packaging ===================#

# Source code packaging
set(CPACK_CMAKE_GENERATOR "")
set(CPACK_SOURCE_GENERATOR "TGZ")
set(CPACK_SOURCE_PACKAGE_FILE_NAME "scantailor-${VERSION}")
set(
	CPACK_SOURCE_IGNORE_FILES
	"/\\\\.svn/"
	"/\\\\.git/"
	"~$"
	"\\\\.pcs$"
	"TODO.txt"
	"CMakeLists.txt.user"
	"/doxygen/"
	"${CMAKE_BINARY_DIR}"
	"${EXTERN}"
)
include(CPack)


if(WIN32 AND BUILD_SHARED_LIBS)
	
	## Copy all needed DLLs to the staging dir.
	# Our external libraries
	# add_custom_command(TARGET scantailor POST_BUILD
	  # COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_RUNTIME_DLLS:scantailor> $<TARGET_FILE_DIR:scantailor>
	  # COMMAND_EXPAND_LISTS
	# )

	# # QT5 stuff; this also copies needed system runtime files
	# add_custom_command(TARGET scantailor POST_BUILD
	  # COMMAND ${EXTERN_BIN_DIR}/windeployqt --dir $<TARGET_FILE_DIR:scantailor> $<TARGET_FILE:scantailor>
	# )
	
	# if(ENABLE_OPENGL)
	# list(APPEND qt5_libs ${Qt5OpenGL_LIBRARIES})
	# endif()
	# foreach(target ${qt5_libs})
		# get_target_property(debug_loc "${target}" LOCATION_DEBUG)
		# get_target_property(release_loc "${target}" LOCATION_RELEASE)
		# COPY_TO_BUILD_DIR("${debug_loc}" CONFIGURATIONS Debug)
		# COPY_TO_BUILD_DIR("${release_loc}" CONFIGURATIONS Release MinSizeRel RelWithDebInfo)
	# endforeach()
	
	# Not needed any more. This is done by the dependency itself
	# Libs
	# COPY_TO_BUILD_DIR(
		# "${JPEG_DLL}" "${PNG_DLL}" "${ZLIB_DLL}" "${TIFF_DLL}" "${OPENJPEG_DLL}"
		# "${PODOFO_DLL}" "${FREETYPE_DLL}" 
	# )
	
	# Generate the target that will actually do the copying.
	#GENERATE_COPY_TO_BUILD_DIR_TARGET(copy_to_build_dir)
	
	# Installer for Windows.  Must go last.
	add_subdirectory(src/packaging/windows)
endif(WIN32 AND BUILD_SHARED_LIBS)

endif(HAVE_DEPENDENCIES)
