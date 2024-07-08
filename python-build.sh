package: python-build
version: "latest"
source: none
build_requires: []
---
#!/bin/bash -e

# Install python-build
pip install build

# Create modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PKGNAME"
alibuild-generate-module --bin > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Our environment
set PYTHON_BUILD_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$PYTHON_BUILD_ROOT/bin
EoF