#!/usr/bin/env bash
# Rebuild the gcc-processing IDE
# Usage: ./buildIDE.sh
set -e
echo "[build] Compiling IDE..."
g++ -std=c++17 \
    src/Processing.cpp \
    src/IDE.cpp \
    src/main.cpp \
    -o ide \
    -lglfw -lGLEW -lGL -lGLU -lm -pthread
echo "[build] Done: ./ide"
