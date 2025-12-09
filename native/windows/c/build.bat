@echo off
REM Build script for Pure C implementation on Windows
REM Requires: Microsoft Visual Studio Build Tools

setlocal enabledelayedexpansion

echo Building LLM Chat C implementation...
echo.

REM Check for MSVC compiler
where cl.exe >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: MSVC compiler not found. Please install Visual Studio Build Tools.
    echo Download from: https://visualstudio.microsoft.com/downloads/
    exit /b 1
)

echo Found MSVC compiler
cl.exe --version
echo.

REM Create output directory
if not exist "build" mkdir build

REM Compile C code with optimizations
echo Compiling C code...
cl.exe /O2 /Oi /Ot /GL /W4 ^
    /D_CRT_SECURE_NO_WARNINGS ^
    /D_WINDOWS ^
    /DUNICODE ^
    /D_UNICODE ^
    llm_chat.c ^
    /Fe:build\llm_chat.exe ^
    /Fo:build\ ^
    /link user32.lib gdi32.lib kernel32.lib

if %errorlevel% neq 0 (
    echo Build failed!
    exit /b 1
)

echo.
echo Build successful!
echo Executable: build\llm_chat.exe
echo.
echo To run the application:
echo   build\llm_chat.exe
