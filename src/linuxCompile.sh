#!/bin/bash

# to abort in case of errors
function error {
echo aborted due to an error
exit 1
}
trap error ERR

# building c++-part (qt-bindings)
cd cpp
mkdir -p dist
cd dist
cmake ..
make
cd ../..

cabal install --only-dependencies $@ || true
cabal install --only-dependencies -j1 $@
cabal configure $@
cabal build
