# ClayLab - Project Instructions

## App Overview
iOS app (SwiftUI + SwiftData). Bundle ID: `com.claylab.app`
App Store Connect ID: `ASC_ID_HERE`. Team ID: `6G3Q27J6NB`

## Project Layout
- **Xcode project**: `ClayLab/`
- **Fastlane**: `ClayLab/fastlane/` (Appfile, Fastfile, metadata, screenshots, api_key.json)
- **Website**: `website/` (if applicable)
- **Screenshots**: `appstore_screenshots/`

## App Store Submissions
Use **fastlane** for all App Store tasks. Never use manual browser automation.
Always follow `~/Desktop/Apps/app-store-best-practices.md` for metadata, keywords, and submission strategy.

```bash
cd ClayLab
fastlane release    # build + upload metadata/screenshots + submit for review
fastlane submit     # upload existing IPA + submit (skip screenshots)
fastlane metadata   # upload metadata/screenshots only (no binary, no submit)
fastlane build      # just build the IPA
```

The ASC API key is already configured in `fastlane/api_key.json`.

## Key Details
- Category: CATEGORY_HERE
- Pricing: Free
- Privacy: No data collected
- Encryption: None

## User Preferences
- Maximize automation, minimize manual steps
- Account: Rick Anderson / support@claylab.app / Claya LLC
