# Karberg Properties

## Notes
- Firebase project: karberg-properties-9f5a8
- Bundle ID (intended): de.karberg.properties

> Bundle ID confirmed in plist: `de.karberg.properties`

## Seed Firestore (sample data)

This repo includes a simple seeder script that creates:
- 2 properties
- 4 units (Flat + Room 1–3)
- 4 leases (with rent + dueDay=27)
- rent ledger entries for the current month
- lease codes (stored as Firestore doc IDs)

### Requirements
- Node.js 18+
- A Firebase **service account** with access to Firestore

### Run

1) Install deps:

```bash
npm install
```

2) Provide credentials either as a JSON string:

```bash
export FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
node scripts/seed-firestore.mjs
```

Or via file path (recommended):

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
node scripts/seed-firestore.mjs
```

The script prints the **lease codes** to share with tenants.

## GitHub Actions: compile/build (iOS Simulator)

Workflow: `.github/workflows/ios-build.yml`

What it does:
- runs on a macOS runner
- installs **XcodeGen**
- generates `KarbergProperties.xcodeproj` from `project.yml`
- builds the app for the **iPhone Simulator** with code signing disabled

To run it:
- push to `main` or open a PR; GitHub Actions will build automatically.

If you want **TestFlight / App Store** builds, we’ll add signing + fastlane next.
