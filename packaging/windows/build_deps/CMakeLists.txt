CMAKE_MINIMUM_REQUIRED(VERSION 3.1.0)


# Needed, otherwise cmake error occurs:
# CMake Error: Error required internal CMake variable not set, cmake may not be built correctly.
# Missing variable is:
# CMAKE_ASM_COMPILE_OBJECT
ENABLE_LANGUAGE( C CXX ASM )

SET(
	CMAKE_USER_MAKE_RULES_OVERRIDE
	"${CMAKE_SOURCE_DIR}/../../../cmake/default_cflags.cmake"
)
SET(
	CMAKE_USER_MAKE_RULES_OVERRIDE_CXX
	"${CMAKE_SOURCE_DIR}/../../../cmake/default_cxxflags.cmake"
)

PROJECT("Scan Tailor PDF Dependencies")

INCLUDE(../../../cmake/SetDefaultBuildType.cmake)
INCLUDE(../../../cmake/SetDefaultGccFlags.cmake)
INCLUDE(../../../cmake/ToNativePath.cmake)
INCLUDE(../../../cmake/PatchFile.cmake)
INCLUDE(TestCXXAcceptsFlag)

ST_SET_DEFAULT_BUILD_TYPE(Release)
ST_SET_DEFAULT_GCC_FLAGS()

GET_FILENAME_COMPONENT(source_outer_dir "${PROJECT_SOURCE_DIR}/../../../.." ABSOLUTE)
GET_FILENAME_COMPONENT(build_outer_dir "${PROJECT_BINARY_DIR}/.." ABSOLUTE)

# we are compiling for x64
SET(WANT_LIB64 ON)

SET(suggest_jom FALSE)


IF(MSVC)

	# JOM works only with msvc
	FIND_PROGRAM(JOM_EXECUTABLE jom HINTS "${source_outer_dir}" "${build_outer_dir}")
	IF(JOM_EXECUTABLE)
		SET(MAKE_COMMAND "\"${JOM_EXECUTABLE}\"")
	ENDIF()
	IF(NOT JOM_EXECUTABLE)
		SET(MAKE_COMMAND nmake)
		SET(suggest_jom TRUE)
	ENDIF()

	IF(MSVC_VERSION LESS 1900)
		MESSAGE(FATAL_ERROR "This Visual Studio version is too old and is not supported. Only Visual Studio 2015 and newer or MinGW are currently supported.")
	ELSE()
		SET(qt_platform win32-msvc)
		SET(boost_toolset msvc)
	ENDIF()
	
ELSEIF(MINGW)
	
	SET(qt_platform win32-g++)
	SET(boost_toolset gcc)
	
	# Set number of cores to speed up Qt compilation
	INCLUDE(ProcessorCount)
	ProcessorCount(N)
	MATH(EXPR THREADS "${N} - 1")
	IF(NOT N EQUAL 0)
		SET(MAKE_COMMAND "mingw32-make -j${THREADS}")
	ELSE()
		SET(MAKE_COMMAND "mingw32-make")
	ENDIF()
	
ELSE()
	MESSAGE(FATAL_ERROR "Unsupported compiler. Only Visual Studio 2015 and newer and MinGW are currently supported.")
ENDIF()


## Set up dependency search

