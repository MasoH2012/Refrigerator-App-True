import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_controller.dart';
import '../../household/application/household_controller.dart';
import 'account_setup_screen.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  var _obscurePassword = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.kitchen_rounded,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Welcome to FreshKeep',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to an existing profile or create a new one.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _username,
                        autofillHints: const [AutofillHints.username],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _submit,
                        child: const Text('Sign in'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _createProfile,
                        icon: const Icon(Icons.person_add_outlined),
                        label: const Text('Create a new profile'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _joinHousehold,
                        icon: const Icon(Icons.group_add_outlined),
                        label: const Text('Join a household'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final error = await ref.read(authProvider.notifier).signIn(
          username: _username.text,
          password: _password.text,
        );
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _createProfile() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const AccountSetupScreen()),
    );
  }

  Future<void> _joinHousehold() async {
    if (!_formKey.currentState!.validate()) return;
    final credentials = await showDialog<_LoginJoinCredentials>(
      context: context,
      builder: (_) => const _LoginJoinHouseholdDialog(),
    );
    if (credentials == null) return;

    // Capture the notifiers before authentication changes AuthGate from this
    // screen to the signed-in app shell.
    final authController = ref.read(authProvider.notifier);
    final householdController = ref.read(householdProvider.notifier);
    final signInError = await authController.signIn(
      username: _username.text,
      password: _password.text,
    );
    if (signInError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(signInError)));
      }
      return;
    }
    final joinError = await householdController.join(
      credentials.code,
      credentials.password,
    );
    if (joinError != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(joinError)));
    }
  }
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required.' : null;

class _LoginJoinCredentials {
  const _LoginJoinCredentials({required this.code, required this.password});

  final String code;
  final String password;
}

class _LoginJoinHouseholdDialog extends StatefulWidget {
  const _LoginJoinHouseholdDialog();

  @override
  State<_LoginJoinHouseholdDialog> createState() =>
      _LoginJoinHouseholdDialogState();
}

class _LoginJoinHouseholdDialogState extends State<_LoginJoinHouseholdDialog> {
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter the invite code and household password. Your username and account password come from the sign-in form.',
            ),
            const SizedBox(height: 14),
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
              decoration:
                  const InputDecoration(labelText: 'Household password'),
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
                    content: Text('Enter the invite code and password.'),
                  ),
                );
                return;
              }
              Navigator.pop(
                context,
                _LoginJoinCredentials(code: code, password: password),
              );
            },
            child: const Text('Sign in and join'),
          ),
        ],
      );
}
