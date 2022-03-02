cmake_minimum_required(VERSION 3.15.0)

if(POLICY CMP0003)
	# Allow linking with full library path instead of -L/path -llibrary
	cmake_policy(SET CMP0003 NEW)
endif()

if(POLICY CMP0048)
	# When PROJECT() is missing the VERSION argument, set the corresponding
	# CMake variables to zero.
	cmake_policy(SET CMP0048 NEW)
endif()


project("Scan Tailor PDF")


##---------- User cmake options ----------##

# When using this option, all dependencies need to be installed and be locatable
# by find_package(), find_library(), and find_file(). You may set
# CMAKE_PREFIX_PATH accordingly.
option(USE_SYSTEM_LIBS "Use installed libraries instead of the project supplied ones. Halts and gives an error if a dependency is not found using find_package()." OFF)

# This will always build the project supplied external dependencies, including QT.
# Most Find….cmake modules only find dynamic libraries. So the maintenance effort
# is too big, to find system static libraries across all supported platforms and
# compilers.
option(STATIC_BUILD "Statically link all libraries." OFF)
if(STATIC_BUILD)
	set(MAYBE_STATIC "STATIC")
endif()

# Crash reporter, only Windows + MSVC supported for now.
# Must go before generating config.h, as ENABLE_CRASH_REPORTER
# goes in there.
IF(MSVC)
	OPTION(ENABLE_CRASH_REPORTER "Enable crash reporter (only for official builds)" OFF)
ENDIF(MSVC)

option(BUILD_CLI "Build the command line Scan Tailor executable." OFF)





SET(
	CMAKE_USER_MAKE_RULES_OVERRIDE
	"${CMAKE_SOURCE_DIR}/cmake/default_cflags.cmake"
)
SET(
	CMAKE_USER_MAKE_RULES_OVERRIDE_CXX
	"${CMAKE_SOURCE_DIR}/cmake/default_cxxflags.cmake"
)

SET(CMAKE_CXX_STANDARD 11)

# Keep the paths outside of the build directory in RPATH
# when installing. That's useful for building with say
# a custom build of Qt.
SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# Scan Tailor needs to find its shared libraries.
SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib/scantailor")