FILE(GLOB jpeg_dirs1 "${build_outer_dir}/libjpeg-turbo-[0-9]*.[0-9]*.[0-9]*")
FILE(GLOB jpeg_dirs2 "${source_outer_dir}/libjpeg-turbo-[0-9]*.[0-9]*.[0-9]*")
FILE(GLOB zlib_dirs1 "${build_outer_dir}/zlib-[0-9]*.[0-9]*.[0-9]*")
FILE(GLOB zlib_dirs2 "${source_outer_dir}/zlib-[0-9]*.[0-9]*.[0-9]*")
FILE(GLOB png_dirs1 "${build_outer_dir}/libpng-[0-9]*.[0-9]*.[0-9]*")
FILE(GLOB png_dirs2 "${source_outer_dir}/libpng-[0-9]*.[0-9]*.[0-9]*")
FILE(GLOB png_dirs3 "${build_outer_dir}/lpng[0-9]*")
FILE(GLOB png_dirs4 "${source_outer_dir}/lpng[0-9]*")
FILE(GLOB tiff_dirs1 "${build_outer_dir}/tiff-[0-9]*.[0-9]*.[0-9]*")
FILE(GLOB tiff_dirs2 "${source_outer_dir}/tiff-[0-9]*.[0-9]*.[0-9]*")	
FILE(GLOB openjpeg_dirs1 "${build_outer_dir}/openjpeg-[0-9]*.[0-9]*.[0-9]*")
FILE(GLOB openjpeg_dirs2 "${source_outer_dir}/openjpeg-[0-9]*.[0-9]*.[0-9]*")
FILE(GLOB freetype_dirs1 "${build_outer_dir}/freetype-[0-9]*.[0-9]*.[0-9]*")
FILE(GLOB freetype_dirs2 "${source_outer_dir}/freetype-[0-9]*.[0-9]*.[0-9]*")
FILE(GLOB podofo_dirs1 "${build_outer_dir}/podofo-[0-9]*.[0-9]*.[0-9]*")
FILE(GLOB podofo_dirs2 "${source_outer_dir}/podofo-[0-9]*.[0-9]*.[0-9]*")
FILE(GLOB qt_dirs1 "${build_outer_dir}/qt-win-*-5.[0-9]*")
FILE(GLOB qt_dirs2 "${build_outer_dir}/qt-everywhere-*-5.[0-9]*")
FILE(GLOB qt_dirs3 "${source_outer_dir}/qt-win-*-5.[0-9]*")
FILE(GLOB qt_dirs4 "${source_outer_dir}/qt-everywhere-*-5.[0-9]*")
FILE(GLOB qt_dirs5 "C:/Qt/Qt5.*/*/Src")
FILE(GLOB boost_dirs1 "${build_outer_dir}/boost_1_[0-9]*_[0-9]*")
FILE(GLOB boost_dirs2 "${source_outer_dir}/boost_1_[0-9]*_[0-9]*")

FIND_PATH(
	JPEG_DIR jpeglib.h HINTS ${jpeg_dirs1} ${jpeg_dirs2}
	DOC "Path to jpeg source directory."
)
FIND_PATH(
	ZLIB_DIR zlib.h HINTS ${zlib_dirs1} ${zlib_dirs2}
	DOC "Path to zlib source directory."
)
FIND_PATH(
	PNG_DIR png.h HINTS ${png_dirs1} ${png_dirs2} ${png_dirs3} ${png_dirs4}
	DOC "Path to libpng source directory."
)
FIND_PATH(
	TIFF_DIR libtiff/tiff.h HINTS ${tiff_dirs1} ${tiff_dirs2}
	DOC "Path to top-level tiff source directory."
)
FIND_PATH(
	OPENJPEG_DIR src/lib/openjp2/openjpeg.h HINTS ${openjpeg_dirs1} ${openjpeg_dirs2}
	DOC "Path to top-level openjpeg source directory."
)
FIND_PATH(
	FREETYPE_DIR ChangeLog.20 HINTS ${freetype_dirs1} ${freetype_dirs2}
	DOC "Path to top-level freetype source directory."
)
FIND_PATH(
	PODOFO_DIR podofo_config.h.in HINTS ${podofo_dirs1} ${podofo_dirs2}
	DOC "Path to top-level podofo source directory."
)
FIND_PATH(
	QT_SRC_DIR NAMES qtbase/qtbase.pro HINTS ${qt_dirs1} ${qt_dirs2}
	${qt_dirs3} ${qt_dirs4} ${qt_dirs5}
	DOC "Path to top-level Qt5 source directory. If you installed a binary version, it will be something like C:\\Qt\\Qt5.0.2\\5.0.2\\Src"
)
FIND_PATH(
	BOOST_DIR boost/foreach.hpp HINTS ${boost_dirs1} ${boost_dirs2}
	DOC "Path to top-level Boost source directory."
)

IF(NOT JPEG_DIR)
	MESSAGE(FATAL_ERROR "JPEG source directory not found. You may specify it manually.")
ELSEIF(NOT ZLIB_DIR)
	MESSAGE(FATAL_ERROR "ZLIB source directory not found. You may specify it manually.")
ELSEIF(NOT PNG_DIR)
	MESSAGE(FATAL_ERROR "LibPNG source directory not found. You may specify it manually.")
ELSEIF(NOT TIFF_DIR)
	MESSAGE(FATAL_ERROR "TIFF source directory not found. You may specify it manually.")
