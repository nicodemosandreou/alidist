package: bazel
version: "5.0.0"
source: https://github.com/bazelbuild/bazel/releases/download/5.0.0/bazel-5.0.0-installer-linux-x86_64.sh
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
prepend_path:
  PKG_CONFIG_PATH: "$BAZEL_ROOT/lib/pkgconfig"
---
#!/bin/bash -e

# Define the Bazel version and installation prefix
BAZEL_VERSION=5.0.0
INSTALL_PREFIX=$INSTALLROOT

# Download the Bazel installer
curl -LO https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh

# Make the installer executable
chmod +x bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh

# Run the installer
./bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh --prefix=${INSTALL_PREFIX}

# Create modulefile
mkdir -p "${INSTALL_PREFIX}/etc/modulefiles"
MODULEFILE="${INSTALL_PREFIX}/etc/modulefiles/${PKGNAME}"
alibuild-generate-module --bin > "${MODULEFILE}"
cat >> "${MODULEFILE}" <<EoF

# Our environment
set BAZEL_ROOT \$::env(BASEDIR)/${PKGNAME}/\$version
prepend-path PATH \$BAZEL_ROOT/bin
EoF
