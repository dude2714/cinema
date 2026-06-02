param(
    [string]$InputApk = "Cinema.apk",
    [Parameter(Mandatory = $true)]
    [string]$VersionName,
    [Parameter(Mandatory = $true)]
    [int]$VersionCode,
    [string]$WorkDir = "apk-work",
    [string]$OutputApk = "Cinema-new-release.apk"
)

$ErrorActionPreference = "Stop"

function Resolve-Tool {
    param(
        [string]$Name,
        [string]$FallbackPath
    )

    $tool = Get-Command $Name -ErrorAction SilentlyContinue
    if ($tool) {
        return $tool.Source
    }

    if (Test-Path -LiteralPath $FallbackPath) {
        return $FallbackPath
    }

    throw "Missing required tool: $Name"
}

if (-not (Test-Path -LiteralPath $InputApk)) {
    throw "Input APK not found: $InputApk"
}

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$scoopApps = Join-Path $env:USERPROFILE "scoop\\apps"
$javaExe = Resolve-Tool -Name "java" -FallbackPath (Join-Path $scoopApps "temurin17-jdk\\current\\bin\\java.exe")
$apktoolJar = Join-Path $scoopApps "apktool\\current\\apktool.jar"
if (-not (Test-Path -LiteralPath $apktoolJar)) {
    throw "Missing required apktool jar: $apktoolJar"
}

$absWorkDir = Join-Path $root $WorkDir
$decodedDir = Join-Path $absWorkDir "decoded"
$unsignedApk = Join-Path $absWorkDir "unsigned.apk"
$signedApk = Join-Path $root $OutputApk
$toolsDir = Join-Path $root ".tools"
$uberJar = Join-Path $toolsDir "uber-apk-signer-1.3.0.jar"

if (Test-Path -LiteralPath $absWorkDir) {
    Remove-Item -LiteralPath $absWorkDir -Recurse -Force
}
New-Item -ItemType Directory -Path $absWorkDir | Out-Null

if (-not (Test-Path -LiteralPath $toolsDir)) {
    New-Item -ItemType Directory -Path $toolsDir | Out-Null
}

if (-not (Test-Path -LiteralPath $uberJar)) {
    $uberUrl = "https://github.com/patrickfav/uber-apk-signer/releases/download/v1.3.0/uber-apk-signer-1.3.0.jar"
    Write-Host "Downloading uber-apk-signer..."
    Invoke-WebRequest -Uri $uberUrl -OutFile $uberJar
}

Write-Host "[1/5] Decoding APK"
& $javaExe -jar "$apktoolJar" d -f "$InputApk" -o "$decodedDir"

$manifestPath = Join-Path $decodedDir "AndroidManifest.xml"
if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "AndroidManifest.xml not found in decoded APK"
}

Write-Host "[2/5] Updating version metadata"
$manifest = Get-Content -LiteralPath $manifestPath -Raw
$manifest = [regex]::Replace($manifest, 'android:versionName="[^"]*"', "android:versionName=`"$VersionName`"")
$manifest = [regex]::Replace($manifest, 'android:versionCode="[0-9]+"', "android:versionCode=`"$VersionCode`"")
Set-Content -LiteralPath $manifestPath -Value $manifest -Encoding utf8

Write-Host "[3/5] Building unsigned APK"
& $javaExe -jar "$apktoolJar" b "$decodedDir" -o "$unsignedApk"

if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $unsignedApk)) {
    throw "Unsigned APK build failed"
}

Write-Host "[4/5] Signing APK"
$signOutDir = Join-Path $absWorkDir "signed"
New-Item -ItemType Directory -Path $signOutDir -Force | Out-Null
& $javaExe -jar "$uberJar" -a "$unsignedApk" -o "$signOutDir" --allowResign | Out-Host

$signedCandidates = Get-ChildItem -LiteralPath $signOutDir -File -Filter "*.apk" | Sort-Object LastWriteTime -Descending
if (-not $signedCandidates -or $signedCandidates.Count -eq 0) {
    throw "Signed APK output was not generated"
}

Write-Host "[5/5] Finalizing output"
Copy-Item -LiteralPath $signedCandidates[0].FullName -Destination "$signedApk" -Force

Write-Host "Done: $signedApk"