ELSEIF(NOT OPENJPEG_DIR)
	MESSAGE(FATAL_ERROR "OpenJPEG source directory not found. You may specify it manually.")
ELSEIF(NOT FREETYPE_DIR)
	MESSAGE(FATAL_ERROR "Freetype source directory not found. You may specify it manually.")	
ELSEIF(NOT PODOFO_DIR)
	MESSAGE(FATAL_ERROR "Podofo source directory not found. You may specify it manually.")
ELSEIF(NOT QT_SRC_DIR)
	MESSAGE(FATAL_ERROR "Qt5 source directory not found. You may specify it manually. If you installed a binary version, it will be something like C:\\Qt\\Qt5.0.2\\5.0.2\\Src")
ELSEIF(NOT BOOST_DIR)
	MESSAGE(FATAL_ERROR "Boost source directory not found. You may specify it manually.")
ENDIF()

SET(QTBASE_DIR "${QT_SRC_DIR}/qtbase")
SET(QTBUILD_DIR "${PROJECT_BINARY_DIR}/qt-build")

FILE(GLOB qt_possible_prebuilt_dirs "${QTBUILD_DIR}/../*")

UNSET(QT_PREBUILT_DIR)
FIND_PATH(
	QT_PREBUILT_DIR bin/linguist.exe HINTS ${qt_possible_prebuilt_dirs}
	DOC "[optional] Installation path of a pre-built version of Qt5 including qttools. If you installed a binary version, it will be something like C:\\Qt\\Qt5.0.2\\5.0.2\\msvc2012"
)

SET(ZLIB_LIB_NAME zlib)
SET(ZLIB_FILE_NAME z)
SET(PNG_LIB_NAME png)
SET(JPEG_LIB_NAME jpeg)
SET(TIFF_LIB_NAME tiff)
SET(TIFFXX_LIB_NAME tiffxx)
SET(OPENJPEG_LIB_NAME openjp2)
SET(PODOFO_LIB_NAME podofo)
SET(FREETYPE_LIB_NAME freetype)
SET(PODOFO_SHARED_LIB_NAME podofo-shared)

MACRO(LIST_ITEMS_PREPEND LIST PREFIX)
	SET(tmp_list_)
	FOREACH(item ${${LIST}})
		LIST(APPEND tmp_list_ "${PREFIX}${item}")
	ENDFOREACH(item)
	SET(${LIST} ${tmp_list_})
ENDMACRO(LIST_ITEMS_PREPEND)


# set archive extension according to OS and linkers
IF(WIN32)
	IF(MSVC)
		SET(LIB_EXT ".lib")
	ELSE(MSVC)
		# MINGW/GCC
		SET(LIB_EXT ".dll.a")
	ENDIF(MSVC)
ELSE(WIN32)
	# *nix flavours incl. apple
	SET(LIB_EXT ".so")
ENDIF(WIN32)

# set archive prefix according to OS and linkers
SET(LIB_PREFIX "")
IF(WIN32)
	IF(MINGW)
		SET(LIB_PREFIX "lib")
	ENDIF()
ELSE(WIN32)
	# *nix flavours incl. apple
	SET(LIB_PREFIX "lib")
ENDIF(WIN32)


#=================================== ZLIB ===================================#


# Note: Don't set AMD64 option. It breaks Qt build.

ADD_SUBDIRECTORY("${ZLIB_DIR}" "${PROJECT_BINARY_DIR}/zlib-build")

SET_TARGET_PROPERTIES(
	${ZLIB_LIB_NAME} PROPERTIES
	PREFIX ""
	OUTPUT_NAME ${ZLIB_FILE_NAME}
	ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_MINSIZEREL "${CMAKE_BINARY_DIR}/staging/libs"
	RUNTIME_OUTPUT_DIRECTORY_DEBUG "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_RELEASE "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL "${QTBUILD_DIR}/bin"
)

# Don't build executables
SET_TARGET_PROPERTIES(
	example example64 minigzip minigzip64 PROPERTIES
	EXCLUDE_FROM_ALL 1
	EXCLUDE_FROM_DEFAULT_BUILD 1	# for VS generators
)


#=================================== JPEG ===================================#


