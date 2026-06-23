@echo off
:: =====================================================================
::  run.bat – Run JMH benchmarks inside Docker
::
::  Usage:
::    run.bat [FILTER] [-wi <n>] [-i <n>] [-f <n>]
::
::  Arguments (all optional, order does not matter):
::    -wi <n>      Warmup iterations       (default: 10)
::    -i  <n>      Measurement iterations  (default: 50)
::    -f  <n>      Forks                   (default: 4)
::    FILTER       Benchmark name / regex  (any argument not starting with -)
::
::  Examples:
::    run.bat                              :: full run with defaults
::    run.bat Sieve                        :: Sieve benchmarks only
::    run.bat -wi 3 -i 5 -f 1             :: quick smoke-test
::    run.bat -wi 3 -i 5 -f 1 Boxing      :: smoke-test, Boxing only
::    run.bat "Boxing|Lambda"              :: multiple scenarios
:: =====================================================================

setlocal enabledelayedexpansion

set IMAGE_NAME=jmh-benchmarks:latest
set RESULTS_DIR=%CD%\results

:: ── Defaults ─────────────────────────────────────────────────────────
set WI=10
set I=50
set F=4
set FILTER=

:: ── Parse arguments ───────────────────────────────────────────────────
:parse
if "%~1"=="" goto endparse
if "%~1"=="-wi" ( set WI=%~2 & shift & shift & goto parse )
if "%~1"=="-i"  ( set I=%~2  & shift & shift & goto parse )
if "%~1"=="-f"  ( set F=%~2  & shift & shift & goto parse )
:: Anything else is treated as the benchmark filter
set FILTER=%~1
shift
goto parse
:endparse

:: ── Ensure results directory exists ──────────────────────────────────
if not exist "%RESULTS_DIR%" mkdir "%RESULTS_DIR%"

:: ── Print summary ─────────────────────────────────────────────────────
echo =^> Image:   %IMAGE_NAME%
if "%FILTER%"=="" (
    echo =^> Filter:  ^<all benchmarks^>
) else (
    echo =^> Filter:  %FILTER%
)
echo =^> Warmup:  %WI% iterations
echo =^> Iters:   %I% iterations
echo =^> Forks:   %F%
echo =^> Results: %RESULTS_DIR%\jmh-results.json
echo.

:: ── Build JMH args and run ────────────────────────────────────────────
set JMH_ARGS=-wi %WI% -i %I% -f %F% -prof gc -v EXTRA -rff results/jmh-results.json -rf json
if not "%FILTER%"=="" set JMH_ARGS=%JMH_ARGS% %FILTER%

docker run --rm ^
    --volume "%RESULTS_DIR%:/benchmarks/results" ^
    --cpus "2" ^
    %IMAGE_NAME% ^
    %JMH_ARGS%

if %ERRORLEVEL% neq 0 (
    echo ERROR: docker run failed with exit code %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

echo.
echo ^ Benchmarks complete.
echo   Results: %RESULTS_DIR%\jmh-results.json

endlocal