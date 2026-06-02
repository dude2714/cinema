# Cinema

Standalone Cinema download repo.

## Files

- `Cinema.apk` - the downloadable APK
- `index.html` - landing page for GitHub Pages
- `Start Cinema.cmd` - local launcher for Windows
- `release.json` - current release metadata shown on the site
- `scripts/Publish-New-CinemaVersion.ps1` - helper script to publish a new APK version
- `scripts/Build-New-From-Apk.ps1` - helper script to rebuild/sign a new APK when only APK is available
- `APK-ONLY-WORKFLOW.md` - step-by-step guide for APK-only versioning

## New Version Flow

1. Build or obtain your new APK.
2. Run this command from the repo root:

	```powershell
	.\scripts\Publish-New-CinemaVersion.ps1 -NewApkPath "C:\path\to\new\Cinema.apk" -Version "v4.0.1" -Notes "New build"
	```

3. Commit and push the updated files:
	- `Cinema.apk`
	- `release.json`
	- `CHANGELOG.md`
4. GitHub Pages auto-deploys from the workflow.

## Publish

1. Push this folder to the `dude2714/cinema` GitHub repository.
2. In repo settings, set GitHub Pages source to GitHub Actions.
3. The workflow in `.github/workflows/pages.yml` will publish the site from the repo root.
4. Share the site URL and the direct APK URL:
	- Site: `https://dude2714.github.io/cinema/`
	- APK: `https://dude2714.github.io/cinema/Cinema.apk`
