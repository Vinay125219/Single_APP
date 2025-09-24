#!/bin/bash

# Linux shell script to build Device Monitor executables locally

set -e

echo "Device Monitor Local Build Script for Linux"
echo "==========================================="

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python3 not found. Please install Python 3.6+ and add it to PATH."
    exit 1
fi

# Check if we're in the correct directory
if [[ ! -f "main.py" ]]; then
    echo "ERROR: main.py not found. Please run this script from the project root directory."
    exit 1
fi

# Install required dependencies
echo "Installing dependencies..."
python3 -m pip install pyinstaller --quiet --no-warn-script-location

# Parse command line arguments
MODE="all"
VERSION="dev"
NO_CLEAN=0
NO_TEST=0
NO_PACKAGE=0

show_help() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --mode [normal|kiosk|all]    Build mode (default: all)"
    echo "  --version VERSION            Version string (default: dev)"
    echo "  --no-clean                   Don't clean build directories"
    echo "  --no-test                    Skip executable testing"
    echo "  --no-package                 Skip release packaging"
    echo "  --help                       Show this help"
    echo
    echo "Examples:"
    echo "  $0                           Build all modes"
    echo "  $0 --mode kiosk              Build only kiosk mode"
    echo "  $0 --version 1.0.0           Build with version 1.0.0"
    echo
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --mode)
            MODE="$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --no-clean)
            NO_CLEAN=1
            shift
            ;;
        --no-test)
            NO_TEST=1
            shift
            ;;
        --no-package)
            NO_PACKAGE=1
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

echo
echo "Building Device Monitor v$VERSION for Linux"
echo "Mode: $MODE"
echo

# Build using Python script
PYTHON_ARGS="--platform linux --version $VERSION"

if [[ "$MODE" != "all" ]]; then
    PYTHON_ARGS="$PYTHON_ARGS --mode $MODE"
fi

if [[ $NO_CLEAN -eq 1 ]]; then
    PYTHON_ARGS="$PYTHON_ARGS --no-clean"
fi

if [[ $NO_TEST -eq 1 ]]; then
    PYTHON_ARGS="$PYTHON_ARGS --no-test"
fi

if [[ $NO_PACKAGE -eq 1 ]]; then
    PYTHON_ARGS="$PYTHON_ARGS --no-package"
fi

echo "Running: python3 scripts/build_local.py $PYTHON_ARGS"
python3 "scripts/build_local.py" $PYTHON_ARGS

echo
echo "Build completed!"
if [[ $NO_PACKAGE -eq 0 ]]; then
    echo
    echo "Release packages created:"
    if [[ -d "release" ]]; then
        ls -la release/*.tar.gz 2>/dev/null || echo "No packages found"
    fi
fi