import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:freshkeep_app/data/repositories/household_repository.dart';

void main() {
  test('creates a household and joins it with an invite code', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = PreferencesHouseholdRepository(preferences);

    final created = await repository.create(
      uid: 'uid-alex',
      username: 'Alex',
      name: 'Alex home',
      password: 'secret',
    );
    expect(created.members, ['Alex']);
    expect(created.inviteCode, hasLength(6));
    expect(await repository.loadActiveId('uid-alex'), created.id);

    final joined = await repository.join(
      username: 'Sam',
      uid: 'uid-sam',
      inviteCode: created.inviteCode,
      password: 'secret',
    );
    expect(joined.id, created.id);
    expect(joined.members, containsAll(<String>['Alex', 'Sam']));
    expect(await repository.loadActiveId('uid-sam'), created.id);
    expect(
        (await repository.loadForUser(uid: 'uid-sam', username: 'Sam'))
            .single
            .id,
        created.id);
  });

  test('prevents the owner from leaving a household', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = PreferencesHouseholdRepository(preferences);
    final household = await repository.create(
      uid: 'uid-alex',
      username: 'Alex',
      name: 'Alex home',
      password: 'secret',
    );

    expect(
      () => repository.leave(
        uid: 'uid-alex',
        username: 'Alex',
        householdId: household.id,
      ),
      throwsA(isA<HouseholdException>()),
    );
  });

  test('allows the owner to change the password and delete a household',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = PreferencesHouseholdRepository(preferences);
    final household = await repository.create(
      uid: 'uid-alex',
      username: 'Alex',
      name: 'Alex home',
      password: 'secret',
    );

    await repository.changePassword(
      uid: 'uid-alex',
      username: 'Alex',
      householdId: household.id,
      currentPassword: 'secret',
      newPassword: 'new-secret',
    );
    await repository.join(
      uid: 'uid-sam',
      username: 'Sam',
      inviteCode: household.inviteCode,
      password: 'new-secret',
    );

    await repository.delete(
      uid: 'uid-alex',
      username: 'Alex',
      householdId: household.id,
    );
    expect(await repository.loadActiveId('uid-alex'), isNull);
    expect(
      await repository.loadForUser(uid: 'uid-alex', username: 'Alex'),
      isEmpty,
    );
  });
}
