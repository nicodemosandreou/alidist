package: JAX
version: "%(tag_basename)s"
tag: main
source: https://github.com/google/jax
requires:
  - protobuf
  - re2
  - boost
  - numpy
  - scipy
build_requires:
  - CMake
  - alibuild-recipe-tools
  - "Python:(slc|ubuntu)"  # JAX requires Python
  - "Python-system:(?!slc.*|ubuntu)"
  - bazel
  - python-build
  - python-installer
  - python-setuptools
  - python-wheel
  - miopen
  - rccl
  - rocm-hip-sdk
prepend_path:
  ROOT_INCLUDE_PATH: "$JAX_ROOT/include/jax"
---
#!/bin/bash -e

# Set up installation root
mkdir -p $INSTALLROOT

# Set up environment variables for ROCm
export ROCM_PATH=/opt/rocm-5.5
export ROCM_HOME=$ROCM_PATH
export PATH=$ROCM_HOME/bin:$ROCM_HOME/llvm/bin:$PATH
export LD_LIBRARY_PATH=$ROCM_HOME/lib:$ROCM_HOME/lib64:$LD_LIBRARY_PATH
export HIP_PLATFORM=hcc
export HCC_AMDGPU_TARGET=gfx906  # Target the specific AMD GPU architecture
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1

# Ensure Python virtual environment is activated (optional, if you use virtual environments)
# source path_to_your_virtualenv/bin/activate

# Download and extract sources
_srcname="jax-jaxlib-v${pkgver}"
_xlaname="xla-rocm-jaxlib-v${pkgver}"
source=(
  "${_srcname}.tar.gz::https://github.com/google/jax/archive/refs/tags/jaxlib-v${pkgver}.tar.gz"
  "${_xlaname}.tar.gz::https://github.com/ROCmSoftwarePlatform/xla/archive/refs/heads/rocm-jaxlib-v${pkgver}.tar.gz"
)
sha256sums=(
  '0ef9635c734d9bbb44fcc87df4f1c3ccce1cfcfd243572c80d36fcdf826fe1e6'
  'fd0f4d49247cca05cfef5bd37180b6f84aadef6a098abed83b1572496515513b'
)

prepare() {
  cd "${srcdir}/${_srcname}"
  echo "6.*.*" > .bazelversion
  export JAXLIB_RELEASE=$pkgver
  if [ -z "$ROCM_HOME" ]; then
    export ROCM_HOME=/opt/rocm
  fi
}

build() {
  cd "${srcdir}/${_srcname}"
  if [ -z "$TF_ROCM_AMDGPU_TARGETS" ]; then
    export TF_ROCM_AMDGPU_TARGETS="gfx803,gfx900,gfx906,gfx908,gfx90a,gfx1030,gfx1100,gfx1101,gfx1102"
  fi

  python build/build.py --enable_rocm \
    "--rocm_amdgpu_targets=${TF_ROCM_AMDGPU_TARGETS}" \
    --bazel_options=--override_repository=xla=${srcdir}/${_xlaname}
}

package() {
  cd "${srcdir}/${_srcname}"
  python -m installer \
    --compile-bytecode 1 \
    --destdir $pkgdir \
    $srcdir/$_srcname/dist/jaxlib-$pkgver-*.whl
}

# Build and install JAX
pip install --upgrade pip
pip install jax jaxlib -f https://storage.googleapis.com/jax-releases/jax_releases.html

# Verify JAX installation
python -c "import jax; print(jax.numpy.ones(3))"

# Create Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PKGNAME"
alibuild-generate-module --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Our environment
set JAX_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PYTHONPATH \$JAX_ROOT/lib/python3.8/site-packages
prepend-path LD_LIBRARY_PATH \$ROCM_HOME/lib:\$ROCM_HOME/lib64
EoF
