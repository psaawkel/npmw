@echo off
REM NPM Wrapper for Angular 20 - Automatically downloads and uses Node.js 22.12.0
REM Works like Gradle Wrapper - no external tools required

setlocal enabledelayedexpansion

REM ============================================================================
REM Configuration
REM ============================================================================
set NODE_VERSION=22.12.0
set SCRIPT_DIR=%~dp0
set NODE_CACHE_DIR=%SCRIPT_DIR%.nodejs

REM ============================================================================
REM Detect Architecture
REM ============================================================================
set ARCH=x64
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" set ARCH=arm64
if "%PROCESSOR_ARCHITEW6432%"=="ARM64" set ARCH=arm64

set PLATFORM=win-%ARCH%
set NODE_DIR=%NODE_CACHE_DIR%\node-v%NODE_VERSION%-%PLATFORM%

REM ============================================================================
REM Check if Node.js is already cached
REM ============================================================================
if exist "%NODE_DIR%\node.exe" (
    echo npmw: Node.js %NODE_VERSION% already cached
    goto :run_npm
)

REM ============================================================================
REM Download and Extract Node.js
REM ============================================================================
echo npmw: Downloading Node.js %NODE_VERSION% for %PLATFORM%...

REM Create cache directory
if not exist "%NODE_CACHE_DIR%" mkdir "%NODE_CACHE_DIR%"

set DOWNLOAD_URL=https://nodejs.org/dist/v%NODE_VERSION%/node-v%NODE_VERSION%-%PLATFORM%.zip
set DOWNLOAD_FILE=%NODE_CACHE_DIR%\node-v%NODE_VERSION%-%PLATFORM%.zip

REM Download using PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('%DOWNLOAD_URL%', '%DOWNLOAD_FILE%') } catch { Write-Error 'Failed to download Node.js'; exit 1 } }"

if errorlevel 1 (
    echo Error: Failed to download Node.js from %DOWNLOAD_URL%
    if exist "%DOWNLOAD_FILE%" del /f /q "%DOWNLOAD_FILE%"
    exit /b 1
)

echo npmw: Extracting Node.js %NODE_VERSION%...

REM Try to extract with tar.exe (available in Windows 10+)
where tar.exe >nul 2>&1
if %errorlevel% equ 0 (
    tar.exe -xf "%DOWNLOAD_FILE%" -C "%NODE_CACHE_DIR%"
    if errorlevel 1 (
        echo Error: Failed to extract with tar.exe
        del /f /q "%DOWNLOAD_FILE%"
        exit /b 1
    )
) else (
    REM Fallback to PowerShell Expand-Archive
    powershell -NoProfile -ExecutionPolicy Bypass -Command "& { try { Expand-Archive -Path '%DOWNLOAD_FILE%' -DestinationPath '%NODE_CACHE_DIR%' -Force } catch { Write-Error 'Failed to extract archive'; exit 1 } }"
    if errorlevel 1 (
        echo Error: Failed to extract with PowerShell
        del /f /q "%DOWNLOAD_FILE%"
        exit /b 1
    )
)

REM Clean up download file
del /f /q "%DOWNLOAD_FILE%"

echo npmw: Node.js %NODE_VERSION% installed successfully

REM ============================================================================
REM Run npm
REM ============================================================================
:run_npm

REM Verify node.exe exists
if not exist "%NODE_DIR%\node.exe" (
    echo Error: Node.js binary not found at %NODE_DIR%\node.exe
    exit /b 1
)

REM Add Node.js to PATH for this session
set PATH=%NODE_DIR%;%PATH%

REM Run npm with all arguments
"%NODE_DIR%\node.exe" "%NODE_DIR%\node_modules\npm\bin\npm-cli.js" %*

exit /b %errorlevel%
