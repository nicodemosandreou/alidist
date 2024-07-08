package: python-installer
version: "latest"
source: none
build_requires: []
---
#!/bin/bash -e

# Install python-installer
pip install installer

# Create modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PKGNAME"
alibuild-generate-module --bin > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Our environment
set PYTHON_INSTALLER_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$PYTHON_INSTALLER_ROOT/bin
EoF
