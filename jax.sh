package: JAX
version: "%(tag_basename)s"
tag: v0.4.30
source: https://github.com/google/jax
requires:
- alibuild-recipe-tools


# Ensure installation directory exists
mkdir -p $INSTALLROOT

# Load necessary modules or set environment variables
module load python/3.8  # Ensure you have the right Python version

# Install Python dependencies
pip install protobuf re2 boost absl-py flatbuffers ml-dtypes numpy scipy

# System dependencies installation for AlmaLinux/RHEL/CentOS
sudo dnf install -y miopen-hip rccl rocm-hip-runtime

# Bazel installation (check for the latest version on the official website)
BAZEL_VERSION="4.0.0"
wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh
chmod +x bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh
./bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh --user

# Add Bazel to PATH
export PATH="$PATH:$HOME/bin"

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