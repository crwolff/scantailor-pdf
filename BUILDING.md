# Building Scan Tailor PDF

## Prerequisits

- [CMake](http://www.cmake.org) v3.15 or later
- [NASM](http://www.nasm.us) 2.14 or later for libjpeg-turbo optimizations
- A c++ compiler and build environment. Supported are VS14 and up, MinGW and g++


## Building

It is encouraged to do an out of source tree build, e.g. create an empty directory somewhere (e.g. `{build}`) and run cmake from there. On Windows, all external dependencies are downloaded and built locally into the `{build}/extern` directory. If you clean up your build directory and wish to build Scan Tailor PDF again, you can keep the source archives of the external dependencies in the `{build}/extern/src` so you don't have to download them again.
The following procedures assume that cmake is invoked from the command line. But it's possible to adapt the commands to the GUI version of cmake.

### Cmake options {#cmake-options}

- `STATIC_BUILD` [OFF]: Creates a static build of Scan Tailor PDF. Only Windows in combination with MinGW is currently supported.
- `BUILD_QT_TOOLS` [OFF]: Build all QT Tools (Assistant, Designer, windeployqt etc.) and not just Linguist, which is required to compile the translations for Scan Tailor PDF.
- `BUILD_INSTALLER` [OFF]: Only works under Windows. Option to build the installer.

### Windows

#### MinGW

From your build directory, invoke

	cmake {source_directory}

where `{source_directory}` is the root folder of the Scan Tailor PDF sources. If cmake does not pick up your MinGW development environment, add `-G "MinGW Makefiles"` to the command line. You may also include any cmake options from [above](#cmake-options), for example `-DSTATIC_BUILD=ON`.


#### Visual Studio



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