SET(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/modules")

IF(MSVC)
	# Disable checked iterators for extra performance.
	ADD_DEFINITIONS(-D_SECURE_SCL=0)
ENDIF()

IF(DEBUG_CLI)
	ADD_DEFINITIONS(-DDEBUG_CLI)
ENDIF(DEBUG_CLI)

ENABLE_TESTING()

# An undocumented side-effect of CONFIGURE_FILE() is that it makes
# the whole project depend on the file we are parsing / copying.
CONFIGURE_FILE(
	"${PROJECT_SOURCE_DIR}/version.h"
	"${PROJECT_BINARY_DIR}/.version.h" COPYONLY
)

# Prevent this leftover from old builds to be used in favour
# of the one in ${PROJECT_SOURCE_DIR}
IF(NOT "${PROJECT_BINARY_DIR}" STREQUAL "${PROJECT_SOURCE_DIR}")
	FILE(REMOVE "${PROJECT_BINARY_DIR}/version.h")
ENDIF()

# Extract VERSION and VERSION_QUAD from version.h
FILE(READ "${PROJECT_SOURCE_DIR}/version.h" version_h_contents)
STRING(
	REGEX REPLACE
	".*#define[ \\t]+VERSION[ \\t]+\"([^\"]*)\".*"
	"\\1" VERSION "${version_h_contents}"
)
IF("${VERSION}" STREQUAL "${version_h_contents}")
	MESSAGE(FATAL_ERROR "Failed to extract VERSION from version.h")
ENDIF()

# VERSION_QUAD must be either empty or be in the form of X.Y.Z.Y
STRING(
	REGEX REPLACE
	".*#define[ \\t]+VERSION_QUAD[ \\t]+\"(([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)?)\".*"
	"\\1" VERSION_QUAD "${version_h_contents}"
)
IF("${VERSION_QUAD}" STREQUAL "${version_h_contents}")
	MESSAGE(FATAL_ERROR "Failed to extract VERSION_QUAD from version.h")
ENDIF()

# This has to go quite early on, as otherwise we risk picking
# up an identically named header from a system include path.
INCLUDE_DIRECTORIES(. foundation math interaction zones)

# For config.h
INCLUDE_DIRECTORIES("${CMAKE_CURRENT_BINARY_DIR}")

INCLUDE(CheckIncludeFile)
INCLUDE(CheckIncludeFileCXX)
INCLUDE(TestCXXAcceptsFlag)
INCLUDE(CMakeDependentOption)
INCLUDE(cmake/FindPthreads.cmake)
INCLUDE(cmake/SetDefaultBuildType.cmake)
INCLUDE(cmake/SetDefaultGccFlags.cmake)
INCLUDE(cmake/ToNativePath.cmake)
INCLUDE(cmake/UpdateTranslations.cmake)
INCLUDE(cmake/CopyToBuildDir.cmake)
INCLUDE(cmake/LibToDLL.cmake)

ST_SET_DEFAULT_BUILD_TYPE(Release)
IF(CMAKE_COMPILER_IS_GNUCC)
	ST_SET_DEFAULT_GCC_FLAGS()
ENDIF(CMAKE_COMPILER_IS_GNUCC)

#GET_FILENAME_COMPONENT(source_outer_dir "${PROJECT_SOURCE_DIR}/.." ABSOLUTE)
#GET_FILENAME_COMPONENT(build_outer_dir "${PROJECT_BINARY_DIR}/.." ABSOLUTE)


#==================================================================#
#====================== Dependency search =========================#
#==================================================================#

set(EXTERN ${PROJECT_SOURCE_DIR}/extern)
message(STATUS "External dependencies will be stored in ${EXTERN}")

if(STATIC_BUILD)
	# https://cmake.org/cmake/help/latest/module/ExternalProject.html
	include(ExternalProject)

	# This dir structure follows the GNU installation structure
	set(EXTERN_INC_DIR ${EXTERN}/include)
	set(EXTERN_LIB_DIR ${EXTERN}/lib)
	set(EXTERN_BIN_DIR ${EXTERN}/bin)

	# Make sure, find_*() functions can find external dependencies
	set(CMAKE_PREFIX_PATH ${EXTERN})

	# Multiprocessor options for quicker compilation of various libraries
	set(MP "")	# Configure QT5 to use multiple processors when using nmake
	set(JX "")	# Make [mingw32-]make use multiple processors for QT5 build
	if(${CMAKE_GENERATOR} STREQUAL "NMake Makefiles")
		set(MP "-mp")	# Appended to the QT5 configure step
	elseif(
		${CMAKE_GENERATOR} STREQUAL "MinGW Makefiles" OR
		${CMAKE_GENERATOR} STREQUAL "Unix Makefiles" OR
		${CMAKE_GENERATOR} STREQUAL "MSYS Makefiles"
		)
			include(ProcessorCount)
			ProcessorCount(N)
			math(EXPR THREADS "${N} - 1")
			if(NOT N EQUAL 0)
				set(JX "-j${THREADS}")
			endif()
	elseif(${CMAKE_GENERATOR} STREQUAL "Ninja")
		if(POLICY CMP0048)
			# Prevent Warnings about byproducts and phony targets for Ninja generator
			cmake_policy(SET CMP0058 OLD)
		endif()
	endif()
endif()

# List of include directories for all external libraries
list(APPEND ALL_EXTERN_INC_DIRS ${EXTERN_INC_DIR})


# External library targets
# The following cmake files will search for and/or download and build
# all external dependencies. They set all LIB_* variables and add all
# needed include directories to the ALL_EXTERN_INC_DIRS variable. 
set(LIB_ZLIB "")
include(cmake/extern/zlib.cmake)

set(LIB_JPEG "")
include(cmake/extern/jpeg.cmake)

set(LIB_PNG "")
include(cmake/extern/png.cmake)

set(LIB_TIFF "")
include(cmake/extern/tiff.cmake)

set(LIB_OPENJP "")
include(cmake/extern/openjp.cmake)

set(LIB_FREETYPE "")
include(cmake/extern/freetype.cmake)

set(LIB_PODOFO "")
include(cmake/extern/podofo.cmake)

# OpenCL is currently only supported on Windows with MSVC
if(MSVC)
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


# SET(STAGING_LIBS_DIR "")
# SET(DEPS_BUILD_DIR "")
# SET(DLLS "")

# IF(WIN32)
	# FIND_PATH(
		# DEPS_BUILD_DIR export-vars.cmake
		# HINTS "${build_outer_dir}/scantailor-deps-build"
		# DOC "Build directory for Scan Tailor dependencies."
	# )
	# IF(NOT DEPS_BUILD_DIR)
		# MESSAGE(
			# "The build directory for Scan Tailor dependencies could not be found. "
			# "If all external libraries are installed, they should be found and used. "
			# "But if you build them locally, you can specify it manually with the "
			# "DEPS_BUILD_DIR variable. Make sure you build the dependencies first!"
		# )
	# ELSE()
		# SET(STAGING_LIBS_DIR "${DEPS_BUILD_DIR}/staging/libs")
		# LIST(PREPEND CMAKE_PREFIX_PATH "${DEPS_BUILD_DIR}/staging")
		# INCLUDE("${DEPS_BUILD_DIR}/export-vars.cmake")
	# ENDIF()
# ENDIF()

#=========================== OpenGL ===============================#

# INCLUDE(FindOpenGL)
# CMAKE_DEPENDENT_OPTION(
	# ENABLE_OPENGL "OpenGL may be used for UI acceleration" ON
	# "OPENGL_FOUND" OFF
# )

#=========================== OpenCL ===============================#

# IF(MSVC)
	# INCLUDE(FindOpenCL)
	# IF(NOT OpenCL_FOUND)
	  # FIND_LIBRARY(
		 # OpenCL_LIBRARY NAMES opencl libopencl
		 # PATHS "${build_outer_dir}/opencl"
		 # DOC "Local OpenCL library path"
	  # )

	  # FIND_PATH(
		 # OpenCL_INCLUDE_DIR NAMES opencl.h cl.h cl.hpp
		 # PATHS "${build_outer_dir}/opencl/cl"
		 # DOC "Local OpenCL include path"
	  # )

	  # IF(OpenCL_LIBRARY AND OpenCL_INCLUDE_DIR)
	  # SET(OpenCL_FOUND ON)
	  # INCLUDE_DIRECTORIES("${OpenCL_INCLUDE_DIR}")
	  # ENDIF()
	# ENDIF()
# ENDIF(MSVC)
# CMAKE_DEPENDENT_OPTION(
	# ENABLE_OPENCL "OpenCL may be used for acceleration of image processing" ON
	# "OpenCL_FOUND" OFF
# )


#============================= Eigen ===============================#

# Try to find local eigen folders
# IF(WIN32 AND DEPS_BUILD_DIR)
	# FILE(GLOB eigen_dirs1 "${build_outer_dir}/eigen-*")
	# FILE(GLOB eigen_dirs2 "${source_outer_dir}/eigen-*")
	
	# FIND_PATH(
		# EIGEN3_INCLUDE_DIR NAMES signature_of_eigen3_matrix_library
		# PATHS ${eigen_dirs1} ${eigen_dirs2}
		# DOC "Path to Eigen include directory (containing \"Eigen\" subdirectory)"
	# )
# ENDIF()

# FIND_PACKAGE(Eigen3)

# IF(NOT EIGEN3_FOUND)	
	# MESSAGE(FATAL_ERROR
		# "Could not find Eigen (version 3) headers.\n"
		# "You may need to install Eigen3 or set EIGEN3_INCLUDE_DIR manually."
	# )
# ENDIF()
# INCLUDE_DIRECTORIES(${EIGEN3_INCLUDE_DIR})

# Once Eigen starts using C++11 alignas() feature, this can be removed.
#ADD_DEFINITIONS(-DEIGEN_DONT_ALIGN_STATICALLY)


#============================== Qt ================================#

# IF(WIN32 AND DEPS_BUILD_DIR)
	# SET(Qt5Core_DIR "${QT_BUILD_DIR}/lib/cmake/Qt5Core")
	# SET(Qt5Gui_DIR "${QT_BUILD_DIR}/lib/cmake/Qt5Gui")
	# SET(Qt5Widgets_DIR "${QT_BUILD_DIR}/lib/cmake/Qt5Widgets")
	# SET(Qt5Xml_DIR "${QT_BUILD_DIR}/lib/cmake/Qt5Xml")
	# SET(Qt5Network_DIR "${QT_BUILD_DIR}/lib/cmake/Qt5Network")
	# SET(Qt5OpenGL_DIR "${QT_BUILD_DIR}/lib/cmake/Qt5OpenGL")
	# IF(QT_PREBUILT_DIR)
		# SET(Qt5LinguistTools_DIR "${QT_PREBUILT_DIR}/lib/cmake/Qt5LinguistTools")
	# ELSE()
	  # # This has changed from qtbase to qttools probably in Qt version 5.9.
		# # Might also be required above.
		# SET(Qt5LinguistTools_DIR "${QT_BUILD_DIR}/lib/cmake/Qt5LinguistTools")
	# ENDIF()
# ENDIF()



# SET(CMAKE_AUTOMOC ON)
# SET(qt_min_version 5.3)
# FIND_PACKAGE(Qt5Core ${qt_min_version} REQUIRED)
# FIND_PACKAGE(Qt5Gui ${qt_min_version} REQUIRED)
# FIND_PACKAGE(Qt5Widgets ${qt_min_version} REQUIRED)
# FIND_PACKAGE(Qt5Xml ${qt_min_version} REQUIRED)
# FIND_PACKAGE(Qt5Network ${qt_min_version} REQUIRED)
# FIND_PACKAGE(Qt5LinguistTools ${qt_min_version} REQUIRED)
# IF(ENABLE_OPENGL)
	# FIND_PACKAGE(Qt5OpenGL ${qt_min_version} REQUIRED)
# ENDIF()



#============================ JPEG ===============================#

# FIND_PACKAGE(JPEG)

# IF(NOT JPEG-FOUND)
	


# ENDIF()

# FIND_PATH(
	# JPEG_INCLUDE_DIR jpeglib.h
	# PATHS /usr/local/include /usr/include
	# HINTS ${JPEG_DIR} # JPEG_DIR may come from export-vars.cmake
	# DOC "Path to libjpeg headers."
# )
# IF(NOT JPEG_INCLUDE_DIR)
	# MESSAGE(
		# FATAL_ERROR
		# "Could not find jpeg headers.\n"
		# "You may need to install a package named libjpeg62-dev or similarly."
	# )
# ENDIF()

# INCLUDE_DIRECTORIES("${JPEG_INCLUDE_DIR}")

# FIND_LIBRARY(
	# JPEG_LIBRARY NAMES jpeg libjpeg
	# PATHS /usr/local/lib /usr/lib
	# HINTS ${STAGING_LIBS_DIR}
	# DOC "Path to jpeg library."
# )
# IF(NOT JPEG_LIBRARY)
	# MESSAGE(
		# FATAL_ERROR
		# "Could not find jpeg library.\n"
		# "You may need to install a package named libjpeg62-dev or similarly."
	# )
# ENDIF()

# # Find dll
# IF(WIN32)
	# FILE(GLOB JPEG_DLL 
		# LIST_DIRECTORIES false
		# "${QT_BUILD_DIR}/bin/*jpeg*.dll")
	# IF(NOT JPEG_DLL)
		# MESSAGE(
			# FATAL_ERROR
			# "Could not find jpeg dll in dependency qt-build\\bin folder."
		# )
	# ENDIF()
# ENDIF()


# #============================ ZLIB ===============================#

# include(ExternalProject)

# set(DEP_INSTALL_DIR ${PROJECT_BINARY_DIR}/build/external)

# FIND_PACKAGE(ZLIB)
# IF(ZLIB-NOTFOUND)
	# set(ZLIB zlib)

	# ExternalProject_Add(
		 # zlib
		 # URL https://zlib.net/zlib1211.zip
		 # EP_BASE  ${PROJECT_SOURCE_DIR}/external
		 # #CONFIGURE_COMMAND ${CMAKE_COMMAND} ../${ZLIB}
		 # CMAKE_ARGS 
		 # BUILD_COMMAND ${CMAKE_COMMAND} --build .
		 # INSTALL_COMMAND ${CMAKE_COMMAND} --install . --prefix ${PROJECT_SOURCE_DIR}
		 # UPDATE_COMMAND ""  # Don't rebuild on recompilation
	# )
	# # add_library(zlib STATIC IMPORTED)
	# # set_property(TARGET zlib PROPERTY IMPORTED_LOCATION ${PROJECT_SOURCE_DIR}/lib/libunity.a)
	# # add_dependencies(scantailor zlib)

# ENDIF()

# FIND_PATH(
	# ZLIB_INCLUDE_DIR zlib.h
	# PATHS /usr/local/include /usr/include
	# HINTS ${ZLIB_DIR} # ZLIB_DIR may come from export-vars.cmake
	# DOC "Path to zlib headers."
# )
# IF(NOT ZLIB_INCLUDE_DIR)
	# MESSAGE(
		# FATAL_ERROR
		# "Could not find zlib headers.\n"
		# "You may need to install a package named zlib1g-dev or similarly."
	# )
# ENDIF()

# INCLUDE_DIRECTORIES("${ZLIB_INCLUDE_DIR}")

# FIND_LIBRARY(
	# ZLIB_LIBRARY NAMES z zdll libz
	# PATHS /usr/local/lib /usr/lib
	# HINTS ${STAGING_LIBS_DIR}
	# DOC "Path to zlib library."
# )
# IF(NOT ZLIB_LIBRARY)
	# MESSAGE(
		# FATAL_ERROR
		# "Could not find zlib library.\n"
		# "You may need to install a package named zlib1g-dev or similarly."
	# )
# ENDIF()

# # Find dll
# IF(WIN32)
	# FILE(GLOB ZLIB_DLL 
		# LIST_DIRECTORIES false
		# "${QT_BUILD_DIR}/bin/*z*.dll")
	# IF(NOT ZLIB_DLL)
		# MESSAGE(
			# FATAL_ERROR
			# "Could not find zlib dll in dependency qt-build\\bin folder."
		# )
	# ENDIF()
# ENDIF()


# #============================ PNG ===============================#

# FIND_PATH(
	# PNG_INCLUDE_DIR png.h
	# PATHS /usr/local/include /usr/include
	# HINTS ${PNG_DIR} # PNG_DIR may come from export-vars.cmake
	# DOC "Path to libpng headers."
# )
# IF(NOT PNG_INCLUDE_DIR)
	# MESSAGE(
		# FATAL_ERROR
		# "Could not find libpng headers.\n"
		# "You may need to install a package named libpng12-dev or similarly."
	# )
# ENDIF()

# INCLUDE_DIRECTORIES("${PNG_INCLUDE_DIR}")

# FIND_LIBRARY(
	# PNG_LIBRARY NAMES png libpng
	# PATHS /usr/local/lib /usr/lib
	# HINTS ${STAGING_LIBS_DIR}
	# DOC "Path to png library."
# )
# IF(NOT PNG_LIBRARY)
	# MESSAGE(
		# FATAL_ERROR
		# "Could not find libpng library.\n"
		# "You may need to install a package named libpng12-dev or similarly."
	# )
# ENDIF()

# # Find dll
# IF(WIN32)
	# FILE(GLOB PNG_DLL 
		# LIST_DIRECTORIES false
		# "${QT_BUILD_DIR}/bin/*png*.dll")
	# IF(NOT PNG_DLL)
		# MESSAGE(
			# FATAL_ERROR
			# "Could not find png dll in dependency qt-build\\bin folder."
		# )
	# ENDIF()
# ENDIF()


# #============================ TIFF ===============================#

# FIND_PATH(
	# TIFF_INCLUDE_DIR tiff.h
	# PATHS /usr/local/include /usr/include
	# HINTS ${TIFF_DIR} # TIFF_DIR may come from export-vars.cmake
	# PATH_SUFFIXES libtiff
	# DOC "Path to libtiff headers."
# )
# IF(NOT TIFF_INCLUDE_DIR)
	# MESSAGE(
		# FATAL_ERROR
		# "Could not find libtiff headers.\n"
		# "You may need to install a package named libtiff4-dev or similarly."
	# )
# ENDIF()

# INCLUDE_DIRECTORIES("${TIFF_INCLUDE_DIR}")

# FIND_LIBRARY(
	# TIFF_LIBRARY NAMES tiff libtiff
	# PATHS /usr/local/lib /usr/lib
	# HINTS ${STAGING_LIBS_DIR}
	# PATH_SUFFIXES libtiff
	# DOC "Path to tiff library."
# )
# IF(NOT TIFF_LIBRARY)
	# MESSAGE(
		# FATAL_ERROR
		# "Could not find libtiff library.\n"
		# "You may need to install a package named libtiff4-dev or similarly."
	# )
# ENDIF()

# # Find dll
# IF(WIN32)
	# FILE(GLOB TIFF_DLL 
		# LIST_DIRECTORIES false
		# "${QT_BUILD_DIR}/bin/*tiff*.dll")
	# IF(NOT TIFF_DLL)
		# MESSAGE(
			# FATAL_ERROR
			# "Could not find tiff dll in dependency qt-build\\bin folder."
		# )
	# ENDIF()
# ENDIF()


# #============================ Openjpeg ===============================#

# FIND_PATH(
	# OPENJPEG_INCLUDE_DIR openjpeg.h
	# PATHS ${OPENJPEG_DIR} # OPENJPEG_DIR may come from export-vars.cmake
	# PATH_SUFFIXES /src/lib/openjp2
	# DOC "Path to openjpeg headers."
# )
# IF(NOT OPENJPEG_INCLUDE_DIR)
	# MESSAGE(
		# FATAL_ERROR
		# "Could not find openjpeg headers.\n"
		# "You may need to install a package named libopenjp2-dev or similarly."
	# )
# ENDIF()

# INCLUDE_DIRECTORIES("${OPENJPEG_INCLUDE_DIR}")

# FIND_LIBRARY(
	# OPENJPEG_LIBRARY NAMES openjp2 libopenjp2
	# PATHS /usr/local/lib /usr/lib
	# HINTS ${STAGING_LIBS_DIR}
	# DOC "Path to openjpeg library."
# )
# IF(NOT OPENJPEG_LIBRARY)
	# MESSAGE(
		# FATAL_ERROR
		# "Could not find openjpeg library.\n"
		# "You may need to install a package named libopenjp2-dev or similarly."
	# )
# ENDIF()

# # Find dll
# IF(WIN32)
	# FILE(GLOB OPENJPEG_DLL 
		# LIST_DIRECTORIES false
		# "${QT_BUILD_DIR}/bin/*openjp*.dll")
	# IF(NOT OPENJPEG_DLL)
		# MESSAGE(
			# FATAL_ERROR
			# "Could not find openjp2 dll in dependency qt-build\\bin folder."
		# )
	# ENDIF()
# ENDIF()


# #============================ Podofo ===============================#

# FIND_PATH(
	# PODOFO_INCLUDE_DIR podofo.h
	# PATHS ${PODOFO_DIR} # PODOFO_DIR may come from export-vars.cmake
	# PATH_SUFFIXES /podofo /src/podofo
	# DOC "Path to podofo headers."
# )
# IF(NOT PODOFO_INCLUDE_DIR)
	# MESSAGE(
		# FATAL_ERROR
		# "Could not find podofo headers.\n"
		# "You may need to install a package named podofo or similarly."
	# )
# ENDIF()

# INCLUDE_DIRECTORIES("${PODOFO_INCLUDE_DIR}/../"	"${DEPS_BUILD_DIR}/podofo-build"
# )
	
# FIND_LIBRARY(
	# PODOFO_LIBRARY NAMES podofo libpodofo
	# PATHS /usr/local/lib /usr/lib
	# HINTS ${STAGING_LIBS_DIR}
	# DOC "Path to podofo library."
# )
# IF(NOT PODOFO_LIBRARY)
	# MESSAGE(
		# FATAL_ERROR
		# "Could not find podofo library.\n"
		# "You may need to install a package named podofo or similarly."
	# )
# ENDIF()


# IF(WIN32)
	# ADD_DEFINITIONS(-DUSE_LIBTIFF_DLL -DUSING_SHARED_PODOFO)
	
	# # Find dll
	# FILE(GLOB PODOFO_DLL 
		# LIST_DIRECTORIES false
		# "${QT_BUILD_DIR}/bin/*podofo*.dll")
	# IF(NOT PODOFO_DLL)
		# MESSAGE(
			# FATAL_ERROR
			# "Could not find podofo dll in dependency qt-build\\bin folder."
		# )
	# ENDIF()
	
	# FILE(GLOB FREETYPE_DLL 
		# LIST_DIRECTORIES false
		# "${QT_BUILD_DIR}/bin/*freetype*.dll")
	# IF(NOT FREETYPE_DLL)
		# MESSAGE(
			# FATAL_ERROR
			# "Could not find freetype dll in dependency qt-build\\bin folder."
		# )
	# ENDIF()
	
# ENDIF()

#============================ Boost ===============================#

# IF(WIN32)
	# SET(Boost_USE_STATIC_LIBS ON)
# ELSE(WIN32)
	# ADD_DEFINITIONS(-DBOOST_TEST_DYN_LINK)
# ENDIF(WIN32)

# SET(Boost_USE_MULTITHREADED ON)
# FIND_PACKAGE(Boost 1.35.0 QUIET COMPONENTS unit_test_framework prg_exec_monitor)
# IF(NOT Boost_FOUND)
	
	# # Try to find boost lib build cmake config directory
	# FILE(GLOB BOOST_CMAKE_CONF
		# LIST_DIRECTORIES TRUE
		# "${BOOST_BUILD_DIR}/lib/cmake/Boost-*" # BOOST_BUILD_DIR may come from export-vars.cmake
	# )
	
	# # Try again in config mode with our own path
	# FIND_PACKAGE(Boost 1.35.0 COMPONENTS unit_test_framework prg_exec_monitor
		# PATHS "${BOOST_CMAKE_CONF}"
	# )
	
	# IF(NOT Boost_FOUND)
		# MESSAGE(
			# FATAL_ERROR
			# "Could not find boost headers or libraries. "
			# "You may need to install a package named libboost1.35-dev or similarly. "
			# "Hint: create a Boost_DEBUG variable in cmake and set it to YES." 
		# )
	# ENDIF(NOT Boost_FOUND)
# ENDIF(NOT Boost_FOUND)

# INCLUDE_DIRECTORIES(${Boost_INCLUDE_DIRS})
# LINK_DIRECTORIES(${Boost_LIBRARY_DIRS})


#============================ Threads ===============================#

IF(UNIX)
	FindPthreads()
	IF(PTHREADS_FOUND)
		ADD_DEFINITIONS(${PTHREADS_CFLAGS})
		LINK_LIBRARIES(${PTHREADS_LIBS})
	ELSE(PTHREADS_FOUND)
		MESSAGE(
			FATAL_ERROR
			"Could not detect threading flags.\n"
			"Try specifying them manually in PTHREADS_CFLAGS and PTHREADS_LIBS."
		)
	ENDIF(PTHREADS_FOUND)
elseif(WIN32 AND MSVC)
	add_definitions(-DNOMINMAX)
endif(UNIX)


# Other includes and options
set(EXTRA_LIBS "")

if(WIN32)
	list(APPEND EXTRA_LIBS winmm imm32 ws2_32 ole32 oleaut32 uuid gdi32 comdlg32 winspool)
endif()

list(APPEND EXTRA_LIBS ${LIB_ZLIB} ${LIB_JPEG} ${LIB_PNG} ${LIB_TIFF}
	${LIB_OPENJP} ${LIB_PODOFO}
)

#${TIFF_LIBRARY} ${PNG_LIBRARY} ${ZLIB_LIBRARY}
#	${JPEG_LIBRARY} ${OPENJPEG_LIBRARY} ${PODOFO_LIBRARY})

set(MAYBE_QT_OPENGL_MODULE "")
if(ENABLE_OPENGL)
	LIST(APPEND EXTRA_LIBS ${OPENGL_LIBRARIES})
	SET(MAYBE_QT_OPENGL_MODULE Qt5::OpenGL)
endif()


#==================================================================#
#========================== Scantailor ============================#
#==================================================================#

if(HAVE_QT5)

# Prepare config.h
if(WIN32)
	set(TRANSLATION_DIRS ".:translations")
	set(PLUGIN_DIRS ".")
else()
	set(TRANSLATION_DIRS ".:${CMAKE_INSTALL_PREFIX}/share/scantailor/translations")
	set(PLUGIN_DIRS ".:${CMAKE_INSTALL_PREFIX}/lib/scantailor")
endif()

configure_file(config.h.in ${CMAKE_BINARY_DIR}/config.h @ONLY)

add_subdirectory(ui)
include_directories("${toplevel_ui_sources_BINARY_DIR}")
link_libraries(${EXTRA_LIBS})

# crash_reporter is included unconditionally to collect translation sources from there.
add_subdirectory(crash_reporter)
add_subdirectory(dewarping)
add_subdirectory(foundation)
add_subdirectory(math)
add_subdirectory(imageproc)
add_subdirectory(interaction)
add_subdirectory(zones)
add_subdirectory(acceleration)
add_subdirectory(tests)

add_subdirectory(filters/fix_orientation)
add_subdirectory(filters/page_split)
add_subdirectory(filters/deskew)
add_subdirectory(filters/select_content)
add_subdirectory(filters/page_layout)
add_subdirectory(filters/output)

set(resource_files resources/resources.qrc resources/icons/COPYING)
if(WIN32)
	list(APPEND resource_files resources/win32/resources.rc)
endif()
source_group("Resources" FILES ${resource_files})

qt5_add_resources(resource_sources resources/resources.qrc)
source_group("Generated" FILES ${resource_sources})

set(
	common_sources
	BackgroundExecutor.cpp BackgroundExecutor.h
	OpenGLSupport.cpp OpenGLSupport.h
	PixmapRenderer.cpp PixmapRenderer.h
	BubbleAnimation.cpp BubbleAnimation.h
	ProcessingIndicationWidget.cpp ProcessingIndicationWidget.h
	NonOwningWidget.cpp NonOwningWidget.h
	ContentBox.cpp ContentBox.h
	SmartFilenameOrdering.cpp SmartFilenameOrdering.h
	AbstractRelinker.h
	RelinkablePath.cpp RelinkablePath.h
	ImageInfo.cpp ImageInfo.h
	ImageFileInfo.h
	ImageMetadata.cpp ImageMetadata.h
	RecentProjects.cpp RecentProjects.h
	OutOfMemoryHandler.cpp OutOfMemoryHandler.h
	CommandLine.cpp CommandLine.h
	PageSelectionAccessor.cpp PageSelectionAccessor.h
	PageSelectionProvider.h
	ContentSpanFinder.cpp ContentSpanFinder.h
	ImagePixmapUnion.h
	ImageViewBase.cpp ImageViewBase.h
	BasicImageView.cpp BasicImageView.h
	DebugImageView.cpp DebugImageView.h
	VectorFieldImageView.cpp VectorFieldImageView.h
	TabbedDebugImages.cpp TabbedDebugImages.h
	ThumbnailLoadResult.h
	ThumbnailPixmapCache.cpp ThumbnailPixmapCache.h
	ThumbnailBase.cpp ThumbnailBase.h
	ThumbnailFactory.cpp ThumbnailFactory.h
	IncompleteThumbnail.cpp IncompleteThumbnail.h
	ContentBoxPropagator.cpp ContentBoxPropagator.h
	PageOrientationPropagator.cpp PageOrientationPropagator.h
	DebugImagesImpl.cpp DebugImagesImpl.h
	DebugViewFactory.h
	ImageId.cpp ImageId.h
	PageId.cpp PageId.h
	PageInfo.cpp PageInfo.h
	BackgroundTask.cpp BackgroundTask.h
	ProcessingTaskQueue.cpp ProcessingTaskQueue.h
	PageSequence.cpp PageSequence.h
	StageSequence.cpp StageSequence.h
	ProjectPages.cpp ProjectPages.h
	ImageMetadataLoader.cpp ImageMetadataLoader.h
	TiffReader.cpp TiffReader.h
	TiffWriter.cpp TiffWriter.h
	JP2Reader.cpp JP2Reader.h
	PdfReader.cpp PdfReader.h
	PngMetadataLoader.cpp PngMetadataLoader.h
	TiffMetadataLoader.cpp TiffMetadataLoader.h
	JpegMetadataLoader.cpp JpegMetadataLoader.h
	JP2MetadataLoader.cpp JP2MetadataLoader.h
	PdfMetadataLoader.cpp PdfMetadataLoader.h
	ImageLoader.cpp ImageLoader.h
	ErrorWidget.cpp ErrorWidget.h
	OrthogonalRotation.cpp OrthogonalRotation.h
	WorkerThreadPool.cpp WorkerThreadPool.h
	LoadFileTask.cpp LoadFileTask.h
	FilterOptionsWidget.h
	TaskStatus.h FilterUiInterface.h
	ProjectReader.cpp ProjectReader.h
	ProjectWriter.cpp ProjectWriter.h
	AtomicFileOverwriter.cpp AtomicFileOverwriter.h
	EstimateBackground.cpp EstimateBackground.h
	Despeckle.cpp Despeckle.h
	FileNameDisambiguator.cpp FileNameDisambiguator.h
	OutputFileNameGenerator.cpp OutputFileNameGenerator.h
	PageRange.cpp PageRange.h
	SelectedPage.cpp SelectedPage.h
	Utils.cpp Utils.h
	PageView.h
	AutoManualMode.h
	AbstractCommand.h
	AbstractFilter.h
	BeforeOrAfter.h
	FilterResult.h
	CompositeCacheDrivenTask.h
	ChangedStateItemDelegate.h
	PageOrderProvider.h
	PageOrderOption.h
	PayloadEvent.h
	filter_dc/AbstractFilterDataCollector.h
	filter_dc/ThumbnailCollector.h
	filter_dc/ContentBoxCollector.h
	filter_dc/PageOrientationCollector.h
	version.h
	config.h.in
	${common_ui_files}
)

set(
	gui_only_sources
	Application.cpp Application.h
	SkinnedButton.cpp SkinnedButton.h
	StageListView.cpp StageListView.h
	RelinkablePathVisualization.cpp RelinkablePathVisualization.h
	RelinkingModel.cpp RelinkingModel.h
	RelinkingSortingModel.cpp RelinkingSortingModel.h
	RelinkingListView.cpp RelinkingListView.h
	RelinkingDialog.cpp RelinkingDialog.h
	SettingsDialog.cpp SettingsDialog.h
	LoadFilesStatusDialog.cpp LoadFilesStatusDialog.h
	ProjectCreationContext.cpp ProjectCreationContext.h
	ProjectOpeningContext.cpp ProjectOpeningContext.h
	OutOfMemoryDialog.cpp OutOfMemoryDialog.h
	ThumbnailSequence.cpp ThumbnailSequence.h
	ProjectFilesDialog.cpp ProjectFilesDialog.h
	NewOpenProjectPanel.cpp NewOpenProjectPanel.h
	SystemLoadWidget.cpp SystemLoadWidget.h
	MainWindow.cpp MainWindow.h
	main.cpp
)

if(BUILD_CLI)
	SET(
		cli_only_sources
		ConsoleBatch.cpp ConsoleBatch.h
		main-cli.cpp
	)
endif()

source_group("Sources" FILES ${common_sources} ${gui_only_sources} ${cli_only_sources})
source_group("Special Headers" FILES version.h config.h.in)

# Compatibility for CMAKE >= 3.10
if(POLICY CMP0071)
    cmake_policy(SET CMP0071 NEW)
endif(POLICY CMP0071)

# IF(CMAKE_COMPILER_IS_GNUCXX)
	# # There seems to be a bug in either gcc or boost that makes page sorting either crash
	# # or go into infinite loop.  It's reproducible on a very simple test case on at least
	# # gcc 4.4.3 and gcc 4.4.4.  It's not reproducible on gcc 4.5.1.
	# # Adding -fno-strict-aliasing seems to fix it.
	# SET_SOURCE_FILES_PROPERTIES(
		# ThumbnailSequence.cpp PROPERTIES
		# COMPILE_FLAGS "-fno-strict-aliasing"
	# )
# ENDIF()

set(win32_resource_file "")
if(WIN32)
	set(rc_file "${CMAKE_SOURCE_DIR}/resources/win32/resources.rc")
	file(GLOB win32_resources resources/win32/*.ico)
	set_source_files_properties(
		"${rc_file}" PROPERTIES
		OBJECT_DEPENDS ${win32_resources}
	)
	set(win32_resource_file "${rc_file}")
endif(WIN32)

add_library(stcore STATIC ${common_sources} ${common_ui_sources})
target_link_libraries(stcore acceleration deskew Qt5::Widgets Qt5::Xml ${MAYBE_QT_OPENGL_MODULE})
if(STATIC_BUILD)
	target_link_libraries(stcore imageproc acceleration "${EXTERN}/lib/libtiff.a" "${EXTERN}/lib/libopenjp2.a")
endif()
add_dependencies(stcore toplevel_ui_sources)

# Some includes need to be added manually in new build system
target_include_directories(
	stcore PUBLIC AFTER
	PUBLIC ${ALL_EXTERN_INC_DIRS}
)

add_executable(
	scantailor WIN32 ${gui_only_sources} ${resource_sources} ${win32_resource_file}
)

target_link_libraries(
	scantailor PUBLIC
	acceleration page_layout output
	fix_orientation page_split deskew select_content stcore
	dewarping zones interaction imageproc math foundation
	${EXTRA_LIBS}
)

install(TARGETS scantailor RUNTIME DESTINATION bin)

if(BUILD_CLI)
	add_executable(scantailor-cli ${cli_only_sources} ${common_ui_sources})

	target_link_libraries(
		scantailor-cli
		acceleration page_layout output
		fix_orientation page_split deskew select_content stcore
		dewarping zones interaction imageproc math foundation
		${EXTRA_LIBS}
	)
	
	install(TARGETS scantailor-cli RUNTIME DESTINATION bin)
endif()


IF(ENABLE_CRASH_REPORTER)
	FIND_PATH(
		SYMBOLS_PATH . PATHS "${build_outer_dir}/symbols"
		"${source_outer_dir}/symbols" NO_DEFAULT_PATH
		DOC "The directory to write symbol information into."
	)
	IF(NOT SYMBOLS_PATH)
		MESSAGE(FATAL_ERROR "SYMBOLS_PATH directory is not set.")
	ENDIF()

	# We can't build it, because it requires ATL, which is not part
	# of the Visual Studio Express Edition, so we rely on a pre-built
	# version which can be found in the Mozilla repository.
	FIND_PROGRAM(
		DUMP_SYMS_EXECUTABLE dump_syms PATHS "${build_outer_dir}" "${source_outer_dir}"
		DOC "Path to dump_syms.exe, which can be found in Mozilla repository."
	)
	IF(NOT DUMP_SYMS_EXECUTABLE)
		MESSAGE(
			FATAL_ERROR "dump_syms.exe wasn't found.  Specify its location manually by setting the DUMP_SYMS_EXECUTABLE variable.  dump_syms.exe may be found in the Mozilla repository under /toolkit/crashreporter/tools/win32"
		)
	ENDIF()

	INCLUDE_DIRECTORIES(crash_reporter crash_reporter/google-breakpad)
	TARGET_LINK_LIBRARIES(scantailor crash_handler)
ENDIF()

# Translations
TRANSLATION_SOURCES(
	scantailor
	${common_sources} ${gui_only_sources} ${cli_only_sources}
)
FILE(GLOB TRANSLATION_FILES translations/scantailor_*.ts)
FILE(GLOB CR_TRANSLATION_FILES translations/crashreporter_*.ts)

FINALIZE_TRANSLATION_SET(scantailor ${TRANSLATION_FILES})
FINALIZE_TRANSLATION_SET(crashreporter ${CR_TRANSLATION_FILES})
UPDATE_TRANSLATIONS_TARGET(update_translations scantailor crashreporter)

SET(ts_files ${TRANSLATION_FILES})
IF(ENABLE_CRASH_REPORTER)
	LIST(APPEND ts_files ${CR_TRANSLATION_FILES})
ENDIF(ENABLE_CRASH_REPORTER)

# Don't build *.qm files from *untranslated.ts
SET(FILTERED_TRANSLATION_FILES)
FOREACH(ts_file ${ts_files})
	IF ("${ts_file}" MATCHES ".*untranslated.ts")
		# Just skip it.
	ELSE("${ts_file}" MATCHES ".*untranslated.ts")
		LIST(APPEND FILTERED_TRANSLATION_FILES "${ts_file}")
	ENDIF("${ts_file}" MATCHES ".*untranslated.ts")
ENDFOREACH(ts_file)

QT5_ADD_TRANSLATION(QM_FILES ${FILTERED_TRANSLATION_FILES})
ADD_CUSTOM_TARGET(compile_translations ALL DEPENDS ${QM_FILES})

INSTALL(FILES ${QM_FILES} DESTINATION "share/scantailor/translations")

# Source code packaging
SET(CPACK_CMAKE_GENERATOR "")
SET(CPACK_SOURCE_GENERATOR "TGZ")
SET(CPACK_SOURCE_PACKAGE_FILE_NAME "scantailor-${VERSION}")
SET(
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
INCLUDE(CPack)

IF(WIN32 AND NOT STATIC_BUILD)
	# Copy some DLLs to the staging dir.
	## TODO: Can we maybe use qtwindeploy here?
	
	# Qt core
	SET(
		qt5_libs
		${Qt5Widgets_LIBRARIES} ${Qt5Gui_LIBRARIES}
		${Qt5Core_LIBRARIES} ${Qt5Xml_LIBRARIES}
	)
	IF(ENABLE_OPENGL)
		LIST(APPEND qt5_libs ${Qt5OpenGL_LIBRARIES})
	ENDIF()
	FOREACH(target ${qt5_libs})
		GET_TARGET_PROPERTY(debug_loc "${target}" LOCATION_DEBUG)
		GET_TARGET_PROPERTY(release_loc "${target}" LOCATION_RELEASE)
		COPY_TO_BUILD_DIR("${debug_loc}" CONFIGURATIONS Debug)
		COPY_TO_BUILD_DIR("${release_loc}" CONFIGURATIONS Release MinSizeRel RelWithDebInfo)
	ENDFOREACH()
	
	# Libs
	COPY_TO_BUILD_DIR(
		"${JPEG_DLL}" "${PNG_DLL}" "${ZLIB_DLL}" "${TIFF_DLL}" "${OPENJPEG_DLL}"
		"${PODOFO_DLL}" "${FREETYPE_DLL}" 
	)
	
	# Mingw runtimes
	IF(MINGW)
		## TODO: Copy libcc*.dll to build dir
	
	ENDIF()

	# Qt's plugins
	SET(PLUGINS_DIR "${QT_BUILD_DIR}/plugins")
	COPY_TO_BUILD_DIR(
		"${PLUGINS_DIR}/platforms/qwindows.dll" SUBDIR platforms
		CONFIGURATIONS Release MinSizeRel RelWithDebInfo
	)
	COPY_TO_BUILD_DIR(
		"${PLUGINS_DIR}/platforms/qwindowsd.dll" SUBDIR platforms
		CONFIGURATIONS Debug
	)

	COPY_TO_BUILD_DIR(
		"${PLUGINS_DIR}/imageformats/qjpeg.dll" SUBDIR imageformats
		CONFIGURATIONS Release MinSizeRel RelWithDebInfo
	)
	COPY_TO_BUILD_DIR(
		"${PLUGINS_DIR}/imageformats/qjpegd.dll" SUBDIR imageformats
		CONFIGURATIONS Debug
	)
	
	# Compatibility with QT >= 5.10
	IF(EXISTS "${PLUGINS_DIR}/styles/qwindowsvistastyle.dll")
		COPY_TO_BUILD_DIR(
			"${PLUGINS_DIR}/styles/qwindowsvistastyle.dll" SUBDIR styles
			CONFIGURATIONS Release MinSizeRel RelWithDebInfo
		)
	ENDIF()
	
	IF(EXISTS "${PLUGINS_DIR}/styles/qwindowsvistastyled.dll")
		COPY_TO_BUILD_DIR(
			"${PLUGINS_DIR}/styles/qwindowsvistastyled.dll" SUBDIR styles
			CONFIGURATIONS Debug
		)
	ENDIF()
	
	# Compatibility with QT < 5.4
	IF(EXISTS "${PLUGINS_DIR}/accessible/qtaccessiblewidgets.dll")
		COPY_TO_BUILD_DIR(
			"${PLUGINS_DIR}/accessible/qtaccessiblewidgets.dll" SUBDIR accessible
			CONFIGURATIONS Release MinSizeRel RelWithDebInfo
		)
	ENDIF()

	IF(EXISTS "${PLUGINS_DIR}/accessible/qtaccessiblewidgetsd.dll")
		COPY_TO_BUILD_DIR(
			"${PLUGINS_DIR}/accessible/qtaccessiblewidgetsd.dll" SUBDIR accessible
			CONFIGURATIONS Debug
		)
	ENDIF()
	
	# Generate the target that will actually do the copying.
	GENERATE_COPY_TO_BUILD_DIR_TARGET(copy_to_build_dir)
	
	# Installer for Windows.  Must go last.
	ADD_SUBDIRECTORY(packaging/windows)
ENDIF(WIN32 AND NOT STATIC_BUILD)

endif(HAVE_QT5)
