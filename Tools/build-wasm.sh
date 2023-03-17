#!/bin/bash
set -e

autoreconf -i
mkdir -p build/native
pushd build/native
../../configure -C
make -j"$(nproc)"
popd

mkdir -p build/wasm
pushd build/wasm
(
  set -e
  export CONFIG_SITE=$(realpath ../../Tools/wasm/config.site-wasm32-emscripten)
  export LIBSQLITE3_CFLAGS=' '
  export BZIP2_CFLAGS=' '
  export LDFLAGS="\
      -s ALLOW_MEMORY_GROWTH=1 \
      -s EXPORTED_FUNCTIONS=_main,_free,_malloc \
      -s EXPORTED_RUNTIME_METHODS=FS,PROXYFS,ERRNO_CODES,allocateUTF8 \
      -lproxyfs.js \
      --js-library='$(realpath ../../Tools/fsroot.js)' \
  "
  emconfigure ../../configure -C \
      --host=wasm32-unknown-emscripten \
      --build=$(realpath ../../config.guess) \
      --with-emscripten-target=browser \
      --disable-wasm-dynamic-linking \
      --with-suffix=.mjs \
      --disable-wasm-preload \
      --enable-wasm-js-module \
      --with-build-python="$(../native/python)"
  emmake make -j$(nproc)
)
popd
