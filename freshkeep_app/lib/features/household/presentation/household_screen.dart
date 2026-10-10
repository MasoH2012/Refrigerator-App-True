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
    final profile = ref.watch(authProvider).value?.profile;
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
                    username: profile?.username ?? '',
                    uid: profile?.firebaseUid ?? '',
                    onSelect: () => ref
                        .read(householdProvider.notifier)
                        .switchTo(household.id),
                    onCopyCode: () => _copyInviteCode(context, household),
                    onCopyLink: () => _copyInviteLink(context, household),
                    onViewPassword: () =>
                        _viewPassword(context, ref, household),
                    onRename: () => _renameHousehold(context, ref, household),
                    onChangePassword: () =>
                        _changePassword(context, ref, household),
                    onDelete: () => _deleteHousehold(context, ref, household),
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
                title: Text('Private household sharing'),
                subtitle: Text(
                    'Share the invite code or link with someone you trust. They will also need the household password. Household data is synced through Firebase for authorized members.'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createHousehold(BuildContext context, WidgetRef ref) async {
    final credentials = await showDialog<_HouseholdCredentials>(
      context: context,
      builder: (_) => const _CreateHouseholdDialog(),
    );
    if (credentials == null || !context.mounted) return;
    final error = await ref
        .read(householdProvider.notifier)
        .create(credentials.name, credentials.password);
    if (error != null && context.mounted) _showError(context, error);
    if (error == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Household created. Save the password you entered; it cannot be displayed later.',
          ),
        ),
      );
    }
  }

  Future<void> _joinHousehold(BuildContext context, WidgetRef ref) async {
    final credentials = await showDialog<_HouseholdJoinCredentials>(
      context: context,
      builder: (_) => const _JoinHouseholdDialog(),
    );
    if (credentials == null || !context.mounted) return;
    final error = await ref
        .read(householdProvider.notifier)
        .join(credentials.code, credentials.password);
    if (error != null && context.mounted) _showError(context, error);
  }

  Future<void> _renameHousehold(
      BuildContext context, WidgetRef ref, Household household) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameHouseholdDialog(initialName: household.name),
    );
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

  Future<void> _changePassword(
      BuildContext context, WidgetRef ref, Household household) async {
    final credentials = await showDialog<_PasswordChangeCredentials>(
      context: context,
      builder: (_) => const _ChangeHouseholdPasswordDialog(),
    );
    if (credentials == null || !context.mounted) return;
    final error = await ref.read(householdProvider.notifier).changePassword(
          household.id,
          currentPassword: credentials.currentPassword,
          newPassword: credentials.newPassword,
        );
    if (error != null && context.mounted) _showError(context, error);
  }

  Future<void> _viewPassword(
      BuildContext context, WidgetRef ref, Household household) async {
    final password = await ref
        .read(householdProvider.notifier)
        .loadSavedPassword(household.id);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _SavedHouseholdPasswordDialog(password: password),
    );
  }

  Future<void> _deleteHousehold(
      BuildContext context, WidgetRef ref, Household household) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${household.name}?'),
        content: const Text(
          'This removes the household from everyone’s active list and stops sharing access. Existing cloud data is archived safely.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete household'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error =
        await ref.read(householdProvider.notifier).delete(household.id);
    if (error != null && context.mounted) _showError(context, error);
  }

  void _copyInviteCode(BuildContext context, Household household) {
    Clipboard.setData(ClipboardData(text: household.inviteCode));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Invite code copied.')));
  }

  void _copyInviteLink(BuildContext context, Household household) {
    Clipboard.setData(ClipboardData(text: household.inviteLink));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Invite link copied.')));
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
      required this.uid,
      required this.onSelect,
      required this.onCopyCode,
      required this.onCopyLink,
      required this.onViewPassword,
      required this.onRename,
      required this.onChangePassword,
      required this.onDelete,
      required this.onLeave});
  final Household household;
  final bool active;
  final String username;
  final String uid;
  final VoidCallback onSelect;
  final VoidCallback onCopyCode;
  final VoidCallback onCopyLink;
  final VoidCallback onViewPassword;
  final VoidCallback onRename;
  final VoidCallback onChangePassword;
  final VoidCallback onDelete;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final isOwner = household.ownerUid.isNotEmpty
        ? household.ownerUid == uid
        : household.ownerUsername.trim().toLowerCase() ==
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
                  label: const Text('Code')),
            ]),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 4),
              child: TextButton.icon(
                  onPressed: onCopyLink,
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('Copy invite link')),
            ),
          ),
          ListTile(
            dense: true,
            leading: Icon(Icons.lock_outline, size: 20),
            title: const Text('Saved password'),
            subtitle: Text('Stored securely on this device. Tap to view.'),
            trailing: const Icon(Icons.visibility_outlined, size: 20),
            onTap: onViewPassword,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'rename') onRename();
                if (value == 'password') onChangePassword();
                if (value == 'delete') onDelete();
                if (value == 'leave') onLeave();
              },
              itemBuilder: (context) => [
                if (isOwner) ...[
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                  const PopupMenuItem(
                      value: 'password', child: Text('Change password')),
                  const PopupMenuItem(
                      value: 'delete', child: Text('Delete household')),
                ],
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

class _HouseholdCredentials {
  const _HouseholdCredentials({required this.name, required this.password});

  final String name;
  final String password;
}

class _CreateHouseholdDialog extends StatefulWidget {
  const _CreateHouseholdDialog();

  @override
  State<_CreateHouseholdDialog> createState() => _CreateHouseholdDialogState();
}

class _CreateHouseholdDialogState extends State<_CreateHouseholdDialog> {
  final _name = TextEditingController(text: 'Our kitchen');
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Create household'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Household name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Household password',
                helperText:
                    'Use at least 4 characters. Save it somewhere safe.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = _name.text.trim();
              final password = _password.text.trim();
              if (name.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Enter a household name and a household password.',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(
                context,
                _HouseholdCredentials(name: name, password: password),
              );
            },
            child: const Text('Create'),
          ),
        ],
      );
}

