# Cinema APK-Only New Version Workflow

Use this when you only have an APK and want to publish a new version in this repo.

## What this does

- Decompiles the APK
- Bumps app version metadata (versionName and versionCode)
- Rebuilds APK
- Aligns and signs APK
- Lets you publish the rebuilt APK with the existing repo release flow

## Required tools

Install these and ensure each is available on PATH:

- java
- apktool
- zipalign
- apksigner
- keytool

## Build command

Run from repo root:

```powershell
.\scripts\Build-New-From-Apk.ps1 -InputApk ".\Cinema.apk" -VersionName "4.0.1" -VersionCode 40001 -OutputApk "Cinema-4.0.1.apk"
```

Notes:
- First run prompts for keystore password and certificate details.
- Keep the generated keystore safe. You need the same keystore for future updates.

## Publish command

After the new APK is built, publish it to the website repo flow:

```powershell
.\scripts\Publish-New-CinemaVersion.ps1 -NewApkPath ".\Cinema-4.0.1.apk" -Version "v4.0.1" -Notes "APK-only rebuild"
```

Then commit and push:

```powershell
git add Cinema.apk release.json CHANGELOG.md
git commit -m "Publish Cinema v4.0.1"
git push
```

## Important limits

- Without original source, deep bug fixes are limited.
- Version bump + rebuild works for packaging/release continuity.
- If runtime popup logic is hardcoded in app code, full removal usually needs original source.
