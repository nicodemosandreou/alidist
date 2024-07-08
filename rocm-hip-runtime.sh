package: rocm-hip-runtime
version: "5.5.0"
source: https://github.com/RadeonOpenCompute/ROCm-Device-Libs
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - alibuild-recipe-tools
prepend_path:
  PKG_CONFIG_PATH: "$ROCM_HIP_RUNTIME_ROOT/lib/pkgconfig"
---
#!/bin/bash -e

# Download ROCm
curl -LO https://github.com/RadeonOpenCompute/ROCm-Device-Libs/archive/rocm-${version}.tar.gz
tar -xzf rocm-${version}.tar.gz
cd ROCm-Device-Libs-rocm-${version}

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
set ROCM_HIP_RUNTIME_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path ROOT_INCLUDE_PATH \$ROCM_HIP_RUNTIME_ROOT/include
prepend-path LIBRARY_PATH \$ROCM_HIP_RUNTIME_ROOT/lib
prepend-path LD_LIBRARY_PATH \$ROCM_HIP_RUNTIME_ROOT/lib
EoF
