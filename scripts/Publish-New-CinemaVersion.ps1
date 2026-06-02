param(
    [Parameter(Mandatory = $true)]
    [string]$NewApkPath,

    [Parameter(Mandatory = $true)]
    [string]$Version,

    [string]$Notes = ""
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$targetApk = Join-Path $repoRoot 'Cinema.apk'
$releaseFile = Join-Path $repoRoot 'release.json'
$changelogFile = Join-Path $repoRoot 'CHANGELOG.md'

if (-not (Test-Path -LiteralPath $NewApkPath)) {
    throw "New APK not found: $NewApkPath"
}

Copy-Item -LiteralPath $NewApkPath -Destination $targetApk -Force

$apk = Get-Item -LiteralPath $targetApk
$sha = (Get-FileHash -LiteralPath $targetApk -Algorithm SHA256).Hash
$updatedUtc = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

$release = [ordered]@{
    version = $Version
    updatedUtc = $updatedUtc
    apkFile = 'Cinema.apk'
    sizeBytes = [int64]$apk.Length
    sha256 = $sha
    notes = $Notes
}

$release | ConvertTo-Json | Set-Content -LiteralPath $releaseFile -Encoding utf8

if (-not (Test-Path -LiteralPath $changelogFile)) {
    "# Changelog`r`n" | Set-Content -LiteralPath $changelogFile -Encoding utf8
}

$entry = @(
    "## $Version - $updatedUtc"
    "- APK: Cinema.apk"
    "- Size: $($apk.Length) bytes"
    "- SHA-256: $sha"
)

if ($Notes.Trim()) {
    $entry += "- Notes: $Notes"
}

$existing = Get-Content -LiteralPath $changelogFile -Raw
$header = "# Changelog`r`n"
if ($existing.StartsWith($header)) {
    $body = $existing.Substring($header.Length).TrimStart("`r", "`n")
    $newContent = $header + "`r`n" + ($entry -join "`r`n") + "`r`n`r`n" + $body + "`r`n"
} else {
    $newContent = "# Changelog`r`n`r`n" + ($entry -join "`r`n") + "`r`n"
}

Set-Content -LiteralPath $changelogFile -Value $newContent -Encoding utf8

Write-Host "Updated Cinema release"
Write-Host "- Version: $Version"
Write-Host "- APK: $targetApk"
Write-Host "- SHA-256: $sha"
Write-Host "- release.json updated"
Write-Host "- CHANGELOG.md updated"
