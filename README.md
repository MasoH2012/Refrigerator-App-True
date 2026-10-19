# FreshKeep

FreshKeep is a Flutter app for tracking food inventory, expiration dates, household sharing, refrigerator organization, shopping lists, and recipe ideas.

## Project layout

- `freshkeep_app/` — the final Flutter application.
- `freshkeep-prototype/` — the earlier high-fidelity HTML prototype.

## Run the Flutter app

From the project folder:

```cmd
cd freshkeep_app
flutter pub get
flutter run
```

The Android Firebase configuration is already included at `freshkeep_app/android/app/google-services.json`.

## Quality checks

```cmd
cd freshkeep_app
dart format lib test
flutter analyze
flutter test
```

Generated build output, dependency caches, IDE metadata, and local tooling files are intentionally ignored by Git.
