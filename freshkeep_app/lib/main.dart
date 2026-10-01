import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/storage_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // google-services.json configures Android. Flutter Web still has no Firebase
  // options file in this project, so only the web preview uses local storage.
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
    } catch (error, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      runApp(_StartupErrorApp(
        error:
            'Firebase could not initialize. Cloud persistence is unavailable.\n\n$error',
      ));
      return;
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
