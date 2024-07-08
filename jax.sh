package: JAX
version: "0.4.30"
source: https://github.com/google/jax
requires:
  - protobuf
  - re2
  - boost
  - miopen
  - rccl
  - rocm-hip-runtime
build_requires:
  - CMake
  - alibuild-recipe-tools
  - "Python:(slc|ubuntu)"
  - "Python-system:(?!slc.*|ubuntu)"
  - python-build
  - python-installer
  - python-setuptools
  - python-wheel
  - bazel
  - miopen
  - rccl
  - rocm-hip-sdk
prepend_path:
  ROOT_INCLUDE_PATH: "$JAX_ROOT/include/jax"
---
#!/bin/bash -e

# Load ROCm environment
source /opt/rocm-5.5.0/bin/rocminfo
source /opt/rocm-5.5.0/bin/rocprof

# Clone the JAX repository
git clone --recursive https://github.com/google/jax $SOURCEDIR
cd $SOURCEDIR

# Set up the Python environment for JAX
pip install -r requirements.txt
pip install -r requirements-test.txt
pip install numpy scipy absl-py

# Set the JAX version
export JAXLIB_RELEASE=$pkgver

# Export ROCm Home if not set
if [ -z "$ROCM_HOME" ]; then
  export ROCM_HOME=/opt/rocm
fi

# Set the AMD GPU targets
export TF_ROCM_AMDGPU_TARGETS="gfx803,gfx900,gfx906,gfx908,gfx90a,gfx1030,gfx1100,gfx1101,gfx1102"

# Build JAX
python build/build.py --enable_rocm \
  "--rocm_amdgpu_targets=${TF_ROCM_AMDGPU_TARGETS}" \
  --bazel_options=--override_repository=xla=${SOURCEDIR}/xla

# Install JAX
python -m pip install .

# Copy installation to $INSTALLROOT
mkdir -p $INSTALLROOT/lib
cp -r jaxlib $INSTALLROOT/lib

# Create the modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PKGNAME"
alibuild-generate-module --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Our environment
set ${PKGNAME}_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path ROOT_INCLUDE_PATH \$${PKGNAME}_ROOT/include/jax
prepend-path PYTHONPATH \$${PKGNAME}_ROOT/lib
EoF
