@echo off
:: =====================================================================
::  build.bat – Build the JMH benchmark Docker image
::
::  Usage:
::    build.bat           :: build with default tag
::    build.bat my-tag    :: build with custom tag
:: =====================================================================

set IMAGE_NAME_BENCH=jmh-benchmarks
set IMAGE_NAME_ANALYSE=jmh-analyse
set TAG=%~1
if "%TAG%"=="" set TAG=latest
set FULL_BENCH_TAG=%IMAGE_NAME_BENCH%:%TAG%
set FULL_ANALYSE_TAG=%IMAGE_NAME_ANALYSE%:%TAG%

echo =^> Building Docker image: %FULL_BENCH_TAG%
docker build ^
    --target run ^
    --tag %FULL_BENCH_TAG% ^
    --file Dockerfile ^
    .


if %ERRORLEVEL% neq 0 (
    echo ERROR: docker build failed for %FULL_BENCH_TAG% with exit code %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

echo =^> Building Docker image: %FULL_ANALYSE_TAG%
docker build ^
    --target analyse ^
    --tag %FULL_ANALYSE_TAG% ^
    --file Dockerfile ^
    .

if %ERRORLEVEL% neq 0 (
    echo ERROR: docker build failed for %FULL_ANALYSE_TAG% with exit code %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

echo.
echo Images built successfully
echo Run benchmarks with:  run.bat