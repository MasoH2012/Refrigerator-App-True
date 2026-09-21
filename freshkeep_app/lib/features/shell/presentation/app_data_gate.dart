import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/freshkeep_data_service.dart';
import 'app_shell.dart';

class AppDataGate extends ConsumerWidget {
  const AppDataGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(freshKeepDataProvider);
    return data.when(
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your FreshKeep data…'),
            ],
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 52,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  'We couldn’t load your FreshKeep data.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(freshKeepDataProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (_) => const AppShell(),
    );
  }
}
