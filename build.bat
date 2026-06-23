@echo off
:: =====================================================================
::  build.bat – Build the JMH benchmark Docker image
::
::  Usage:
::    build.bat           :: build with default tag
::    build.bat my-tag    :: build with custom tag
:: =====================================================================

set IMAGE_NAME=jmh-benchmarks
set TAG=%~1
if "%TAG%"=="" set TAG=latest
set FULL_TAG=%IMAGE_NAME%:%TAG%

echo =^> Building Docker image: %FULL_TAG%
docker build ^
    --target run ^
    --tag %FULL_TAG% ^
    --file Dockerfile ^
    .

if %ERRORLEVEL% neq 0 (
    echo ERROR: docker build failed with exit code %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

echo.
echo ^ Image built successfully: %FULL_TAG%
echo   Run benchmarks with:  run.bat