# Building Scan Tailor PDF

## Prerequisits {#prereqs}

- [CMake](http://www.cmake.org) v3.15 or later
- [NASM](http://www.nasm.us) 2.14 or later for libjpeg-turbo optimizations
- Tested build environments:
	- MinGW (also under MSYS2)
- Tested compilers:
	- gcc
	- llvm/clang
	- vs14 – vs19


## Building

It is encouraged to do an out of source tree build, e.g. create an empty directory somewhere (e.g. `{build}`) and run cmake from there. On Windows, all external dependencies are downloaded and built locally into the `{build}/extern` directory. If you clean up your build directory and wish to build Scan Tailor PDF again, you can keep the source archives of the external dependencies in the `{build}/extern/src` so cmake won't have to download them again.
The following procedures assume that cmake is invoked from the command line. But it's possible to adapt the commands to the GUI version of cmake.

### Cmake options {#cmake-options}

The following options can be turned on the command line with `-D[OPTION]=ON` or defined and set in the cmake gui. Defaults are given in square brackets.

- `BUILD_SHARED_LIBS` [ON]: If turned off, creates a static build of Scan Tailor PDF. Only Windows in combination with MinGW is currently supported.
- `BUILD_QT_TOOLS` [OFF]: Build all QT Tools (Assistant, Designer, windeployqt etc.) and not just Linguist, which is required to compile the translations for Scan Tailor PDF.
- `BUILD_INSTALLER` [OFF]: Option to build the installer. Only works under Windows.



- `CMAKE_BUILD_TYPE` [Release]: 

### Windows

#### Visual Studio


#### MinGW

It is recommended to use [MSYS2](https://www.msys2.org/) to build with MinGW under Windows. Other MinGW distributions may also work, but may be finicky, especially when building QT5. Make sure to have the prerequisite tools installed (see [above](#prereqs)). It's also recommended to use [ninja](https://ninja-build.org/) as your build tool (it is the default in MSYS2).

From your build directory, invoke

	cmake {source_directory}

where `{source_directory}` is the root folder of the Scan Tailor PDF sources. If cmake does not pick up your MinGW development environment, add `-G "MinGW Makefiles"` to the command line. You may also include any cmake options from [above](#cmake-options), for example `-DSTATIC_BUILD=ON`.

Then

	ninja

This will build all dependencies first and will take quite some time, but will only need to be done once. Output may seem to stop when building QT5 because ninja only prints the output of a sub-process when it terminates. It an error occurs, ninja will complain and print the error.
When the build is finished run cmake again

	cmake {source_directory}
	
You may omit any options from the first run as they are cached. Then rerun ninja:

	ninja

This last run is much faster and will output the executable and (hopefully) all needed dependencies in the `{source_directory}\{config}` directory, where `{config}` defaults to 'Release' but may also be 'Debug', 'RelWithDebInfo', or 'MinSizeRel' depending on whether `CMAKE_BUILD_TYPE` was specified with one of these options.



### Un*x

Currently, only a shared build is supported.

The following libraries have to be installed before building is possible (Debian):

- zlib1g-dev
- libpng-dev
- libfreetype-dev
- libjpeg62-turbo-dev (or standard jpeg dev library)
- liblzma-dev
- libtiff-dev
- libzstd-dev
- libopenjp2-7-dev
- libpodofo-dev
- libboost-test1.74-dev (or newer)
- qtbase5-dev
- qttools5-dev


