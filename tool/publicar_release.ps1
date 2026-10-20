param(
    [Parameter(Mandatory = $true)][int]$Version,
    [string]$Notas = "",
    [switch]$SoloConstruir
)

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz

(Get-Content lib/core/version_app.dart -Raw) -replace 'const int versionApp = \d+;', "const int versionApp = $Version;" | Set-Content lib/core/version_app.dart -NoNewline
(Get-Content windows/installer/RepuestosPOS.iss -Raw) -replace '#define MyAppVersion "\d+"', "#define MyAppVersion `"$Version`"" | Set-Content windows/installer/RepuestosPOS.iss -NoNewline
(Get-Content pubspec.yaml -Raw) -replace '(?m)^version: .*$', "version: 1.0.$Version+$Version" | Set-Content pubspec.yaml -NoNewline

flutter build windows --release
if ($LASTEXITCODE -ne 0) { throw "Fallo flutter build windows" }

$iscc = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
& $iscc "windows\installer\RepuestosPOS.iss"
if ($LASTEXITCODE -ne 0) { throw "Fallo Inno Setup" }

flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw "Fallo flutter build apk" }

$dist = Join-Path $raiz "dist"
if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
New-Item -ItemType Directory $dist | Out-Null

Copy-Item "windows\installer\Output\RepuestosPOS$Version.exe" "$dist\RepuestosPOS$Version.exe"
Copy-Item "windows\installer\Output\RepuestosPOS$Version.exe" "$dist\RepuestosPOS.exe"
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "$dist\RepuestosPOS$Version.apk"
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "$dist\RepuestosPOS.apk"

$archivos = Get-ChildItem $dist -File | ForEach-Object { $_.FullName }
dart tool/firmar_release.dart @archivos
if ($LASTEXITCODE -ne 0) { throw "Fallo la firma de los instaladores" }

if ($SoloConstruir) { return }

$subir = Get-ChildItem $dist -File | ForEach-Object { $_.FullName }
gh release create "v$Version" @subir --title "Version $Version" --notes $Notas
if ($LASTEXITCODE -ne 0) { throw "Fallo gh release create" }
