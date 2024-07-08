package: hipcub
version: "5.5.0"
source: https://github.com/ROCmSoftwarePlatform/hipCUB
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - alibuild-recipe-tools
  - rocblas
prepend_path:
  PKG_CONFIG_PATH: "$HIPCUB_ROOT/lib/pkgconfig"
---
#!/bin/bash -e

# Clone hipCUB
git clone -b rocm-${version} https://github.com/ROCmSoftwarePlatform/hipCUB.git $SOURCEDIR
cd $SOURCEDIR

# Create build directory
mkdir -p build && cd build

# Configure the build
cmake .. \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
    -DCMAKE_BUILD_TYPE=Release

# Build and install
make ${JOBS:+-j $JOBS}
make install

# Create modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PKGNAME"
alibuild-generate-module --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Our environment
set HIPCUB_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path ROOT_INCLUDE_PATH \$HIPCUB_ROOT/include
prepend-path LIBRARY_PATH \$HIPCUB_ROOT/lib
prepend-path LD_LIBRARY_PATH \$HIPCUB_ROOT/lib
EoF
