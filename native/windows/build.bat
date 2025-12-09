@echo off
setlocal enabledelayedexpansion

echo Building LLM Chat for Windows...

set SCRIPT_DIR=%~dp0
set BUILD_DIR=%SCRIPT_DIR%build
set OUTPUT_DIR=%BUILD_DIR%\Release

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

cd "%SCRIPT_DIR%"

dotnet publish LLMChat.csproj ^
    --configuration Release ^
    --runtime win-x64 ^
    --output "%OUTPUT_DIR%" ^
    --self-contained false

if !ERRORLEVEL! equ 0 (
    echo Build successful!
    echo Output: %OUTPUT_DIR%\LLMChat.exe
    
    if exist "%OUTPUT_DIR%\LLMChat.exe" (
        echo Starting application...
        start "" "%OUTPUT_DIR%\LLMChat.exe"
    )
) else (
    echo Build failed!
    exit /b 1
)

endlocal
