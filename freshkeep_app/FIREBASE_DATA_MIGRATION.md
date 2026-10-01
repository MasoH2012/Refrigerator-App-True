# FreshKeep Firebase persistence

## Data model

The Android build is the Firebase-backed target because the repository includes
an Android `google-services.json`. The current web preview has no generated
Firebase web options, so it remains an explicitly local preview until a web
Firebase app is added; it does not silently claim cloud synchronization.

FreshKeep uses the authenticated Firebase UID as the private-data key:

- `users/{uid}` — profile fields written by `FirebaseAuthRepository`.
- `users/{uid}/inventory/{itemId}` — private inventory.
- `users/{uid}/shoppingList/{itemId}` — private shopping list.
- `users/{uid}/preferences/main` — notification, expiry-warning, dietary, and allergy settings.
- `users/{uid}/householdState/main` — the selected household ID.
- `users/{uid}/households/{householdId}` — a membership index used to list households.

Shared households use:

- `households/{householdId}` — name, invite code, owner UID, password hash, and creation time.
- `households/{householdId}/members/{uid}` — authoritative membership records.
- `households/{householdId}/inventory/{itemId}` — shared inventory.
- `households/{householdId}/shoppingList/{itemId}` — shared shopping list.
- `householdInvites/{inviteCode}` — authenticated-only join metadata containing the household ID and password hash. It contains no inventory or member data.

The member subcollection is authoritative for security. The user household
collection is only an index, so a stale index cannot grant access to a
household. Firestore rules require an actual member document for shared data.

## Migration behavior

On the first successful cloud read for a UID, each Firestore repository checks
for existing cloud data. Cloud data wins when it already exists. If the cloud
collection is empty, the repository uploads the corresponding legacy
SharedPreferences data, then writes a local migration marker. Local data is not
deleted. A failed cloud read or write is surfaced to the UI and never silently
falls back to local data.

Legacy household membership can only be migrated safely when the signed-in
username was the old household owner, because the old format did not contain
Firebase UIDs. Non-owner legacy household records are left untouched locally.

Recipe history is not currently exposed by the app, so no recipe documents are
written. The private `savedRecipes` rule is reserved for a future saved-recipe
repository.

## Manual verification checklist

1. On device A, create a Firebase account and select a refrigerator.
2. Add food items, including an expiry date and quantity.
3. Add shopping-list items and change preferences.
4. Create a household and record its invite code/password.
5. Sign out, then sign into the same account on device B.
6. Confirm the refrigerator, inventory, shopping list, and preferences appear.
7. Modify inventory or shopping data on device B and verify device A sees it after refresh.
8. Join the household from a second Firebase account using the invite code/password.
9. Confirm members share household inventory and shopping list, while private preferences remain separate.
10. Clear app data or reinstall, sign into the original account, and confirm cloud data remains.
11. Confirm a signed-out user cannot read private or household documents.

Run Flutter tests from the non-OneDrive checkout:

```cmd
cd /d "C:\Dev\freshkeep_app"
flutter test
```