# Options
SET(WITH_TURBOJPEG OFF CACHE BOOL "Include the TurboJPEG API library and associated test programs")
SET(WITH_JPEG8 ON CACHE BOOL "Emulate libjpeg v8 API/ABI")
SET(ENABLE_STATIC OFF CACHE BOOL "Build static libraries")

ADD_SUBDIRECTORY("${JPEG_DIR}" "${PROJECT_BINARY_DIR}/jpeg-build")

SET_TARGET_PROPERTIES(
	${JPEG_LIB_NAME} PROPERTIES
	PREFIX ""
	ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_MINSIZEREL "${CMAKE_BINARY_DIR}/staging/libs"
	RUNTIME_OUTPUT_DIRECTORY_DEBUG "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_RELEASE "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL "${QTBUILD_DIR}/bin"
)

# Don't build executables
SET_TARGET_PROPERTIES(
	rdjpgcom  wrjpgcom cjpeg djpeg jcstest jpegtran PROPERTIES
	EXCLUDE_FROM_ALL 1
	EXCLUDE_FROM_DEFAULT_BUILD 1	# for VS generators
)



#================================== LIBPNG ==================================#


# Options and dependency locations
SET(PNG_STATIC OFF CACHE BOOL "Build static lib")
SET(PNG_TESTS OFF CACHE BOOL "Build libpng tests")
SET(ZLIB_INCLUDE_DIR "${ZLIB_DIR}")
SET(ZLIB_LIBRARY "${CMAKE_BINARY_DIR}/staging/libs/${LIB_PREFIX}${ZLIB_FILE_NAME}${LIB_EXT}")
SET(SKIP_INSTALL_LIBRARIES 1)

# Include png project
ADD_SUBDIRECTORY("${PNG_DIR}" "${PROJECT_BINARY_DIR}/png-build")

# Since we skip install above, we need to define it ourselves
install(TARGETS png
          EXPORT libpng
          RUNTIME DESTINATION bin
          LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
          ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
          FRAMEWORK DESTINATION ${CMAKE_INSTALL_LIBDIR})

# Modify target to make sure libs are copied to the correct place
SET_TARGET_PROPERTIES(
	${PNG_LIB_NAME} PROPERTIES
	PREFIX ""
	OUTPUT_NAME "${PNG_LIB_NAME}"
	ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_MINSIZEREL "${CMAKE_BINARY_DIR}/staging/libs"
	RUNTIME_OUTPUT_DIRECTORY_DEBUG "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_RELEASE "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL "${QTBUILD_DIR}/bin"
)

# Add zlib build time include
target_include_directories(
	${PNG_LIB_NAME} PUBLIC
	$<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/zlib-build>
)

# Don't build executables
SET_TARGET_PROPERTIES(
	pngfix png-fix-itxt PROPERTIES
	EXCLUDE_FROM_ALL 1
	EXCLUDE_FROM_DEFAULT_BUILD 1	# for VS generators
)

ADD_DEPENDENCIES(
	${PNG_LIB_NAME} ${ZLIB_LIB_NAME}
)


#=================================== TIFF ===================================#


# Options and dependency locations
SET(zlib ON CACHE BOOL "use zlib (required for Deflate compression)")
SET(lzma ON CACHE BOOL "use liblzma (required for LZMA2 compression)")
SET(ZLIB_FOUND TRUE)
SET(ZLIB_INCLUDE_DIRS "${ZLIB_DIR}")
SET(ZLIB_LIBRARIES "${CMAKE_BINARY_DIR}/staging/libs/${LIB_PREFIX}${ZLIB_FILE_NAME}${LIB_EXT}")
SET(JPEG_INCLUDE_DIR "${JPEG_DIR}")	
SET(JPEG_LIBRARY "${CMAKE_BINARY_DIR}/staging/libs/${LIB_PREFIX}${JPEG_LIB_NAME}${LIB_EXT}")

