param(
    [string]$LuacPath
)

$ErrorActionPreference = "Stop"

function Resolve-LuacPath {
    param([string]$PreferredPath)

    if ($PreferredPath -and (Test-Path $PreferredPath)) {
        return $PreferredPath
    }

    $command = Get-Command luac -ErrorAction SilentlyContinue
    if ($command -and $command.Source) {
        return $command.Source
    }

    $candidates = @(
        "C:\Program Files (x86)\Lua\5.1\luac.exe",
        "C:\Program Files\Lua\5.1\luac.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    throw "Unable to locate luac.exe. Pass -LuacPath explicitly."
}

$resolvedLuacPath = Resolve-LuacPath -PreferredPath $LuacPath
$repoRoot = Split-Path -Parent $PSScriptRoot
$luaFiles = Get-ChildItem -Path $repoRoot -Filter "*.lua" -File | Sort-Object Name

if (-not $luaFiles) {
    Write-Error "No Lua files found in $repoRoot."
    exit 1
}

$failedFiles = @()
foreach ($file in $luaFiles) {
    & $resolvedLuacPath -p $file.FullName *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK`t$($file.Name)"
    } else {
        Write-Host "ERR`t$($file.Name)"
        $failedFiles += $file.Name
    }
}

if ($failedFiles.Count -gt 0) {
    Write-Error ("Lua syntax check failed: " + ($failedFiles -join ", "))
    exit 1
}

Write-Host ("Checked {0} file(s) with {1}" -f $luaFiles.Count, $resolvedLuacPath)
