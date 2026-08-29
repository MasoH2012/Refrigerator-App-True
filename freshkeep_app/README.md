# FreshKeep

FreshKeep is a Flutter application for refrigerator inventory, expiration alerts,
recipe suggestions, and food-safe refrigerator organization.

## Architecture

- Feature-first presentation under `lib/features`.
- Immutable domain models under `lib/domain`.
- Repository abstraction with a SharedPreferences implementation under `lib/data`.
- Riverpod for dependency injection and state management.
- GoRouter for typed, declarative navigation.
- Material 3 design with adaptive safe areas and accessible semantics.
- First-run account onboarding for username, password, refrigerator, and initial inventory.
- Returning-user sign-in and sign-out with a salted local password verifier.

## First-run flow

FreshKeep always opens on a shared account entry screen where users can sign in
to an existing profile or create a new one. Profile creation requires a unique
username, password, refrigerator brand/model, and at least one food item with an
expiration date. Multiple profiles are supported on one device, and each keeps
an independent refrigerator inventory. A cold launch or explicit sign-out
requires authentication again. The password itself is never stored.

Refrigerator selection uses an alphabetized, searchable catalog of verified
real-world models. Users must select a catalog entry; arbitrary free text is
not accepted. Each record includes its documented layout, shelf, crisper,
pantry, door-bin, and freezer structure, which drives the model-specific
diagram in the Organize tab.

## Run

```sh
flutter pub get
flutter run
```

To generate native platform runners when cloning only the source package:

```sh
flutter create --platforms=android,ios,web,windows .
```

## Quality checks

```sh
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

Camera recognition and OS notifications are exposed as service boundaries so
production plugins or backend APIs can be integrated without changing UI code.

## AI recipe suggestions

The Recipes tab requests a fresh set of AI-created or web-discovered recipes
from the current, non-expired refrigerator inventory. It does not substitute a
small static recipe catalog when AI is unavailable. Every response uses a
structured contract, and FreshKeep validates each claimed fridge ingredient
against the local inventory before displaying it. Must-use, vegetarian, time,
fridge-only, and avoided-ingredient filters are enforced again in the app rather
than trusted to the model alone.

The reference server is in `server/recipe_suggestions_server.mjs`; setup details
are in `server/README.md`. The OpenAI key belongs only on that server and must
never be compiled into Flutter.
