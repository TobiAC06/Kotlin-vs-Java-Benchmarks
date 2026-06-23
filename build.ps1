# =====================================================================
#  build.ps1 – Build the JMH benchmark Docker image
#
#  Usage:
#    .\build.ps1             # build with default tag
#    .\build.ps1 -Tag my-tag # build with custom tag
# =====================================================================
param(
    [string]$Tag = "latest"
)

$ErrorActionPreference = "Stop"

$ImageName = "jmh-benchmarks"
$FullTag   = "${ImageName}:${Tag}"

Write-Host "==> Building Docker image: $FullTag"
docker build `
    --target run `
    --tag $FullTag `
    --file Dockerfile `
    .

if ($LASTEXITCODE -ne 0) {
    Write-Error "docker build failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "✓ Image built successfully: $FullTag"
Write-Host "  Run benchmarks with:  .\run.ps1"