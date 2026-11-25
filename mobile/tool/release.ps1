# NEW 12.2: one script makes a release, the same on CI and on a laptop.
# Usage: pwsh tool/release.ps1 -Tag v1.2.3 [-BuildNumber 37]
param(
  [Parameter(Mandatory)][string]$Tag,
  [int]$BuildNumber = 0
)
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

if ($Tag -notmatch '^v(\d+\.\d+\.\d+)$') { throw "The tag must look like v1.2.3, got '$Tag'" }
$name = $Matches[1]
if ($BuildNumber -le 0) { $BuildNumber = [int]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() / 60) }

# Without key.properties Gradle quietly signs with the debug key: refuse instead
$propsFile = 'android/key.properties'
if (-not (Test-Path $propsFile)) { throw 'android/key.properties is missing: refusing to build (it would be signed with the debug key).' }
$props = @{}
Get-Content $propsFile | ForEach-Object { if ($_ -match '^\s*([^=#]+?)\s*=\s*(.*)$') { $props[$Matches[1]] = $Matches[2] } }

function Get-Sha256([string[]]$lines) {
  ($lines | Where-Object { $_ -match 'SHA-?256:' } | Select-Object -First 1) -replace '.*SHA-?256:\s*', ''
}
$expected = Get-Sha256 (keytool -list -v -keystore $props['storeFile'] -alias $props['keyAlias'] -storepass $props['storePassword'])
if (-not $expected) { throw 'Could not read the upload key fingerprint.' }

$outDir = 'release-out'
New-Item -ItemType Directory -Force $outDir | Out-Null
$symbols = "$outDir/symbols"

function Build($kind, $flavor) {
  $args = @('build', $kind, '--release', '--flavor', $flavor, "--dart-define-from-file=config/$flavor.json")
  if (Test-Path "config/firebase.$flavor.json") { $args += "--dart-define-from-file=config/firebase.$flavor.json" }
  $args += @("--build-name=$name", "--build-number=$BuildNumber", '--obfuscate', "--split-debug-info=$symbols/$flavor")
  flutter @args
  if ($LASTEXITCODE -ne 0) { throw "flutter build $kind failed" }
}

Build 'apk' 'staging'
Build 'appbundle' 'prod'

$apk = Get-ChildItem build/app/outputs/flutter-apk -Filter '*staging*release*.apk' | Select-Object -First 1
$aab = Get-ChildItem build/app/outputs/bundle -Recurse -Filter '*.aab' | Select-Object -First 1
if (-not $apk -or -not $aab) { throw 'A build output is missing.' }

# Signed with the upload key, or nothing leaves
foreach ($f in @($apk, $aab)) {
  $actual = Get-Sha256 (keytool -printcert -jarfile $f.FullName)
  if ($actual -ne $expected) { throw "REFUSED: $($f.Name) is not signed with the upload key.`n  expected $expected`n  got      $actual" }
}

Copy-Item $apk.FullName "$outDir/ronditrack-$name-$BuildNumber-staging.apk"
Copy-Item $aab.FullName "$outDir/ronditrack-$name-$BuildNumber-prod.aab"
"Release $name ($BuildNumber) is signed with the upload key. Files are in $outDir"