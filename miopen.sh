package: miopen
version: "2.14.0"
source: https://github.com/ROCmSoftwarePlatform/MIOpen
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - "Python:(?!osx)"
  - alibuild-recipe-tools
  - rocblas
  - boost
prepend_path:
  PKG_CONFIG_PATH: "$MIOPEN_ROOT/lib/pkgconfig"
---
#!/bin/bash -e

# Clone MIOpen
git clone -b rocm-${version} https://github.com/ROCmSoftwarePlatform/MIOpen.git $SOURCEDIR
cd $SOURCEDIR

# Create build directory
mkdir -p build && cd build

# Configure the build
cmake .. \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_DEV=ON \
    -DMIOPEN_BACKEND=HIP

# Build and install
make ${JOBS:+-j $JOBS}
make install

# Create the modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PKGNAME"
alibuild-generate-module --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Our environment
set MIOPEN_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path ROOT_INCLUDE_PATH \$MIOPEN_ROOT/include
prepend-path LIBRARY_PATH \$MIOPEN_ROOT/lib
prepend-path LD_LIBRARY_PATH \$MIOPEN_ROOT/lib
EoF
