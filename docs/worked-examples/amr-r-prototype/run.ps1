param([int]$Year = 2024, [string]$RHome = '')
# THROWAWAY. Run from any directory; the computation runs directly in R.
$ErrorActionPreference = 'Stop'
if (-not $RHome) {
    $RHome = (Get-ChildItem "$env:ProgramFiles/R/R-*" -Directory |
        Sort-Object { [version]$_.Name.Substring(2) } -Descending | Select-Object -First 1).FullName
}
$env:LC_ALL = 'C'
& "$RHome/bin/Rscript.exe" --vanilla "$PSScriptRoot/run.R" $Year
if ($LASTEXITCODE) { throw 'Prototype run failed.' }