class _JoinHouseholdDialog extends StatefulWidget {
  const _JoinHouseholdDialog();

  @override
  State<_JoinHouseholdDialog> createState() => _JoinHouseholdDialogState();
}

class _JoinHouseholdDialogState extends State<_JoinHouseholdDialog> {
  final _code = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Join a household'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _code,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Invite code',
                hintText: 'Example: FRESH7',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Household password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final code = _code.text.trim();
              final password = _password.text.trim();
              if (code.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Enter the invite code and household password.',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(
                context,
                _HouseholdJoinCredentials(code: code, password: password),
              );
            },
            child: const Text('Join'),
          ),
        ],
      );
}

class _RenameHouseholdDialog extends StatefulWidget {
  const _RenameHouseholdDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameHouseholdDialog> createState() => _RenameHouseholdDialogState();
}

class _RenameHouseholdDialogState extends State<_RenameHouseholdDialog> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Rename household'),
        content: TextField(controller: _name, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _name.text),
            child: const Text('Save'),
          ),
        ],
      );
}

class _PasswordChangeCredentials {
  const _PasswordChangeCredentials({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;
}

class _ChangeHouseholdPasswordDialog extends StatefulWidget {
  const _ChangeHouseholdPasswordDialog();

  @override
  State<_ChangeHouseholdPasswordDialog> createState() =>
      _ChangeHouseholdPasswordDialogState();
}

class _ChangeHouseholdPasswordDialogState
    extends State<_ChangeHouseholdPasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Change household password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Passwords are stored securely as hashes, so an existing password cannot be displayed. Enter it here to replace it.',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _current,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Current password'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _next,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  helperText: 'Use at least 4 characters',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirm,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirm new password'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final current = _current.text.trim();
              final next = _next.text.trim();
              if (current.length < 4 || next.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords must be at least 4 characters.'),
                  ),
                );
                return;
              }
              if (next != _confirm.text.trim()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New passwords do not match.')),
                );
                return;
              }
              Navigator.pop(
                context,
                _PasswordChangeCredentials(
                  currentPassword: current,
                  newPassword: next,
                ),
              );
            },
            child: const Text('Change password'),
          ),
        ],
      );
}

class _SavedHouseholdPasswordDialog extends StatefulWidget {
  const _SavedHouseholdPasswordDialog({required this.password});

  final String? password;

  @override
  State<_SavedHouseholdPasswordDialog> createState() =>
      _SavedHouseholdPasswordDialogState();
}

class _SavedHouseholdPasswordDialogState
    extends State<_SavedHouseholdPasswordDialog> {
  var _visible = false;

  @override
  Widget build(BuildContext context) {
    final password = widget.password;
    return AlertDialog(
      title: const Text('Household password'),
      content: password == null
          ? const Text(
              'This household password has not been saved on this device. You can save it the next time you join or change it.')
          : Row(
              children: [
                Expanded(
                  child: SelectableText(
                    _visible ? password : '•' * password.length,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: _visible ? 'Hide password' : 'Show password',
                  onPressed: () => setState(() => _visible = !_visible),
                  icon: Icon(_visible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _HouseholdJoinCredentials {
  const _HouseholdJoinCredentials({required this.code, required this.password});

  final String code;
  final String password;
}
