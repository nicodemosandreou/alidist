package: JAX
version: "%(tag_basename)s"
tag: v0.4.30
source: https://github.com/google/jax
requires:
  - protobuf
  - re2
  - boost
  - python-absl
  - python-flatbuffers
  - python-ml-dtypes
  - python-numpy
  - python-scipy
  - miopen
  - rccl
  - rocm-hip-runtime
build_requires:
  - python-build
  - python-installer
  - python-setuptools
  - python-wheel
  - bazel
  - miopen
  - rccl
  - rocm-hip-sdk
  - alibuild-recipe-tools
  - "Python:(slc|ubuntu)"
  - "Python-system:(?!slc.*|ubuntu)"
---
#!/bin/bash -e

# Ensure installation directory exists
mkdir -p $INSTALLROOT

# Load necessary modules or set environment variables
module load python/3.8  # Ensure you have the right Python version

# Download source code
wget -O jaxlib.tar.gz https://github.com/google/jax/archive/refs/tags/jaxlib-v0.4.30.tar.gz
wget -O xla-rocm.tar.gz https://github.com/ROCmSoftwarePlatform/xla/archive/refs/heads/rocm-jaxlib-v0.4.30.tar.gz

# Extract source code
tar -xzf jaxlib.tar.gz
tar -xzf xla-rocm.tar.gz

# Prepare build environment
cd jax-jaxlib-v0.4.30
echo "6.*.*" > .bazelversion
export JAXLIB_RELEASE=0.4.30
export ROCM_HOME=${ROCM_HOME:-/opt/rocm-5.5.0}
export TF_ROCM_AMDGPU_TARGETS="gfx906"

# Build JAX with ROCm support
python build/build.py --enable_rocm \
  "--rocm_amdgpu_targets=${TF_ROCM_AMDGPU_TARGETS}" \
  --bazel_options=--override_repository=xla=${PWD}/../xla-rocm-jaxlib-v0.4.30

# Install JAX
python -m installer --compile-bytecode 1 --destdir $INSTALLROOT $(find . -name "jaxlib-0.4.30-*.whl")

# Create the modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PKGNAME"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global dotversion
  puts stderr "JAX $version with ROCm 5.5 support"
}
module-whatis "JAX $version with ROCm 5.5 support"

# Our environment
setenv JAX_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PYTHONPATH \$JAX_ROOT/lib/python3.8/site-packages
EoF
