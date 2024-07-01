#!/bin/bash -e

# Package metadata
PACKAGE_NAME="PyTorch"
PACKAGE_VERSION="2.2.1"
INSTALLROOT=${INSTALLROOT:-/opt/pytorch}

# Set the installation directory
mkdir -p $INSTALLROOT

# Detect architecture and hardware to set the download URL
case $(uname -s) in
  Darwin)
    if [[ $(uname -m) == "x86_64" ]]; then
      echo "Installing PyTorch for MacOS (CPU version)"
      URL=https://download.pytorch.org/libtorch/cpu/libtorch-macos-x86_64-$PACKAGE_VERSION.zip
    else
      echo "Installing PyTorch for MacOS (Metal backend)"
      URL=https://download.pytorch.org/libtorch/cpu/libtorch-macos-arm64-$PACKAGE_VERSION.zip
    fi
  ;;
  Linux)
    if command -v rocminfo >/dev/null 2>&1; then
      echo "Installing PyTorch for ROCm"
      URL=https://download.pytorch.org/libtorch/rocm6.0/libtorch-cxx11-abi-shared-with-deps-$PACKAGE_VERSION%2Brocm6.0.zip
    elif command -v nvcc >/dev/null 2>&1; then
      CUDA_VERSION=$(nvcc --version | grep "release" | awk '{print $NF}' | cut -d. -f1)
      if [[ "$CUDA_VERSION" == "V11" ]]; then
        echo "Installing PyTorch for CUDA 11.x"
        URL=https://download.pytorch.org/libtorch/cu118/libtorch-cxx11-abi-shared-with-deps-$PACKAGE_VERSION%2Bcu118.zip
      elif [[ "$CUDA_VERSION" == "V12" ]]; then
        echo "Installing PyTorch for CUDA 12.x"
        URL=https://download.pytorch.org/libtorch/cu121/libtorch-cxx11-abi-shared-with-deps-$PACKAGE_VERSION%2Bcu121.zip
      else
        echo "CUDA version is not 11.x or 12.x, installing PyTorch basic CPU version"
        URL=https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-$PACKAGE_VERSION%2Bcpu.zip
      fi
    else
      echo "Installing PyTorch basic CPU version"
      URL=https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-$PACKAGE_VERSION%2Bcpu.zip
    fi
  ;;
  *)
    echo "Unsupported OS"
    exit 1
  ;;
esac

# Download and extract PyTorch
curl -fSsLo pytorch.zip $URL
unzip -o pytorch.zip -d "$INSTALLROOT"
mv "$INSTALLROOT/libtorch"/* "$INSTALLROOT/"
rmdir "$INSTALLROOT/libtorch"

# Generate modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PACKAGE_NAME"
alibuild-generate-module --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Set environment variables for PyTorch
setenv PYTORCH_ROOT \$::env(BASEDIR)/$PACKAGE_NAME/\$version
prepend-path CMAKE_PREFIX_PATH \$PYTORCH_ROOT/share/cmake
prepend-path LD_LIBRARY_PATH \$PYTORCH_ROOT/lib
EoF

echo "PyTorch installation complete. Modulefile created at $MODULEFILE."
