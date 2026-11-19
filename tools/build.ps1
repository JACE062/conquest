param([string]$Godot = "godot")

$ErrorActionPreference = "Stop"
$project = Split-Path $PSScriptRoot -Parent
Push-Location $project
try {
    $version = & $Godot --version
    if ($LASTEXITCODE -ne 0 -or $version -notmatch '^4\.7\.2\.stable') {
        throw "Install Godot 4.7.2 stable and its matching export templates."
    }
    foreach ($directory in "build/web", "build/windows") {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }
    New-Item -ItemType File -Force -Path "build/.gdignore" | Out-Null
    & $Godot --headless --editor --import
    if ($LASTEXITCODE -ne 0) { throw "Project import failed." }
    & $Godot --headless -s tests/rules_test.gd
    if ($LASTEXITCODE -ne 0) { throw "Rules tests failed." }
    foreach ($preset in "Web", "Windows Desktop") {
        & $Godot --headless --export-release $preset
        if ($LASTEXITCODE -ne 0) { throw "$preset export failed." }
    }
    foreach ($target in "web", "windows") {
        Copy-Item -LiteralPath "art/OFL.txt", "CREDITS.txt" -Destination "build/$target"
    }
    Compress-Archive -Path "build/windows/*" -DestinationPath "build/Conquest-Windows-x64.zip" -Force
} finally {
    Pop-Location
}
