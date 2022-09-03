# Build instructions for Ubuntu 20.04
  
Download cmake from the cmake.org 'Older Releases' section:
```
wget https://cmake.org/files/v3.20/cmake-3.20.6.tar.gz
```
Unpack build and install:
```
tar xvf cmake-3.20.6.tar.gz
cd cmake-3.20.6
mkdir build
cd build
../bootstrap && make
sudo make install
```
Get dependencies:
``` 
sudo apt install zlib1g-dev libpng-dev libfreetype-dev libjpeg-dev liblzma-dev libtiff-dev libzstd-dev libopenjp2-7-dev libpodofo-dev libboost-test1.71-dev qtbase5-dev qttools5-dev
```
Clone repository and switch to proper branch:
```
git clone https://github.com/crwolff/scantailor-pdf.git
cd scantailor-pdf
git checkout ubuntu20.04
```
Create build directory, start the build, then go get a cup of tea:
``` 
mkdir build
cd build
cmake ..
make
```
When done, the executable should be in build/Release
