import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/presentation/app_data_gate.dart';
import '../application/auth_controller.dart';
import 'sign_in_screen.dart';

// Keep the former import path compatible while the screen lives in its own file.
export 'sign_in_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return auth.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(authProvider),
            child: const Text('Try again'),
          ),
        ),
      ),
      data: (session) {
        if (session.isAuthenticated) return const AppDataGate();
        return const SignInScreen();
      },
    );
  }
}
