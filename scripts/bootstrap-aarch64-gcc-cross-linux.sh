#!/bin/bash

CMAKE_BIN=cmake
BUILD_DIR=build-aarch64-cross

rm -rf $BUILD_DIR
mkdir $BUILD_DIR

cd $BUILD_DIR && $CMAKE_BIN \
  -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
  ../LAPACKE
