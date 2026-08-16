import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/food_item.dart';
import '../application/inventory_controller.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _quantity = TextEditingController(text: '1 item');
  var _category = FoodCategory.produce;
  var _zone = FridgeZone.highHumidity;
  var _expirationDate = DateTime.now().add(const Duration(days: 5));
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Add food')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.edit_outlined),
                      label: Text('Manual'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.camera_alt_outlined),
                      label: Text('Scan'),
                    ),
                  ],
                  selected: const {false},
                  onSelectionChanged: (_) => _showScanner(),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Food name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a food name'
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<FoodCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: FoodCategory.values
                      .map(
                        (value) => DropdownMenuItem(
                            value: value, child: Text(value.name)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _category = value!),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _quantity,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a quantity'
                      : null,
                ),
                const SizedBox(height: 14),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: Theme.of(context).colorScheme.surface,
                  title: const Text('Expiration date'),
                  subtitle: Text(DateFormat.yMMMMd().format(_expirationDate)),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<FridgeZone>(
                  initialValue: _zone,
                  decoration:
                      const InputDecoration(labelText: 'Fridge location'),
                  items: FridgeZone.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_zoneName(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _zone = value!),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add to my fridge'),
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _expirationDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await ref.read(inventoryProvider.notifier).addItem(
          name: _name.text,
          expirationDate: _expirationDate,
          category: _category,
          quantity: _quantity.text,
          zone: _zone,
        );
    if (mounted) context.pop();
  }

  void _showScanner() => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.document_scanner_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Camera recognition',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Camera and OCR plug-ins can connect here without changing the inventory workflow.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue manually'),
              ),
            ],
          ),
        ),
      );
}

String _zoneName(FridgeZone zone) => switch (zone) {
      FridgeZone.topShelf => 'Top shelf',
      FridgeZone.middleShelf => 'Middle shelf',
      FridgeZone.lowerShelf => 'Lower shelf',
      FridgeZone.highHumidity => 'High-humidity drawer',
      FridgeZone.lowHumidity => 'Low-humidity drawer',
      FridgeZone.door => 'Door',
    };
