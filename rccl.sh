package: rccl
version: "2.14.0"
source: https://github.com/ROCmSoftwarePlatform/rccl
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - alibuild-recipe-tools
prepend_path:
  PKG_CONFIG_PATH: "$RCCL_ROOT/lib/pkgconfig"
---
#!/bin/bash -e

# Clone RCCL
git clone -b rocm-${version} https://github.com/ROCmSoftwarePlatform/rccl.git $SOURCEDIR
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

# Create the modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PKGNAME"
alibuild-generate-module --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Our environment
set RCCL_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path ROOT_INCLUDE_PATH \$RCCL_ROOT/include
prepend-path LIBRARY_PATH \$RCCL_ROOT/lib
prepend-path LD_LIBRARY_PATH \$RCCL_ROOT/lib
EoF
