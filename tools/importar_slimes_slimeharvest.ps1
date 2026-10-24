# Backup se o GitHub Actions nao conseguir importar automaticamente os sprites.
# Executar na raiz do projeto: .\tools\importar_slimes_slimeharvest.ps1
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$clone = Join-Path $env:TEMP "slime-harvest-assets-import"
if (Test-Path $clone) {
    Remove-Item -Recurse -Force $clone
}
git clone --depth 1 --filter=blob:none --sparse "https://github.com/HelioConde/Slime-Harvest.git" $clone
if ($LASTEXITCODE -ne 0) { throw "Falha ao clonar Slime-Harvest." }
git -C $clone sparse-checkout set "assets/slimes/bestiary"
if ($LASTEXITCODE -ne 0) { throw "Falha ao consultar sprites de slimes." }
$source = Join-Path $clone "assets/slimes/bestiary"
$target = Join-Path $root "assets/slimes/bestiary"
$count = 0
foreach ($folder in (Get-ChildItem $source -Directory)) {
    $name = $folder.Name
    $png = Join-Path $folder.FullName "$name.png"
    $frames = Join-Path $folder.FullName "${name}_frames.tres"
    if (-not (Test-Path $png) -or -not (Test-Path $frames)) {
        throw "Arquivo de slime incompleto: $name"
    }
    $dest = Join-Path $target $name
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Copy-Item $png $dest -Force
    Copy-Item $frames $dest -Force
    $count++
}
Write-Host "Sprites e animacoes de $count especies importados." -ForegroundColor Green
if ($count -ne 32) { throw "Esperadas 32 especies, encontradas $count" }
Write-Host 'Opcional: git add assets/slimes/bestiary ; git commit -m "Importa slimes" ; git push origin main'
