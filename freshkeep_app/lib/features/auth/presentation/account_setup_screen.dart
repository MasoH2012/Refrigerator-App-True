import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/food_item.dart';
import '../application/auth_controller.dart';

class AccountSetupScreen extends ConsumerStatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  ConsumerState<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends ConsumerState<AccountSetupScreen> {
  final _accountKey = GlobalKey<FormState>();
  final _fridgeKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _refrigerator = TextEditingController();
  final _items = <FoodItem>[];
  var _step = 0;
  var _obscurePassword = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirmation.dispose();
    _refrigerator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Set up FreshKeep'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                    child: Column(
                      children: [
                        LinearProgressIndicator(value: (_step + 1) / 3),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Step ${_step + 1} of 3'),
                            Text([
                              'Your profile',
                              'Your refrigerator',
                              'Your food'
                            ][_step]),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: switch (_step) {
                        0 => _accountStep(context),
                        1 => _refrigeratorStep(context),
                        _ => _foodStep(context),
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        if (_step > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() => _step--),
                              child: const Text('Back'),
                            ),
                          ),
                        if (_step > 0) const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _continue,
                            child: Text(
                                _step == 2 ? 'Create profile' : 'Continue'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _accountStep(BuildContext context) => ListView(
        key: const ValueKey('account'),
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.person_add_alt_1,
              size: 58, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 18),
          Text('Create your profile',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
              'Your account stays signed in on this device until you sign out.',
              textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Form(
            key: _accountKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _username,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newUsername],
                  decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline)),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.length < 3) return 'Use at least 3 characters.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    helperText:
                        'At least 8 characters, with a letter and number.',
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmation,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: Icon(Icons.lock_reset_outlined)),
                  validator: (value) => value != _password.text
                      ? 'Passwords do not match.'
                      : null,
                ),
              ],
            ),
          ),
        ],
      );

  Widget _refrigeratorStep(BuildContext context) => ListView(
        key: const ValueKey('refrigerator'),
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.kitchen_outlined,
              size: 58, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 18),
          Text('Which refrigerator do you use?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
              'This helps FreshKeep recommend the right shelf and drawer for every item.',
              textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Form(
            key: _fridgeKey,
            child: TextFormField(
              controller: _refrigerator,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Brand and model',
                hintText: 'Example: Samsung RF28T5001SR',
                prefixIcon: Icon(Icons.kitchen),
              ),
              validator: (value) => value == null || value.trim().length < 3
                  ? 'Enter your refrigerator brand or model.'
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text('Popular examples',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Samsung French Door',
              'LG InstaView',
              'Whirlpool Side-by-Side'
            ]
                .map((model) => ActionChip(
                    label: Text(model),
                    onPressed: () =>
                        setState(() => _refrigerator.text = model)))
                .toList(),
          ),
        ],
      );

  Widget _foodStep(BuildContext context) => ListView(
        key: const ValueKey('food'),
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.shopping_basket_outlined,
              size: 58, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 18),
          Text('Add food from your refrigerator',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
              'Add at least one item so your inventory and expiration alerts start ready to use.',
              textAlign: TextAlign.center),
          const SizedBox(height: 22),
          OutlinedButton.icon(
              onPressed: _showAddFoodDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add food item')),
          const SizedBox(height: 14),
          if (_items.isEmpty)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('At least one food item is required.')),
            )
          else
            ..._items.map((item) => Card(
                  child: ListTile(
                    leading:
                        const CircleAvatar(child: Icon(Icons.eco_outlined)),
                    title: Text(item.name),
                    subtitle: Text(
                        '${item.quantity} · expires ${DateFormat.yMMMd().format(item.expirationDate)}'),
                    trailing: IconButton(
                        onPressed: () => setState(() => _items.remove(item)),
                        icon: const Icon(Icons.close),
                        tooltip: 'Remove ${item.name}'),
                  ),
                )),
        ],
      );

  Future<void> _continue() async {
    if (_step == 0 && !_accountKey.currentState!.validate()) return;
    if (_step == 1 && !_fridgeKey.currentState!.validate()) return;
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Add at least one food item to continue.')));
      return;
    }
    final error = await ref.read(authProvider.notifier).register(
          username: _username.text,
          password: _password.text,
          refrigeratorModel: _refrigerator.text,
          initialItems: _items,
        );
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showAddFoodDialog() async {
    final item = await showDialog<FoodItem>(
        context: context, builder: (context) => const _AddFoodDialog());
    if (item != null) setState(() => _items.add(item));
  }
}

class _AddFoodDialog extends StatefulWidget {
  const _AddFoodDialog();
  @override
  State<_AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<_AddFoodDialog> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _quantity = TextEditingController(text: '1 item');
  var _category = FoodCategory.produce;
  var _expiration = DateTime.now().add(const Duration(days: 5));

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add food item'),
        content: Form(
          key: _key,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                    controller: _name,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Food name'),
                    validator: _required),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _quantity,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    validator: _required),
                const SizedBox(height: 12),
                DropdownButtonFormField<FoodCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: FoodCategory.values
                      .map((category) => DropdownMenuItem(
                          value: category, child: Text(category.name)))
                      .toList(),
                  onChanged: (value) => setState(() => _category = value!),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Expiration date'),
                  subtitle: Text(DateFormat.yMMMd().format(_expiration)),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: _pickDate,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(onPressed: _save, child: const Text('Add')),
        ],
      );

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _expiration,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (value != null) setState(() => _expiration = value);
  }

  void _save() {
    if (!_key.currentState!.validate()) return;
    Navigator.pop(
      context,
      FoodItem(
        id: const Uuid().v4(),
        name: _name.text.trim(),
        expirationDate: _expiration,
        category: _category,
        quantity: _quantity.text.trim(),
        zone: _category == FoodCategory.produce
            ? FridgeZone.highHumidity
            : FridgeZone.middleShelf,
        createdAt: DateTime.now(),
      ),
    );
  }
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Required' : null;

String? _validatePassword(String? value) {
  final password = value ?? '';
  if (password.length < 8) return 'Use at least 8 characters.';
  if (!RegExp('[A-Za-z]').hasMatch(password) ||
      !RegExp('[0-9]').hasMatch(password)) {
    return 'Include at least one letter and one number.';
  }
  return null;
}
