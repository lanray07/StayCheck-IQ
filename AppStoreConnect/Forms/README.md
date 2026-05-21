# Filled App Store Connect Forms

These files capture the App Store Connect form answers for StayCheck IQ.

## Completed Drafts

- `app-review-information.json`
- `age-rating.json`
- `export-compliance.json`
- `content-rights.json`
- `pricing-and-availability.json`
- `app-privacy-answers.json`
- `version-release.json`

## Remaining Private Values

The only required values not safely filled by Codex are listed in `remaining-required-private-values.json`.

Most importantly, App Review requires a real phone number. Replace:

```json
"contactPhone": "REQUIRED_REAL_PHONE_NUMBER"
```

in `app-review-information.json` before submission.

## GitHub Actions

- `.github/workflows/ios-xcodebuild.yml` runs the Xcode simulator build on GitHub-hosted macOS.
- The `gh-pages` branch publishes the support/privacy/terms pages from `docs/`.
- `.github/workflows/appstore-metadata.yml` can upload metadata with fastlane after App Store Connect API secrets are added.
