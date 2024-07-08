package: python-setuptools
version: "latest"
source: none
build_requires: []
---
#!/bin/bash -e

# Install python-setuptools
pip install setuptools

# Create modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PKGNAME"
alibuild-generate-module --bin > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Our environment
set PYTHON_SETUPTOOLS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$PYTHON_SETUPTOOLS_ROOT/bin
EoF
