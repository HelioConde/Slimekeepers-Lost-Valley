param([string]$GodotBinary = 'C:\godot\Godot_v4.7.2-stable_win64_console.exe', [string]$EvidenceFolder = 'docs\world\living_v3')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$evidenceDir = Join-Path $projectRoot $EvidenceFolder
New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null
$checks = @('test_clearing','test_forest_v2','test_habitats','test_forest_life','test_forest_audio','test_valley','test_valley_water','test_region_travel','test_menu','test_slime_ecosystem','test_environment_v3','test_environment_regions','test_living_regions','test_visual_rules','test_curated_exports','test_map_composition','test_pond_banks','test_day_night','test_water_reflections','test_day_shadows')
foreach ($check in $checks) {
    $logPath = Join-Path $evidenceDir ($check + '.log')
    & $GodotBinary --headless --path $projectRoot --script "res://tools/$check.gd" -- --require-complete-art *> $logPath
    $code = $LASTEXITCODE
    $errors = Select-String -LiteralPath $logPath -Pattern 'SCRIPT ERROR:|Parse Error:|^ERROR:|FAIL:'
    if ($code -ne 0 -or $errors) {
        Get-Content -LiteralPath $logPath -Tail 35
        throw "Validation failed: $check (exit $code)"
    }
    Get-Content -LiteralPath $logPath | Select-String 'checks|INTEGRATION|TEST|FOREST_'
}
$gdunitLog = Join-Path $evidenceDir 'gdunit.log'
& $GodotBinary --headless --path $projectRoot -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/forest -c --ignoreHeadlessMode *> $gdunitLog
if ($LASTEXITCODE -ne 0) { Get-Content -LiteralPath $gdunitLog -Tail 40; throw 'GdUnit4 failed' }
Write-Output 'All forest/valley checks passed. Native rendering and 5-minute exploration are separate tools.'
