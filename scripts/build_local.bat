@echo off
REM Windows batch script to build Device Monitor executables locally

setlocal enabledelayedexpansion

echo Device Monitor Local Build Script for Windows
echo =============================================

REM Check if Python is available
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Python not found. Please install Python 3.7+ and add it to PATH.
    pause
    exit /b 1
)

REM Check if we're in the correct directory
if not exist "main.py" (
    echo ERROR: main.py not found. Please run this script from the project root directory.
    pause
    exit /b 1
)

REM Install required dependencies
echo Installing dependencies...
pip install pyinstaller pywin32 --quiet --no-warn-script-location

REM Parse command line arguments
set MODE=all
set VERSION=dev
set NO_CLEAN=0
set NO_TEST=0
set NO_PACKAGE=0

:parse_args
if "%~1"=="" goto :build
if "%~1"=="--mode" (
    set MODE=%~2
    shift
    shift
    goto :parse_args
)
if "%~1"=="--version" (
    set VERSION=%~2
    shift
    shift
    goto :parse_args
)
if "%~1"=="--no-clean" (
    set NO_CLEAN=1
    shift
    goto :parse_args
)
if "%~1"=="--no-test" (
    set NO_TEST=1
    shift
    goto :parse_args
)
if "%~1"=="--no-package" (
    set NO_PACKAGE=1
    shift
    goto :parse_args
)
if "%~1"=="--help" goto :show_help
shift
goto :parse_args

:build
echo.
echo Building Device Monitor v%VERSION% for Windows
echo Mode: %MODE%
echo.

REM Build using Python script
set PYTHON_ARGS=--platform windows --version %VERSION%

if "%MODE%" neq "all" (
    set PYTHON_ARGS=!PYTHON_ARGS! --mode %MODE%
)

if %NO_CLEAN% equ 1 (
    set PYTHON_ARGS=!PYTHON_ARGS! --no-clean
)

if %NO_TEST% equ 1 (
    set PYTHON_ARGS=!PYTHON_ARGS! --no-test
)

if %NO_PACKAGE% equ 1 (
    set PYTHON_ARGS=!PYTHON_ARGS! --no-package
)

echo Running: python scripts\build_local.py %PYTHON_ARGS%
python "scripts\build_local.py" %PYTHON_ARGS%

echo.
echo Build completed!
if %NO_PACKAGE% equ 0 (
    echo.
    echo Release packages created:
    if exist "release\" (
        dir "release\*.zip" /b 2>nul
    )
)

pause
exit /b 0

:show_help
echo Usage: %~n0 [options]
echo.
echo Options:
echo   --mode [normal^|kiosk^|all]    Build mode (default: all)
echo   --version VERSION             Version string (default: dev)
echo   --no-clean                    Don't clean build directories
echo   --no-test                     Skip executable testing
echo   --no-package                  Skip release packaging
echo   --help                        Show this help
echo.
echo Examples:
echo   %~n0                          Build all modes
echo   %~n0 --mode kiosk             Build only kiosk mode
echo   %~n0 --version 1.0.0          Build with version 1.0.0
echo.
pause
exit /b 0