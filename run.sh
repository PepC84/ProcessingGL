#!/usr/bin/env bash
# Build a sketch and immediately run it
# Usage: ./run.sh [path/to/sketch.cpp] [output_name]
set -e
bash build.sh "${1:-src/MySketch.cpp}" "${2:-SketchApp}"
./"${2:-SketchApp}"
