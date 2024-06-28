package: ONNXRuntime
version: "%(tag_basename)s"
tag: v1.16.0
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
prepend_path:
  ROOT_INCLUDE_PATH: "$ONNXRUNTIME_ROOT/include/onnxruntime"
---
#!/bin/bash -e

mkdir -p $INSTALLROOT

# Set up environment variables for ROCm
export ROCM_PATH=/opt/rocm  
export ROCM_HOME=$ROCM_PATH
export PATH=$ROCM_HOME/bin:$PATH
export PATH=$ROCM_HOME/llvm/bin:$PATH
export LD_LIBRARY_PATH=$ROCM_HOME/lib:$ROCM_HOME/lib64:$LD_LIBRARY_PATH
export HIP_PLATFORM=hcc
export GPU_TARGETS=gfx906


# Save current LD_LIBRARY_PATH
OLD_LD_LIBRARY_PATH=$LD_LIBRARY_PATH

# Temporarily remove ROCm's libstdc++.so.6 from LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v "$ROCM_HOME/lib" | tr '\n' ':')

cmake "$SOURCEDIR/cmake"                                                              \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                             \
      -DCMAKE_BUILD_TYPE=Release                                                      \
      -DCMAKE_INSTALL_LIBDIR=lib                                                      \
      -DPYTHON_EXECUTABLE=$(python3 -c "import sys; print(sys.executable)")           \
      -Donnxruntime_BUILD_UNIT_TESTS=OFF                                              \
      -Donnxruntime_PREFER_SYSTEM_LIB=ON                                              \
      -Donnxruntime_BUILD_SHARED_LIB=ON                                               \
      -DProtobuf_USE_STATIC_LIBS=ON                                                   \
      -Donnxruntime_USE_ROCM=ON                                                       \
      -Donnxruntime_ROCM_HOME=$ROCM_HOME                                              \
      ${PROTOBUF_ROOT:+-DProtobuf_LIBRARY=$PROTOBUF_ROOT/lib/libprotobuf.a}           \
      ${PROTOBUF_ROOT:+-DProtobuf_LITE_LIBRARY=$PROTOBUF_ROOT/lib/libprotobuf-lite.a} \
      ${PROTOBUF_ROOT:+-DProtobuf_PROTOC_LIBRARY=$PROTOBUF_ROOT/lib/libprotoc.a}      \
      ${PROTOBUF_ROOT:+-DProtobuf_INCLUDE_DIR=$PROTOBUF_ROOT/include}                 \
      ${PROTOBUF_ROOT:+-DProtobuf_PROTOC_EXECUTABLE=$PROTOBUF_ROOT/bin/protoc}        \
      ${RE2_ROOT:+-DRE2_INCLUDE_DIR=${RE2_ROOT}/include}                              \
      ${BOOST_ROOT:+-DBOOST_INCLUDE_DIR=${BOOST_ROOT}/include}                        \
      -DCMAKE_CXX_FLAGS="$CXXFLAGS -Wno-unknown-warning -Wno-unknown-warning-option -Wno-error=unused-but-set-variable" \
      -DCMAKE_C_FLAGS="$CFLAGS -Wno-unknown-warning -Wno-unknown-warning-option -Wno-error=unused-but-set-variable"      \
      -DCMAKE_HIP_COMPILER=$ROCM_HOME/llvm/bin/clang++                                \
      -D__HIP_PLATFORM_AMD__=1

cmake --build . -- ${JOBS:+-j$JOBS} install

# Restore the original LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$OLD_LD_LIBRARY_PATH

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
MODULEFILE="$INSTALLROOT/etc/modulefiles/$PKGNAME"
alibuild-generate-module --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF

# Our environment
set ${PKGNAME}_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path ROOT_INCLUDE_PATH \$${PKGNAME}_ROOT/include/onnxruntime
EoF
