#!/bin/bash -e

# Package information
package: JAX
version: "0.4.30"  # Adjust this to the desired JAX version
source: https://github.com/google/jax
requires:
  - Python
build_requires:
  - CMake
  - alibuild-recipe-tools
  - "Python:(slc|ubuntu)"
  - "Python-system:(?!slc.*|ubuntu)"
prepend_path:
  PYTHONPATH: "$JAX_ROOT/lib/python3.8/site-packages"  # Adjust Python version as needed

---
#!/bin/bash -e

mkdir -p $INSTALLROOT

# Set up environment variables for ROCm
export ROCM_PATH=/opt/rocm
export ROCM_HOME=$ROCM_PATH
export PATH=$ROCM_HOME/bin:$PATH
export PATH=$ROCM_HOME/llvm/bin:$PATH
export LD_LIBRARY_PATH=$ROCM_HOME/lib:$ROCM_HOME/lib64:$LD_LIBRARY_PATH
export HIP_PLATFORM=amd
export HCC_AMDGPU_TARGET=gfx906
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1

# Save current LD_LIBRARY_PATH
OLD_LD_LIBRARY_PATH=$LD_LIBRARY_PATH

# Temporarily remove ROCm's libstdc++.so.6 from LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v "$ROCM_HOME/lib" | tr '\n' ':')

# Create a virtual environment
python3 -m venv $INSTALLROOT/jax_env
source $INSTALLROOT/jax_env/bin/activate

# Upgrade pip and install wheel
pip install --upgrade pip
pip install wheel

# Install JAX with ROCm support
pip install --upgrade "jax[rocm]" -f https://storage.googleapis.com/jax-releases/jax_rocm_releases.html

# Check if JAX installation succeeded
if [ $? -ne 0 ]; then
    echo "JAX installation failed"
    exit 1
fi

# Install additional dependencies
pip install numpy scipy

# Create a simple test script
cat > $INSTALLROOT/test_jax.py << EOL
import jax
import jax.numpy as jnp

print("JAX version:", jax.__version__)
print("Available devices:", jax.devices())

x = jnp.arange(10)
y = jnp.sum(x)
print("Sum of numbers from 0 to 9:", y)
print("Is GPU being used?", jax.default_backend() == "gpu")
EOL

# Run the test script
python $INSTALLROOT/test_jax.py

# Restore the original LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$OLD_LD_LIBRARY_PATH

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PKGNAME"
alibuild-generate-module --bin --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Our environment
set ${PKGNAME}_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PYTHONPATH \$${PKGNAME}_ROOT/lib/python3.8/site-packages
prepend-path PATH \$${PKGNAME}_ROOT/jax_env/bin
EoF
