param(
    [string]$RHome = '',
    [switch]$Stage1Only,
    [switch]$BuildOnly
)
# THROWAWAY: Reproduce Rouen NATUREPVT sample-type mapping prototype locally on Windows.
$ErrorActionPreference = 'Stop'

if (-not $RHome) {
    $RHome = (Get-ChildItem "$env:ProgramFiles/R/R-*" -Directory |
        Sort-Object { [version]$_.Name.Substring(2) } -Descending | Select-Object -First 1).FullName
}
$rscript = Join-Path $RHome 'bin/Rscript.exe'
if (-not (Test-Path $rscript)) {
    throw "Rscript.exe not found under $RHome"
}

if (-not $BuildOnly) {
    Write-Host "Running Stage 1 (deterministic pre-grouping)..."
    & $rscript --vanilla "$PSScriptRoot/stage1_pregroup.R"
    if ($LASTEXITCODE) { throw 'Stage 1 R script failed.' }
}

if ($Stage1Only) {
    Write-Host "Stage 1 complete. Run Stage 2 workflow next, then rerun with -BuildOnly."
    exit 0
}

$clsJson = Join-Path (Resolve-Path "$PSScriptRoot/../../..").Path "outputs/sample-type-prototype/classifications.json"
if (-not (Test-Path $clsJson)) {
    throw "Missing Stage 2 output: $clsJson. Run Stage 2 workflow (classify_workflow.py via run_workflow) first."
}

Write-Host "Running Stage 3 (merge & build HTML/Markdown deliverables)..."
& $rscript --vanilla "$PSScriptRoot/build_deliverables.R"
if ($LASTEXITCODE) { throw 'Stage 3 R build script failed.' }
