import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep_app/app.dart';
import 'package:freshkeep_app/core/providers/storage_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launch screen offers sign in and profile creation',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const FreshKeepApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create a new profile'), findsOneWidget);
    expect(find.text('Join a household'), findsOneWidget);

    await tester.tap(find.text('Create a new profile'));
    await tester.pumpAndSettle();

    expect(find.text('Set up FreshKeep'), findsOneWidget);
    expect(find.text('Create your profile'), findsOneWidget);
  });
}
