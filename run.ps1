# =====================================================================
#  run.ps1 – Run JMH benchmarks inside Docker
#
#  Usage:
#    .\run.ps1 [OPTIONS]
#
#  Parameters:
#    -Wi     <n>       Warmup iterations       (default: 10)
#    -I      <n>       Measurement iterations  (default: 50)
#    -F      <n>       Forks                   (default: 4)
#    -Filter <regex>   Benchmark name / regex filter
#
#  Examples:
#    .\run.ps1                                    # full run with defaults
#    .\run.ps1 -Filter Sieve                      # Sieve benchmarks only
#    .\run.ps1 -Wi 3 -I 5 -F 1                   # quick smoke-test
#    .\run.ps1 -Wi 3 -I 5 -F 1 -Filter Boxing    # smoke-test, Boxing only
#    .\run.ps1 -Filter "Boxing|Lambda"            # multiple scenarios
# =====================================================================
param(
    [int]   $Wi     = 10,
    [int]   $I      = 50,
    [int]   $F      = 4,
    [string]$Filter = ""
)

$ErrorActionPreference = "Stop"

$ImageName  = "jmh-benchmarks:latest"
$ResultsDir = Join-Path (Get-Location) "results"

# Ensure results directory exists on the host
New-Item -ItemType Directory -Force -Path $ResultsDir | Out-Null

# ── Assemble JMH arguments ────────────────────────────────────────────
$JmhArgs = @(
    "-wi", $Wi,
    "-i",  $I,
    "-f",  $F,
    "-prof", "gc",
    "-v",    "EXTRA",
    "-rff",  "results/jmh-results.json",
    "-rf",   "json"
)

if ($Filter -ne "") {
    $JmhArgs += $Filter
}

# ── Print summary ─────────────────────────────────────────────────────
Write-Host "==> Image:   $ImageName"
Write-Host "==> Filter:  $(if ($Filter) { $Filter } else { '<all benchmarks>' })"
Write-Host "==> Warmup:  $Wi iterations"
Write-Host "==> Iters:   $I iterations"
Write-Host "==> Forks:   $F"
Write-Host "==> Results: $ResultsDir\jmh-results.json"
Write-Host ""

docker run --rm `
    --volume "${ResultsDir}:/benchmarks/results" `
    --cpus "2" `
    $ImageName `
    @JmhArgs

if ($LASTEXITCODE -ne 0) {
    Write-Error "docker run failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "✓ Benchmarks complete."
Write-Host "  Results: $ResultsDir\jmh-results.json"