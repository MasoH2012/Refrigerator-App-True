import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:freshkeep_app/data/repositories/household_repository.dart';

void main() {
  test('creates a household and joins it with an invite code', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = HouseholdRepository(preferences);

    final created =
        await repository.create(username: 'Alex', name: 'Alex home');
    expect(created.members, ['Alex']);
    expect(created.inviteCode, hasLength(6));
    expect(repository.loadActiveId('Alex'), created.id);

    final joined = await repository.join(
      username: 'Sam',
      inviteCode: created.inviteCode,
    );
    expect(joined.id, created.id);
    expect(joined.members, containsAll(<String>['Alex', 'Sam']));
    expect(repository.loadActiveId('Sam'), created.id);
    expect(repository.loadForUser('Sam').single.id, created.id);
  });

  test('prevents the owner from leaving a household', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = HouseholdRepository(preferences);
    final household =
        await repository.create(username: 'Alex', name: 'Alex home');

    expect(
      () => repository.leave(username: 'Alex', householdId: household.id),
      throwsA(isA<HouseholdException>()),
    );
  });
}
