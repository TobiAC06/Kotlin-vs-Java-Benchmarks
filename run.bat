@echo off
:: =====================================================================
::  run.bat – Run JMH benchmarks and/or analyse results via Docker
::
::  Usage:
::    run.bat [bench|analyse|all] [OPTIONS] [FILTER]
::
::  Commands:
::    bench      Run benchmarks only (default when no command is given)
::    analyse    Run the analysis script only (requires existing results)
::    all        Run benchmarks, then analyse
::
::  Options (bench / all only):
::    -wi <n>      Warmup iterations       (default: 10)
::    -i  <n>      Measurement iterations  (default: 50)
::    -f  <n>      Forks                   (default: 4)
::
::  Filter (bench / all only):
::    Optional benchmark name / regex (any argument not starting with -)
::
::  Examples:
::    run.bat                              :: full benchmark run with defaults
::    run.bat all                          :: benchmark + analyse
::    run.bat analyse                      :: analyse existing results
::    run.bat Sieve                        :: Sieve benchmarks only
::    run.bat -wi 3 -i 5 -f 1             :: quick smoke-test
::    run.bat -wi 3 -i 5 -f 1 Boxing      :: smoke-test, Boxing only
::    run.bat "Boxing|Lambda"              :: multiple scenarios
:: =====================================================================

setlocal enabledelayedexpansion

set BENCH_IMAGE=jmh-benchmarks:latest
set ANALYSE_IMAGE=jmh-analyse:latest
set RESULTS_DIR=%CD%\results

:: ── Defaults ──────────────────────────────────────────────────────────
set WI=10
set I=50
set F=4
set FILTER=

:: ── Determine command ─────────────────────────────────────────────────
set COMMAND=bench
if "%~1"=="bench"   ( set COMMAND=bench   & shift )
if "%~1"=="analyse" ( set COMMAND=analyse & shift )
if "%~1"=="all"     ( set COMMAND=all     & shift )

:: ── Parse named options ───────────────────────────────────────────────
:parse
if "%~1"=="" goto endparse
if "%~1"=="-wi" ( set WI=%~2 & shift & shift & goto parse )
if "%~1"=="-i"  ( set I=%~2  & shift & shift & goto parse )
if "%~1"=="-f"  ( set F=%~2  & shift & shift & goto parse )
set FILTER=%~1
shift
goto parse
:endparse

:: ── Ensure results directory exists ───────────────────────────────────
if not exist "%RESULTS_DIR%" mkdir "%RESULTS_DIR%"

:: ── Dispatch ──────────────────────────────────────────────────────────
if "%COMMAND%"=="bench"   goto do_bench
if "%COMMAND%"=="analyse" goto do_analyse
if "%COMMAND%"=="all"     goto do_all
goto do_bench

:do_bench
call :run_bench
goto end

:do_analyse
call :run_analyse
goto end

:do_all
call :run_bench
if %ERRORLEVEL% neq 0 goto error
echo.
call :run_analyse
goto end

:: ── Subroutine: run benchmarks ────────────────────────────────────────
:run_bench
echo =^> Image:   %BENCH_IMAGE%
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

set JMH_ARGS=-wi %WI% -i %I% -f %F% -prof gc -v EXTRA -rff results/jmh-results.json -rf json
if not "%FILTER%"=="" set JMH_ARGS=%JMH_ARGS% %FILTER%

docker run --rm ^
    --volume "%RESULTS_DIR%:/benchmarks/results" ^
    --cpus "2" ^
    %BENCH_IMAGE% ^
    %JMH_ARGS%

if %ERRORLEVEL% neq 0 goto error

echo.
echo Benchmarks complete.
echo   Results: %RESULTS_DIR%\jmh-results.json
exit /b 0

:: ── Subroutine: run analysis ──────────────────────────────────────────
:run_analyse
echo =^> Image:   %ANALYSE_IMAGE%
echo =^> Input:   %RESULTS_DIR%\jmh-results.json
echo =^> Output:  %RESULTS_DIR%\
echo.

docker run --rm ^
    --volume "%RESULTS_DIR%:/results" ^
    %ANALYSE_IMAGE%

if %ERRORLEVEL% neq 0 goto error

echo.
echo Analysis complete.
echo   benchmark_runtime.png -^> %RESULTS_DIR%\benchmark_runtime.png
echo   benchmark_memory.png  -^> %RESULTS_DIR%\benchmark_memory.png
exit /b 0

:error
echo ERROR: command failed with exit code %ERRORLEVEL%
exit /b %ERRORLEVEL%

:end
endlocal