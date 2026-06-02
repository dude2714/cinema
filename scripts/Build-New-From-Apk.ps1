param(
    [string]$InputApk = "Cinema.apk",
    [Parameter(Mandatory = $true)]
    [string]$VersionName,
    [Parameter(Mandatory = $true)]
    [int]$VersionCode,
    [string]$WorkDir = "apk-work",
    [string]$KeystorePath = ".\apk-work\cinema-release.jks",
    [string]$KeystoreAlias = "cinema",
    [string]$OutputApk = "Cinema-new-release.apk"
)

$ErrorActionPreference = "Stop"

function Require-Tool {
    param([string]$Name)
    $tool = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $tool) {
        throw "Missing required tool: $Name"
    }
}

Require-Tool "apktool"
Require-Tool "keytool"
Require-Tool "zipalign"
Require-Tool "apksigner"

if (-not (Test-Path -LiteralPath $InputApk)) {
    throw "Input APK not found: $InputApk"
}

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$absWorkDir = Join-Path $root $WorkDir
$decodedDir = Join-Path $absWorkDir "decoded"
$unsignedApk = Join-Path $absWorkDir "unsigned.apk"
$alignedApk = Join-Path $absWorkDir "aligned.apk"
$signedApk = Join-Path $root $OutputApk

if (Test-Path -LiteralPath $absWorkDir) {
    Remove-Item -LiteralPath $absWorkDir -Recurse -Force
}
New-Item -ItemType Directory -Path $absWorkDir | Out-Null

Write-Host "[1/6] Decoding APK"
apktool d -f "$InputApk" -o "$decodedDir"

$manifestPath = Join-Path $decodedDir "AndroidManifest.xml"
if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "AndroidManifest.xml not found in decoded APK"
}

Write-Host "[2/6] Updating version metadata"
$manifest = Get-Content -LiteralPath $manifestPath -Raw
$manifest = [regex]::Replace($manifest, 'android:versionName="[^"]*"', "android:versionName=\"$VersionName\"")
$manifest = [regex]::Replace($manifest, 'android:versionCode="[0-9]+"', "android:versionCode=\"$VersionCode\"")
Set-Content -LiteralPath $manifestPath -Value $manifest -Encoding utf8

Write-Host "[3/6] Building unsigned APK"
apktool b "$decodedDir" -o "$unsignedApk"

if (-not (Test-Path -LiteralPath $KeystorePath)) {
    Write-Host "[4/6] Creating new keystore at $KeystorePath"
    $ksDir = Split-Path -Parent $KeystorePath
    if (-not (Test-Path -LiteralPath $ksDir)) {
        New-Item -ItemType Directory -Path $ksDir | Out-Null
    }

    keytool -genkeypair -v -keystore "$KeystorePath" -alias "$KeystoreAlias" -keyalg RSA -keysize 2048 -validity 10000
}

Write-Host "[5/6] Zipalign"
zipalign -f 4 "$unsignedApk" "$alignedApk"

Write-Host "[6/6] Signing APK"
Copy-Item -LiteralPath "$alignedApk" -Destination "$signedApk" -Force
apksigner sign --ks "$KeystorePath" --ks-key-alias "$KeystoreAlias" "$signedApk"
apksigner verify "$signedApk"

Write-Host "Done: $signedApk"
