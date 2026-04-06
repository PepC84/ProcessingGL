#!/usr/bin/env bash
# Build a sketch
# Usage: ./build.sh [path/to/sketch.cpp] [output_name]
#   e.g. ./build.sh src/MySketch.cpp MyApp
set -e
SKETCH="${1:-src/MySketch.cpp}"
OUT="${2:-SketchApp}"
echo "[build] $SKETCH → $OUT"
g++ -std=c++17 \
    src/Processing.cpp \
    "$SKETCH" \
    src/main.cpp \
    -o "${OUT}" \
    -lglfw -lGLEW -lGL -lGLU -lm -pthread
echo "[build] Done: ./${OUT}"
