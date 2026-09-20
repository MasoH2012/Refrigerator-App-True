import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/household.dart';
import '../application/household_controller.dart';
import '../../auth/application/auth_controller.dart';

class HouseholdScreen extends ConsumerWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdState = ref.watch(householdProvider);
    final username = ref.watch(authProvider).value?.profile?.username;
    return Scaffold(
      appBar: AppBar(title: const Text('Household sharing')),
      body: householdState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load households: $error')),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text('Share one fridge with the people you live with.',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text(
                'Everyone in a household sees the same food inventory and shopping list on their signed-in profile.'),
            const SizedBox(height: 20),
            if (data.households.isEmpty)
              _EmptyHouseholdCard(
                  onCreate: () => _createHousehold(context, ref),
                  onJoin: () => _joinHousehold(context, ref))
            else ...[
              ...data.households.map((household) => _HouseholdCard(
                    household: household,
                    active: household.id == data.activeHouseholdId,
                    username: username ?? '',
                    onSelect: () => ref
                        .read(householdProvider.notifier)
                        .switchTo(household.id),
                    onCopyCode: () => _copyInviteCode(context, household),
                    onRename: () => _renameHousehold(context, ref, household),
                    onLeave: () => _leaveHousehold(context, ref, household),
                  )),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                  onPressed: () => _joinHousehold(context, ref),
                  icon: const Icon(Icons.group_add_outlined),
                  label: const Text('Join another household')),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                  onPressed: () => _createHousehold(context, ref),
                  icon: const Icon(Icons.add_home_work_outlined),
                  label: const Text('Create a new household')),
            ],
            const SizedBox(height: 20),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const ListTile(
                leading: Icon(Icons.lock_outline),
                title: Text('Private on this device'),
                subtitle: Text(
                    'Invite codes work between profiles using this FreshKeep installation. Cloud syncing between devices can be connected when an account backend is added.'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createHousehold(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: 'Our kitchen');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create household'),
        content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Household name')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Create')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !context.mounted) return;
    final error = await ref.read(householdProvider.notifier).create(name);
    if (error != null && context.mounted) _showError(context, error);
  }

  Future<void> _joinHousehold(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join a household'),
        content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
                labelText: 'Invite code', hintText: 'Example: FRESH7')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Join')),
        ],
      ),
    );
    controller.dispose();
    if (code == null || !context.mounted) return;
    final error = await ref.read(householdProvider.notifier).join(code);
    if (error != null && context.mounted) _showError(context, error);
  }

  Future<void> _renameHousehold(
      BuildContext context, WidgetRef ref, Household household) async {
    final controller = TextEditingController(text: household.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename household'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !context.mounted) return;
    final error =
        await ref.read(householdProvider.notifier).rename(household.id, name);
    if (error != null && context.mounted) _showError(context, error);
  }

  Future<void> _leaveHousehold(
      BuildContext context, WidgetRef ref, Household household) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave ${household.name}?'),
        content: const Text(
            'You will no longer see this household’s inventory or shopping list.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Leave')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error =
        await ref.read(householdProvider.notifier).leave(household.id);
    if (error != null && context.mounted) _showError(context, error);
  }

  void _copyInviteCode(BuildContext context, Household household) {
    Clipboard.setData(ClipboardData(text: household.inviteCode));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Invite code copied.')));
  }

  void _showError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}

class _EmptyHouseholdCard extends StatelessWidget {
  const _EmptyHouseholdCard({required this.onCreate, required this.onJoin});
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.home_work_outlined, size: 48),
              const SizedBox(height: 12),
              const Text('No shared household yet',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text(
                  'Create one for your home or join a household with an invite code.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: FilledButton(
                        onPressed: onCreate, child: const Text('Create'))),
                const SizedBox(width: 10),
                Expanded(
                    child: OutlinedButton(
                        onPressed: onJoin, child: const Text('Join'))),
              ]),
            ],
          ),
        ),
      );
}

class _HouseholdCard extends StatelessWidget {
  const _HouseholdCard(
      {required this.household,
      required this.active,
      required this.username,
      required this.onSelect,
      required this.onCopyCode,
      required this.onRename,
      required this.onLeave});
  final Household household;
  final bool active;
  final String username;
  final VoidCallback onSelect;
  final VoidCallback onCopyCode;
  final VoidCallback onRename;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final isOwner = household.ownerUsername.trim().toLowerCase() ==
        username.trim().toLowerCase();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
                child: Icon(active ? Icons.home : Icons.home_outlined)),
            title: Text(household.name),
            subtitle: Text(
                '${household.members.length} member${household.members.length == 1 ? '' : 's'}'),
            trailing: active
                ? const Chip(label: Text('Active'))
                : TextButton(onPressed: onSelect, child: const Text('Use')),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(children: [
              const Icon(Icons.key_outlined, size: 20),
              const SizedBox(width: 10),
              Text(household.inviteCode,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      letterSpacing: 2, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton.icon(
                  onPressed: onCopyCode,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy')),
            ]),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'rename') onRename();
                if (value == 'leave') onLeave();
              },
              itemBuilder: (context) => [
                if (isOwner)
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                if (!isOwner)
                  const PopupMenuItem(
                      value: 'leave', child: Text('Leave household')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
