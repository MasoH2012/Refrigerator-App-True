import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/storage_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // google-services.json configures Android. Flutter Web needs a separate
  // Firebase Web app/options file, so keep the web preview usable with the
  // local repository until that configuration is added.
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
    } catch (error, stackTrace) {
      debugPrint('Firebase initialization failed; using local storage: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  late final SharedPreferences preferences;
  try {
    preferences = await SharedPreferences.getInstance();
  } catch (error, stackTrace) {
    debugPrint('Unable to load local storage: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(_StartupErrorApp(error: error));
    return;
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const FreshKeepApp(),
    ),
  );
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'FreshKeep could not start.\n\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