# TIFF jpeg and zlib dependencies search fails, if the archives do not exist yet.
# So create them. They will be overwritten with the actual files
FILE(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/staging/libs/")
FILE(TOUCH "${CMAKE_BINARY_DIR}/staging/libs/${LIB_PREFIX}${JPEG_LIB_NAME}${LIB_EXT}") 
#FILE(TOUCH "${CMAKE_BINARY_DIR}/staging/libs/${LIB_PREFIX}${ZLIB_LIB_NAME}${LIB_EXT}") 

# Include tiff project
ADD_SUBDIRECTORY("${TIFF_DIR}" "${PROJECT_BINARY_DIR}/tiff-build")
#set(ZLIB_SUPPORT TRUE)

# The find jpeg package does not find all includes
target_include_directories(
	${TIFF_LIB_NAME} PUBLIC BEFORE
	PUBLIC "${CMAKE_BINARY_DIR}/jpeg-build"
	PUBLIC "${CMAKE_BINARY_DIR}/zlib-build"
)

# Modify target to make sure libs are copied to the correct place
SET_TARGET_PROPERTIES(
	${TIFF_LIB_NAME} PROPERTIES
	PREFIX ""
	ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_MINSIZEREL "${CMAKE_BINARY_DIR}/staging/libs"
	RUNTIME_OUTPUT_DIRECTORY_DEBUG "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_RELEASE "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL "${QTBUILD_DIR}/bin"
)

ADD_DEPENDENCIES(
	${TIFF_LIB_NAME} ${ZLIB_LIB_NAME} ${JPEG_LIB_NAME}
)


#================================= OPENJPEG =================================#


# Options and dependency locations
SET(BUILD_STATIC_LIBS OFF CACHE BOOL "Build OpenJPEG static library.")
SET(BUILD_CODEC OFF CACHE BOOL "Build the CODEC executables")
SET(BUILD_THIRDPARTY OFF CACHE BOOL "Build the thirdparty executables if it is needed")
SET(PNG_PNG_INCLUDE_DIR "${PNG_DIR}")	
SET(PNG_LIBRARY "${CMAKE_BINARY_DIR}/staging/libs/${LIB_PREFIX}${PNG_LIB_NAME}${LIB_EXT}")	
SET(TIFF_INCLUDE_DIR "${TIFF_DIR}")	
SET(TIFF_LIBRARY "${CMAKE_BINARY_DIR}/staging/libs/${LIB_PREFIX}${TIFF_LIB_NAME}${LIB_EXT}")	

# Include openjpeg project
ADD_SUBDIRECTORY("${OPENJPEG_DIR}" "${PROJECT_BINARY_DIR}/openjpeg-build")

# Modify target to make sure libs are copied to the correct place
SET_TARGET_PROPERTIES(
	${OPENJPEG_LIB_NAME} PROPERTIES
	PREFIX ""
	ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_MINSIZEREL "${CMAKE_BINARY_DIR}/staging/libs"
	RUNTIME_OUTPUT_DIRECTORY_DEBUG "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_RELEASE "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL "${QTBUILD_DIR}/bin"
)

# Don't build executables
SET_TARGET_PROPERTIES(
	addtiffo ascii_tag custom_dir defer_strile_loading defer_strile_writing fax2ps fax2tiff
	iptcutil long_tag md5cmp mkg3states pal2rgb ppm2tiff raw_decode raw2tiff rewrite rgb2ycbcr
	short_tag strip_rw testtypes thumbnail tiff2bw tiff2pdf tiff2ps tiff2rgba tiff-bi tiffcmp
	tiffcp tiffcrop tiffdither tiffdump tiff-grayscale tiffinfo tiffmedian tiff-palette tiff-rgb
	tiffset tiffsplit PROPERTIES
	EXCLUDE_FROM_ALL 1
	EXCLUDE_FROM_DEFAULT_BUILD 1	# for VS generators
)

ADD_DEPENDENCIES(
	${OPENJPEG_LIB_NAME} ${ZLIB_LIB_NAME} ${PNG_LIB_NAME} ${TIFF_LIB_NAME}
)


#================================= FREETYPE =================================#


# Options and dependency locations
SET(FREETYPE_NO_DIST 1)
SET(PNG_INCLUDE_DIRS "${PNG_DIR}")	
SET(PNG_LIBRARIES "${CMAKE_BINARY_DIR}/staging/libs/${LIB_PREFIX}${PNG_LIB_NAME}${LIB_EXT}")	

# Include freetype project
ADD_SUBDIRECTORY("${FREETYPE_DIR}" "${PROJECT_BINARY_DIR}/freetype-build")

# the find png package does not find all includes
target_include_directories(
	${FREETYPE_LIB_NAME} PUBLIC AFTER
	PUBLIC "${CMAKE_BINARY_DIR}/png-build"
	PUBLIC "${CMAKE_BINARY_DIR}/zlib-build"
)

# Modify target to make sure libs are copied to the correct place
SET_TARGET_PROPERTIES(
	${FREETYPE_LIB_NAME} PROPERTIES
	PREFIX ""
	ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_MINSIZEREL "${CMAKE_BINARY_DIR}/staging/libs"
	RUNTIME_OUTPUT_DIRECTORY_DEBUG "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_RELEASE "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL "${QTBUILD_DIR}/bin"
)

ADD_DEPENDENCIES(
	${FREETYPE_LIB_NAME} ${ZLIB_LIB_NAME} ${PNG_LIB_NAME}
)


#================================== PODOFO ==================================#


# Options and dependency locations
SET(PODOFO_BUILD_LIB_ONLY 1)
SET(PODOFO_BUILD_SHARED 1)
SET(ZLIB_INCLUDE_DIR "${ZLIB_DIR}")	
SET(ZLIB_LIBRARY_RELEASE "${CMAKE_BINARY_DIR}/staging/libs/${LIB_PREFIX}${ZLIB_FILE_NAME}${LIB_EXT}")
SET(LIBJPEG_INCLUDE_DIR ${JPEG_DIR})	
SET(LIBJPEG_LIBRARY_RELEASE "${CMAKE_BINARY_DIR}/staging/libs/${LIB_PREFIX}${JPEG_LIB_NAME}${LIB_EXT}")	
SET(PNG_PNG_INCLUDE_DIR ${PNG_DIR})	
SET(PNG_LIBRARY_RELEASE "${CMAKE_BINARY_DIR}/staging/libs/${LIB_PREFIX}${PNG_LIB_NAME}${LIB_EXT}")	
SET(TIFF_INCLUDE_DIR "${TIFF_DIR}/libtiff")	
SET(TIFF_LIBRARY_RELEASE "${CMAKE_BINARY_DIR}/staging/libs/${LIB_PREFIX}${TIFF_LIB_NAME}${LIB_EXT}")	
SET(FREETYPE_INCLUDE_DIR_FT2BUILD "${FREETYPE_DIR}/include")
SET(FREETYPE_INCLUDE_DIR_FTHEADER "${FREETYPE_DIR}/include/freetype")	
SET(FREETYPE_LIBRARY_RELEASE "${CMAKE_BINARY_DIR}/staging/libs/${LIB_PREFIX}${FREETYPE_LIB_NAME}${LIB_EXT}")	

# Include podofo project
ADD_SUBDIRECTORY(${PODOFO_DIR} "${PROJECT_BINARY_DIR}/podofo-build")

# Some headers of dependencies need to be included manually
target_include_directories(
	podofo_shared PUBLIC AFTER
	PUBLIC "${CMAKE_BINARY_DIR}/jpeg-build"
	PUBLIC "${CMAKE_BINARY_DIR}/tiff-build/libtiff"
	PUBLIC "${CMAKE_BINARY_DIR}/png-build"
	PUBLIC "${CMAKE_BINARY_DIR}/zlib-build"
)

# Modify target to make sure libs are copied to the correct place
SET_TARGET_PROPERTIES(
	podofo_shared PROPERTIES
	PREFIX ""
	ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_BINARY_DIR}/staging/libs"
	ARCHIVE_OUTPUT_DIRECTORY_MINSIZEREL "${CMAKE_BINARY_DIR}/staging/libs"
	RUNTIME_OUTPUT_DIRECTORY_DEBUG "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_RELEASE "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${QTBUILD_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL "${QTBUILD_DIR}/bin"
)

ADD_DEPENDENCIES(
	podofo_shared ${ZLIB_LIB_NAME} ${PNG_LIB_NAME} ${TIFF_LIB_NAME}
	${JPEG_LIB_NAME} ${FREETYPE_LIB_NAME}
)


#================================= Boost ================================#


# Boost 1.77 does not pass the toolset from the bootstrap to the b2 build
# makefile. So it uses msvc by default. Build fails if you use mingw in a
# non-standard location (e.g. not in c:\Mingw).
# Fix: line 15 in bootstrap.bat: call .\build.bat %1
SET(boost_64bit_flags "")
IF(CMAKE_SIZEOF_VOID_P EQUAL 8)
	LIST(APPEND boost_64bit_flags "address-model=64")
ENDIF()

SET(BOOST_BUILD_DIR "${CMAKE_BINARY_DIR}/boost-build")

ADD_CUSTOM_TARGET(
	boost ALL
	COMMAND cmd /c bootstrap ${boost_toolset}
	COMMAND b2 --with-test toolset=${boost_toolset}
	threading=multi link=static variant=debug,release ${boost_64bit_flags}
	--stagedir=${BOOST_BUILD_DIR} --build-dir=${BOOST_BUILD_DIR}
	WORKING_DIRECTORY "${BOOST_DIR}"
	VERBATIM
)


#=================================== Qt ===================================#


# Backward compatibility.  We used to patch projects.pro, but now we achieve
# the same result by other means.
IF(EXISTS "${QTBASE_DIR}/projects.pro.orig")
	CONFIGURE_FILE(
		"${QTBASE_DIR}/projects.pro.orig"
		"${QTBASE_DIR}/projects.pro" COPYONLY
	)
	FILE(REMOVE "${QTBASE_DIR}/projects.pro.orig")
ENDIF(EXISTS "${QTBASE_DIR}/projects.pro.orig")


TO_NATIVE_PATH("${JPEG_DIR}" JPEG_INCLUDE_DIR)
TO_NATIVE_PATH("${ZLIB_DIR}" ZLIB_INCLUDE_DIR)
TO_NATIVE_PATH("${PNG_DIR}" PNG_INCLUDE_DIR)
TO_NATIVE_PATH("${FREETYPE_DIR}/include" FREETYPE_INCLUDE_DIR)
TO_NATIVE_PATH("${QTBASE_DIR}" QTBASE_DIR_NATIVE)


# Find all *.conf files under mkspecs that mention -Zc:wchar_t- and remove
# that minus at the end.  That's necessary to make Qt compatible with other
# libraries that use wchar_t stuff.
# FILE(GLOB_RECURSE conf_files "${QTBASE_DIR}/mkspecs/*.conf")
# FOREACH(conf_file ${conf_files})
	# FILE(READ "${conf_file}" contents)
	# STRING(REGEX REPLACE "-Zc:wchar_t-" "-Zc:wchar_t" new_contents "${contents}")
	# IF(NOT "${contents}" STREQUAL "${new_contents}")
		# # Make a backup copy, if not already there.
		# IF(NOT EXISTS "${conf_file}.orig")
			# CONFIGURE_FILE("${conf_file}" "${conf_file}.orig" COPYONLY)
		# ENDIF()

		# FILE(WRITE "${conf_file}" "${new_contents}")
	# ENDIF()
# ENDFOREACH()


IF(MSVC)
	# Disable frame pointer omission in release mode to ensure
	# good stack traces from our built-in crash reporter.
	PATCH_FILE(
		"${QTBASE_DIR}/mkspecs/win32-msvc/qmake.conf"
		
		# Add the flag.
		"/(QMAKE_CFLAGS_RELEASE[ \t]*=)/\\1 -Oy-/"
		
		# Get rid of duplicates, in case it was already there.
		"/( -Oy-)+/ -Oy-/"
	)
ENDIF()
	

SET(qt_build_script "${CMAKE_BINARY_DIR}/build-qt.bat")

SET(maybe_skip_building_tools "")
IF(QT_PREBUILT_DIR)
	SET(maybe_skip_building_tools "goto exit")
ENDIF()

ADD_CUSTOM_COMMAND(
	OUTPUT "${qt_build_script}"
	COMMAND "${CMAKE_COMMAND}"
	"-DPROJECT_ROOT=${CMAKE_SOURCE_DIR}/../../.."
	"-DTARGET_FILE=${qt_build_script}"
	"-DPLATFORM=${qt_platform}"
	"-DMAYBE_SKIP_BUILDING_TOOLS=${maybe_skip_building_tools}"
	"-DMAKE_COMMAND=${MAKE_COMMAND}"
	"-DQTBUILD_DIR=${QTBUILD_DIR}"
	"-DQTBASE_DIR=${QTBASE_DIR}"
	"-DJPEG_INCLUDE_DIR=${JPEG_INCLUDE_DIR}"
	"-DZLIB_INCLUDE_DIR=${ZLIB_INCLUDE_DIR}"
	"-DPNG_INCLUDE_DIR=${PNG_INCLUDE_DIR}"
	"-DFREETYPE_INCLUDE_DIR=${FREETYPE_INCLUDE_DIR}"
	"-DJPEG_LINK_DIR=$<TARGET_LINKER_FILE_DIR:${JPEG_LIB_NAME}>"
	"-DZLIB_LINK_DIR=$<TARGET_LINKER_FILE_DIR:${ZLIB_LIB_NAME}>"
	"-DPNG_LINK_DIR=$<TARGET_LINKER_FILE_DIR:${PNG_LIB_NAME}>"
	"-DFREETYPE_LINK_DIR=$<TARGET_LINKER_FILE_DIR:${FREETYPE_LIB_NAME}>"
	-P "${CMAKE_CURRENT_SOURCE_DIR}/generate_qt_build_script.cmake"
	DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/generate_qt_build_script.cmake"
	VERBATIM
)
	
ADD_CUSTOM_TARGET(
	Qt ALL
	COMMAND "${qt_build_script}"
	DEPENDS "${qt_build_script}"
	WORKING_DIRECTORY "${QTBUILD_DIR}"
)

# Boost added so that boost is built before Qt. That's helpful if build
# errors occur, as rebuilding boost is much faster than rebuilding Qt.
ADD_DEPENDENCIES(
	Qt boost ${ZLIB_LIB_NAME} ${JPEG_LIB_NAME}
	${PNG_LIB_NAME} ${TIFF_LIB_NAME} ${OPENJPEG_LIB_NAME}
	${FREETYPE_LIB_NAME}
)

# If you have multiple versions of Qt installed, this script
# can easily pick the wrong one.
MESSAGE(STATUS "----------------------------")
MESSAGE(STATUS "QT_SRC_DIR is ${QT_SRC_DIR}")
IF(QT_PREBUILT_DIR)
	MESSAGE(STATUS "QT_PREBUILT_DIR is ${QT_PREBUILT_DIR}")
ELSE()
	MESSAGE(STATUS "QT_PREBUILT_DIR is not set. Using a source-only version of Qt? Fine, though \
building will take longer.")
ENDIF()
MESSAGE(STATUS "If you've got multiple versions of Qt installed, check we've got the right one.")
IF(suggest_jom)
	MESSAGE(STATUS "Note that building Qt with NMAKE is slow. Consider using JOM instead. \
Drop jom.exe to the folder with other dependencies and/or set JOM_EXECUTABLE to point to it.")
ENDIF()
MESSAGE(STATUS "----------------------------")


# Dump symbols of all DLLs we are going to link to.
OPTION(DUMP_DLL_SYMBOLS "Enable if you are going to build crash reporter." OFF)
IF(DUMP_DLL_SYMBOLS)
	FIND_PATH(
		SYMBOLS_PATH . PATHS "${build_outer_dir}/symbols"
		"${source_outer_dir}/symbols" NO_DEFAULT_PATH
		DOC "The directory to write symbol information into."
	)
	IF(NOT SYMBOLS_PATH)
		MESSAGE(FATAL_ERROR "SYMBOLS_PATH directory is not set.")
	ENDIF(NOT SYMBOLS_PATH)

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
	ENDIF(NOT DUMP_SYMS_EXECUTABLE)
	
	ADD_CUSTOM_TARGET(
		dump_dll_symbols ALL
		COMMAND "${CMAKE_COMMAND}" "-DSYMBOLS_PATH=${SYMBOLS_PATH}"
		"-DDUMP_SYMS_EXECUTABLE=${DUMP_SYMS_EXECUTABLE}"
		"-DMOVE_SYMBOLS_SCRIPT=${CMAKE_CURRENT_SOURCE_DIR}/../../../cmake/move_sym_file.cmake"
		-P "${CMAKE_CURRENT_SOURCE_DIR}/dump_dll_syms.cmake"
		DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/dump_dll_syms.cmake"
		WORKING_DIRECTORY "${QTBASE_DIR}/bin"
		VERBATIM
	)
	
	# Qt depends on the rest of them.
	ADD_DEPENDENCIES(dump_dll_symbols Qt)
ENDIF()

#==========================================================================#

# Export some variables for main project
CONFIGURE_FILE(export-vars.cmake.in "${CMAKE_BINARY_DIR}/export-vars.cmake" @ONLY)
