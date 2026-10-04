import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/refrigerator_model.dart';
import '../../../domain/models/app_preferences.dart';
import '../../../domain/models/data_scope.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../recipes/application/recipe_suggestions_controller.dart';
import '../../household/application/household_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  var _notifications = true;
  var _warningDays = 3;
  var _dietaryPreference = 'No preference';
  var _allergies = 'None added';
  String? _settingsUsername;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).value?.profile;
    final refrigerator = profile == null
        ? null
        : RefrigeratorCatalog.byId(profile.refrigeratorModel);
    final household = ref.watch(householdProvider).value?.active;
    if (profile != null && _settingsUsername != profile.username) {
      _settingsUsername = profile.username;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _loadSettings(profile.username));
    }
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
            refrigerator?.shortName ?? profile?.refrigeratorModel ?? '',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text('Preferences', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: _notifications,
                  onChanged: _setNotifications,
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Expiry notifications'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Warn me before'),
                  subtitle: Text('$_warningDays days before expiration'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _chooseWarningDays,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.eco_outlined),
                  title: const Text('Dietary preferences'),
                  subtitle: Text(_dietaryPreference),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _chooseDietaryPreference,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.block_outlined),
                  title: const Text('Allergies & dislikes'),
                  subtitle: Text(_allergies),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _editAllergies,
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
                  subtitle: Text(
                    refrigerator?.displayName ??
                        profile?.refrigeratorModel ??
                        '',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showRefrigeratorDetails,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.home_work_outlined),
                  title: const Text('Household sharing'),
                  subtitle: Text(
                    household == null
                        ? 'Create or join a shared fridge'
                        : '${household.name} · ${household.members.length} member${household.members.length == 1 ? '' : 's'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/household'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Privacy & data'),
                  subtitle:
                      const Text('Synced securely with your Firebase account'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showPrivacyDetails,
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

  Future<void> _chooseWarningDays() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (_) => _WarningDaysDialog(initialDays: _warningDays),
    );
    if (selected != null && mounted) {
      setState(() => _warningDays = selected);
      await _saveSettings();
    }
  }

  Future<void> _chooseDietaryPreference() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Dietary preferences'),
        children: ['No preference', 'Vegetarian', 'Vegan', 'Pescatarian']
            .map((preference) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, preference),
                  child: Text(preference),
                ))
            .toList(),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _dietaryPreference = selected);
      await _saveSettings();
    }
  }

  Future<void> _editAllergies() async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _AllergiesDialog(
        initialValue: _allergies == 'None added' ? '' : _allergies,
      ),
    );
    if (value != null && mounted) {
      setState(() => _allergies = value.isEmpty ? 'None added' : value);
      await _saveSettings();
    }
  }

  Future<void> _showRefrigeratorDetails() async {
    final profile = ref.read(authProvider).value?.profile;
    final selected = await showDialog<RefrigeratorModel>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose your refrigerator'),
        children: RefrigeratorCatalog.models
            .map(
              (model) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, model),
                child: Text(model.displayName),
              ),
            )
            .toList(),
      ),
    );
    if (selected == null || profile == null || !mounted) return;
    final error = await ref
        .read(authProvider.notifier)
        .updateRefrigeratorModel(selected.id);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Refrigerator changed to ${selected.shortName}.')),
      );
    }
  }

  void _showPrivacyDetails() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.shield_outlined),
        title: const Text('Privacy & data'),
        content: const Text(
          'FreshKeep syncs your profile, refrigerator inventory, shopping list, preferences, and household data with your Firebase account. Recipe requests use only the ingredients needed to generate suggestions.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _setNotifications(bool enabled) {
    setState(() => _notifications = enabled);
    _saveSettings();
  }

  Future<void> _loadSettings(String username) async {
    final profile = ref.read(authProvider).value?.profile;
    if (profile == null) return;
    final settings = await ref
        .read(userPreferencesRepositoryProvider)
        .load(privateScopeForProfile(profile));
    if (!mounted) return;
    setState(() {
      _notifications = settings.notificationsEnabled;
      _warningDays = settings.warningDays;
      _dietaryPreference = settings.dietaryPreference;
      _allergies = settings.allergies.isEmpty
          ? 'None added'
          : settings.allergies.join(', ');
    });
  }

  Future<void> _saveSettings() async {
    final username = ref.read(authProvider).value?.profile?.username;
    if (username == null) return;
    final allergies = _allergies == 'None added'
        ? const <String>[]
        : _allergies
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList();
    final profile = ref.read(authProvider).value?.profile;
    if (profile == null) return;
    await ref.read(userPreferencesRepositoryProvider).save(
          privateScopeForProfile(profile),
          AppPreferences(
            notificationsEnabled: _notifications,
            warningDays: _warningDays,
            dietaryPreference: _dietaryPreference,
            allergies: allergies,
          ),
        );
    ref.invalidate(recipeSuggestionsProvider);
  }
}

class _WarningDaysDialog extends StatefulWidget {
  const _WarningDaysDialog({required this.initialDays});

  final int initialDays;

  @override
  State<_WarningDaysDialog> createState() => _WarningDaysDialogState();
}

class _WarningDaysDialogState extends State<_WarningDaysDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initialDays}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Warn me before expiration'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Days before expiration',
            helperText: 'Enter any whole number from 0 onward.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final days = int.tryParse(_controller.text.trim());
              if (days == null || days < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a whole number of 0 or more.'),
                  ),
                );
                return;
              }
              Navigator.pop(context, days);
            },
            child: const Text('Save'),
          ),
        ],
      );
}

class _AllergiesDialog extends StatefulWidget {
  const _AllergiesDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_AllergiesDialog> createState() => _AllergiesDialogState();
}

class _AllergiesDialogState extends State<_AllergiesDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Allergies & dislikes'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Example: peanuts, shellfish',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      );
}
