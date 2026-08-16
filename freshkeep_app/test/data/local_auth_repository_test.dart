import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep_app/data/repositories/local_auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalAuthRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = LocalAuthRepository(await SharedPreferences.getInstance());
  });

  test('registers a profile but requires sign-in on the next launch', () async {
    final profile = await repository.register(
      username: 'Mason',
      password: 'Fresh123',
      refrigeratorModel: 'Samsung RF28',
    );
    final session = await repository.restoreSession();

    expect(profile.username, 'Mason');
    expect(session.isAuthenticated, isFalse);
    expect(session.profile, isNull);
    expect(session.hasProfiles, isTrue);
  });

  test('rejects an incorrect password and accepts the correct password',
      () async {
    await repository.register(
      username: 'Mason',
      password: 'Fresh123',
      refrigeratorModel: 'Samsung RF28',
    );
    await repository.signOut();

    expect(
      await repository.signIn(username: 'Mason', password: 'wrong'),
      isNull,
    );
    expect(
      await repository.signIn(username: 'mason', password: 'Fresh123'),
      isNotNull,
    );
  });

  test('supports multiple profiles with independent credentials', () async {
    await repository.register(
      username: 'Mason',
      password: 'Fresh123',
      refrigeratorModel: 'Samsung RF28',
    );
    await repository.register(
      username: 'Alex',
      password: 'Cold4567',
      refrigeratorModel: 'LG InstaView',
    );

    final mason = await repository.signIn(
      username: 'Mason',
      password: 'Fresh123',
    );
    final alex = await repository.signIn(
      username: 'Alex',
      password: 'Cold4567',
    );

    expect(mason?.refrigeratorModel, 'Samsung RF28');
    expect(alex?.refrigeratorModel, 'LG InstaView');
  });

  test('rejects a duplicate username without replacing the profile', () async {
    await repository.register(
      username: 'Mason',
      password: 'Fresh123',
      refrigeratorModel: 'Samsung RF28',
    );

    await expectLater(
      repository.register(
        username: 'mason',
        password: 'Other123',
        refrigeratorModel: 'Other fridge',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
