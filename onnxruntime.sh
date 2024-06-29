package: ONNXRuntime
version: "%(tag_basename)s"
tag: v1.16.3
source: https://github.com/microsoft/onnxruntime
requires:
  - protobuf
  - re2
  - boost
build_requires:
  - CMake
  - alibuild-recipe-tools
  - "Python:(slc|ubuntu)"  # this package builds ONNX, which requires Python
  - "Python-system:(?!slc.*|ubuntu)"
---
#!/bin/bash -e

mkdir -p $INSTALLROOT
export GPU_TARGETS=gfx906
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1
export ROCM_HOME=/opt/rocm

cmake "$SOURCEDIR/cmake"                                                              \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                             \
      -DCMAKE_BUILD_TYPE=Release                                                      \
      -DCMAKE_INSTALL_LIBDIR=lib                                                      \
      -DPYTHON_EXECUTABLE=$(python3 -c "import sys; print(sys.executable)")           \
      -Donnxruntime_BUILD_UNIT_TESTS=OFF                                              \
      -Donnxruntime_PREFER_SYSTEM_LIB=ON                                              \
      -Donnxruntime_BUILD_SHARED_LIB=ON                                               \
      -Donnxruntime_USE_ROCM=ON                                                       \
      -Donnxruntime_ROCM_HOME=$ROCM_HOME                                              \
      -DCMAKE_HIP_COMPILER=$ROCM_HOME/llvm/bin/clang++                                \
      -D__HIP_PLATFORM_AMD__=1                                                        \
      -DProtobuf_USE_STATIC_LIBS=ON                                                   \
      ${PROTOBUF_ROOT:+-DProtobuf_LIBRARY=$PROTOBUF_ROOT/lib/libprotobuf.a}           \
      ${PROTOBUF_ROOT:+-DProtobuf_LITE_LIBRARY=$PROTOBUF_ROOT/lib/libprotobuf-lite.a} \
      ${PROTOBUF_ROOT:+-DProtobuf_PROTOC_LIBRARY=$PROTOBUF_ROOT/lib/libprotoc.a}      \
      ${PROTOBUF_ROOT:+-DProtobuf_INCLUDE_DIR=$PROTOBUF_ROOT/include}                 \
      ${PROTOBUF_ROOT:+-DProtobuf_PROTOC_EXECUTABLE=$PROTOBUF_ROOT/bin/protoc}        \
      ${RE2_ROOT:+-DRE2_INCLUDE_DIR=${RE2_ROOT}/include}                              \
      ${BOOST_ROOT:+-DBOOST_INCLUDE_DIR=${BOOST_ROOT}/include}                        \
      -DCMAKE_CXX_FLAGS="$CXXFLAGS -Wno-unknown-warning -Wno-unknown-warning-option -Wno-error=unused-but-set-variable" \
      -DCMAKE_C_FLAGS="$CFLAGS -Wno-unknown-warning -Wno-unknown-warning-option -Wno-error=unused-but-set-variable"

cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PKGNAME"
alibuild-generate-module --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Our environment
set ${PKGNAME}_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path ROOT_INCLUDE_PATH \$${PKGNAME}_ROOT/include
prepend-path LD_LIBRARY_PATH \$${PKGNAME}_ROOT/lib

EoF

