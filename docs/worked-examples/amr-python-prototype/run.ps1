param([int]$Year = 2024, [string]$RHome = '')
# THROWAWAY. Run from any directory. Dependencies and generated material stay ignored.
$ErrorActionPreference = 'Stop'
$taskRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$scratch = Join-Path $taskRoot 'outputs/amr-python-prototype'
$venv = Join-Path $scratch '.venv'
$python = Join-Path $venv 'Scripts/python.exe'
if (-not $RHome) {
    $RHome = (Get-ChildItem "$env:ProgramFiles/R/R-*" -Directory |
        Sort-Object { [version]$_.Name.Substring(2) } -Descending | Select-Object -First 1).FullName
}
$env:R_HOME = $RHome
$env:RPY2_CFFI_MODE = 'ABI'
$env:LC_ALL = 'C'
$env:PATH = "$RHome/bin/x64;$env:PATH"
if (-not (Test-Path -LiteralPath $python)) {
    uv --cache-dir "$scratch/uv-cache" venv $venv --python 3.12 --no-project
    if ($LASTEXITCODE) { throw 'Cannot create the prototype environment.' }
    uv --cache-dir "$scratch/uv-cache" pip install --link-mode copy --python $python -r "$PSScriptRoot/requirements.txt"
    if ($LASTEXITCODE) { throw 'Cannot install prototype dependencies.' }
}
$env:AMR_PROTOTYPE_R_LIB = "$venv/R_libs".Replace('\', '/')
New-Item -ItemType Directory -Force $env:AMR_PROTOTYPE_R_LIB | Out-Null
& "$RHome/bin/Rscript.exe" --vanilla -e 'lib <- Sys.getenv("AMR_PROTOTYPE_R_LIB"); if (!requireNamespace("AMR", lib.loc=lib, quietly=TRUE) || as.character(packageVersion("AMR", lib.loc=lib)) != "3.1.0") install.packages("https://cloud.r-project.org/src/contrib/AMR_3.1.0.tar.gz", lib=lib, repos=NULL, type="source")'
if ($LASTEXITCODE) { throw 'Cannot prepare the isolated R library.' }
& $python -u "$PSScriptRoot/run.py" --year $Year
if ($LASTEXITCODE) { throw 'Prototype run failed.' }
