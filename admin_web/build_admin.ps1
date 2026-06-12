$ErrorActionPreference = 'Stop'
$NodeDir = 'C:\Program Files\nodejs'
$npm = Join-Path $NodeDir 'npm.cmd'
$env:Path = "$NodeDir;$env:Path"

$ProjectAdmin = $PSScriptRoot
$BuildRoot = 'C:\dev\swim_admin_web'

if (-not (Test-Path "$NodeDir\npm.cmd")) {
  Write-Error 'Node.js не найден. Установи с https://nodejs.org и добавь в PATH: C:\Program Files\nodejs'
}

if (Test-Path $BuildRoot) {
  Remove-Item -Recurse -Force $BuildRoot
}
New-Item -ItemType Directory -Force -Path $BuildRoot | Out-Null

robocopy $ProjectAdmin $BuildRoot /E /XD node_modules dist .git /NFL /NDL /NJH /NJS | Out-Null
if (Test-Path "$ProjectAdmin\.env") {
  Copy-Item "$ProjectAdmin\.env" "$BuildRoot\.env" -Force
}

Set-Location $BuildRoot
& $npm install
& $npm run build

$distDst = Join-Path $ProjectAdmin 'dist'
if (Test-Path $distDst) {
  Remove-Item -Recurse -Force $distDst
}
robocopy (Join-Path $BuildRoot 'dist') $distDst /E /NFL /NDL /NJH /NJS | Out-Null

Write-Host 'Готово: admin_web/dist обновлён. Запуск dev: cd C:\dev\swim_admin_web && npm run dev'
