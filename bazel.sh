package: bazel
version: "5.0.0"
source: https://github.com/bazelbuild/bazel/releases/download/5.0.0/bazel-5.0.0-dist.zip
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
prepend_path:
  PKG_CONFIG_PATH: "$BAZEL_ROOT/lib/pkgconfig"
---
#!/bin/bash -e

# Unzip Bazel
unzip bazel-5.0.0-dist.zip -d bazel-5.0.0-dist
cd bazel-5.0.0-dist

# Build Bazel
./compile.sh

# Install Bazel
mkdir -p $INSTALLROOT/bin
cp output/bazel $INSTALLROOT/bin/

# Create modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PKGNAME"
alibuild-generate-module --bin > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Our environment
set BAZEL_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$BAZEL_ROOT/bin
EoF
