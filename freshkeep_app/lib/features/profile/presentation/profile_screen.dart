import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../inventory/application/inventory_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  var _notifications = true;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).valueOrNull?.profile;
    final itemCount = ref.watch(inventoryProvider).valueOrNull?.length ?? 0;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        children: [
          CircleAvatar(
            radius: 44,
            child: Text(
              profile?.initials ?? '?',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            profile?.username ?? 'FreshKeep user',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            profile?.refrigeratorModel ?? '',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _Stat(value: '$itemCount', label: 'Items tracked')),
              const SizedBox(width: 8),
              const Expanded(child: _Stat(value: '8', label: 'Meals saved')),
              const SizedBox(width: 8),
              const Expanded(
                  child: _Stat(value: '3.4 lb', label: 'Waste avoided')),
            ],
          ),
          const SizedBox(height: 24),
          Text('Preferences', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: _notifications,
                  onChanged: (value) => setState(() => _notifications = value),
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Expiry notifications'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.calendar_today_outlined),
                  title: Text('Warn me before'),
                  trailing: Text('3 days'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.eco_outlined),
                  title: Text('Dietary preferences'),
                  trailing: Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.block_outlined),
                  title: Text('Allergies & dislikes'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Account', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.kitchen_outlined),
                  title: const Text('Refrigerator'),
                  subtitle: Text(profile?.refrigeratorModel ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.shield_outlined),
                  title: Text('Privacy & data'),
                  trailing: Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.logout,
                      color: Theme.of(context).colorScheme.error),
                  title: Text('Sign out',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  onTap: _confirmSignOut,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            'Your refrigerator and food items will remain on this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed == true) await ref.read(authProvider.notifier).signOut();
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          child: Column(
            children: [
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              Text(label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
}
