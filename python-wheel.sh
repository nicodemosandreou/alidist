package: python-wheel
version: "latest"
source: none
build_requires: []
---
#!/bin/bash -e

# Install python-wheel
pip install wheel

# Create modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PKGNAME"
alibuild-generate-module --bin > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Our environment
set PYTHON_WHEEL_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$PYTHON_WHEEL_ROOT/bin
EoF
