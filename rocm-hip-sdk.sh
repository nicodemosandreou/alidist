package: rocm-hip-sdk
version: "5.5.0"
source: https://github.com/RadeonOpenCompute/ROCm.git
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - alibuild-recipe-tools
  - rocblas
  - hipcub
prepend_path:
  PKG_CONFIG_PATH: "$ROCM_HIP_SDK_ROOT/lib/pkgconfig"
---
#!/bin/bash -e

# Define the ROCm version
ROCM_VERSION=5.5.0

# Install the required ROCm components
install_rocm_component() {
  local component=$1
  local version=$2
  git clone -b rocm-${version} https://github.com/RadeonOpenCompute/${component}.git $SOURCEDIR/${component}
  cd $SOURCEDIR/${component}
  mkdir -p build && cd build
  cmake .. -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" -DCMAKE_BUILD_TYPE=Release
  make ${JOBS:+-j $JOBS}
  make install
}

# Install ROCm components
install_rocm_component "rocBLAS" $ROCM_VERSION
install_rocm_component "hipCUB" $ROCM_VERSION
install_rocm_component "rocPRIM" $ROCM_VERSION
install_rocm_component "rocSOLVER" $ROCM_VERSION
install_rocm_component "rocRAND" $ROCM_VERSION

# Create the modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PKGNAME"
alibuild-generate-module --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Our environment
set ROCM_HIP_SDK_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path ROOT_INCLUDE_PATH \$ROCM_HIP_SDK_ROOT/include
prepend-path LIBRARY_PATH \$ROCM_HIP_SDK_ROOT/lib
prepend-path LD_LIBRARY_PATH \$ROCM_HIP_SDK_ROOT/lib
EoF
