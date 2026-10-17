import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/data_scope.dart';
import '../../../domain/models/food_item.dart';
import '../../../domain/models/refrigerator_model.dart';
import '../application/auth_controller.dart';

class AccountSetupScreen extends ConsumerStatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  ConsumerState<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends ConsumerState<AccountSetupScreen> {
  final _accountKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _items = <FoodItem>[];
  RefrigeratorModel? _selectedRefrigerator;
  var _step = 0;
  var _obscurePassword = true;
  var _showRefrigeratorError = false;
  var _joinHousehold = false;
  var _accountCreated = false;
  var _isSubmitting = false;
  final _householdCode = TextEditingController();
  final _householdPassword = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirmation.dispose();
    _householdCode.dispose();
    _householdPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
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
                            onPressed: _isSubmitting ? null : _continue,
                            child: Text(
                              _isSubmitting
                                  ? 'Checking username...'
                                  : _step == 0 && _joinHousehold
                                  ? 'Create & join household'
                                  : _step == 2
                                      ? 'Create profile'
                                      : 'Continue',
                            ),
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
          const Text('You will sign in again when you reopen the app.',
              textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Form(
            key: _accountKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _username,
                  enabled: !_accountCreated,
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
                  enabled: !_accountCreated,
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
                  enabled: !_accountCreated,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: Icon(Icons.lock_reset_outlined)),
                  validator: (value) => value != _password.text
                      ? 'Passwords do not match.'
                      : null,
                ),
                const SizedBox(height: 22),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _joinHousehold,
                          onChanged: _accountCreated ? null : (value) =>
                              setState(() => _joinHousehold = value),
                          title: const Text('Join a household now'),
                          subtitle: const Text(
                            'Use the invite code and password shared by the owner. You will skip refrigerator and food setup because the household already has them.',
                          ),
                        ),
                        if (_joinHousehold) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _householdCode,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Household invite code',
                              prefixIcon: Icon(Icons.key_outlined),
                            ),
                            validator: (value) {
                              if (!_joinHousehold) return null;
                              final code = value?.trim() ?? '';
                              return code.length != 8
                                  ? 'Enter the full 8-character invite code.'
                                  : null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _householdPassword,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Household password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (value) {
                              if (!_joinHousehold) return null;
                              return value == null || value.trim().isEmpty
                                  ? 'Enter the household password.'
                                  : null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
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
          LayoutBuilder(
            builder: (context, constraints) => DropdownMenu<RefrigeratorModel>(
              width: constraints.maxWidth,
              enableFilter: true,
              enableSearch: true,
              requestFocusOnTap: true,
              leadingIcon: const Icon(Icons.kitchen),
              label: const Text('Refrigerator brand and model'),
              hintText: 'Search real refrigerator models',
              dropdownMenuEntries: RefrigeratorCatalog.alphabetized
                  .map(
                    (model) => DropdownMenuEntry<RefrigeratorModel>(
                      value: model,
                      label: model.displayName,
                    ),
                  )
                  .toList(),
              onSelected: (model) => setState(() {
                _selectedRefrigerator = model;
                _showRefrigeratorError = false;
              }),
            ),
          ),
          if (_showRefrigeratorError) ...[
            const SizedBox(height: 8),
            Text(
              'Choose a refrigerator from the list.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Type a brand or model number to filter. Only listed models can be selected.',
          ),
          if (_selectedRefrigerator case final model?) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.check)),
                title: Text(model.shortName),
                subtitle: Text(
                  '${model.layoutLabel} · ${model.capacityCuFt} cu. ft.\n'
                  '${model.refrigeratorShelves} shelves · ${model.crisperDrawers} crispers · ${model.freezerLevels} freezer levels',
                ),
                isThreeLine: true,
              ),
            ),
          ],
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
              'Optional. You can add food now or start with an empty inventory and add items later.',
              textAlign: TextAlign.center),
          const SizedBox(height: 22),
          OutlinedButton.icon(
              onPressed: _showAddFoodDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add food item')),
          const SizedBox(height: 14),
          if (_items.isEmpty)
            Card(
              child: const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('No food added yet'),
                subtitle: Text('You can add items from the Home screen later.'),
              ),
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
    if (_isSubmitting) return;

    // A household already has its shared refrigerator and inventory. Do not
    // make a new member repeat those setup steps during profile creation.
    if (_step == 0 && _joinHousehold) {
      await _runWhileSubmitting(_createProfile);
      return;
    }
    if (_step == 0 && _accountCreated) {
      setState(() => _step++);
      return;
    }
    if (_step == 1 && _selectedRefrigerator == null) {
      setState(() => _showRefrigeratorError = true);
      return;
    }
    if (_step == 0) {
      await _runWhileSubmitting(() async {
        // Creating the Firebase account here makes username availability
        // authoritative before the wizard advances. A duplicate username is
        // rejected by FirebaseAuth and remains on this step.
        final error = await ref.read(authProvider.notifier).register(
              username: _username.text,
              password: _password.text,
              refrigeratorModel: '',
              initialItems: const [],
            );
        if (error != null) {
          _showError(error);
          return;
        }
        if (mounted) {
          setState(() {
            _accountCreated = true;
            _step++;
          });
        }
      });
      return;
    }

    // The account was already validated and created on step 1. Step 2 only
    // validates the refrigerator selection before moving to food setup.
    if (_step == 1) {
      setState(() => _step++);
      return;
    }

    await _runWhileSubmitting(_createProfile);
  }

  Future<void> _createProfile() async {
    if (_accountCreated) {
      await _finishExistingAccount();
      return;
    }

    final error = await ref.read(authProvider.notifier).register(
          username: _username.text,
          password: _password.text,
          // Household members can choose their own model later. An empty
          // value avoids pretending that a default refrigerator was selected.
          refrigeratorModel: _selectedRefrigerator?.id ?? '',
          initialItems: _items,
          householdInviteCode: _joinHousehold ? _householdCode.text : null,
          householdPassword: _joinHousehold ? _householdPassword.text : null,
        );
    if (error != null) {
      _showError(error);
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _finishExistingAccount() async {
    final profile = ref.read(authProvider).value?.profile;
    if (profile == null) {
      _showError('Your account session expired. Please start again.');
      return;
    }
    final refrigerator = _selectedRefrigerator;
    if (refrigerator == null) {
      _showError('Choose a refrigerator before continuing.');
      return;
    }
    final refrigeratorError = await ref
        .read(authProvider.notifier)
        .updateRefrigeratorModel(refrigerator.id);
    if (refrigeratorError != null) {
      _showError(refrigeratorError);
      return;
    }
    try {
      await ref.read(inventoryRepositoryProvider).saveItems(
            privateScopeForProfile(profile),
            _items,
          );
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      _showError('Could not save your food items: $error');
    }
  }

  Future<void> _runWhileSubmitting(Future<void> Function() action) async {
    if (mounted) setState(() => _isSubmitting = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
