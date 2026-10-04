import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../domain/models/food_item.dart';
import '../application/inventory_controller.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({this.item, super.key});

  final FoodItem? item;

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _quantity = TextEditingController(text: '1 item');
  var _category = FoodCategory.produce;
  var _zone = FridgeZone.highHumidity;
  var _storageLocation = StorageLocation.fridge;
  var _expirationDate = DateTime.now().add(const Duration(days: 5));
  var _expirationIsEstimated = false;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item == null) return;
    _name.text = item.name;
    _quantity.text = item.quantity;
    _category = item.category;
    _zone = item.zone;
    _storageLocation = item.storageLocation;
    _expirationDate = item.expirationDate;
    _expirationIsEstimated = false;
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar:
            AppBar(title: Text(widget.item == null ? 'Add food' : 'Edit food')),
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
                if (_expirationIsEstimated)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Expiration was estimated from the food type. Update it with the package date when available.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 14),
                DropdownButtonFormField<StorageLocation>(
                  initialValue: _storageLocation,
                  decoration:
                      const InputDecoration(labelText: 'Storage location'),
                  items: const [
                    DropdownMenuItem(
                      value: StorageLocation.fridge,
                      child: Text('In fridge'),
                    ),
                    DropdownMenuItem(
                      value: StorageLocation.outOfFridge,
                      child: Text('Out of fridge'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _storageLocation = value!),
                ),
                if (_storageLocation == StorageLocation.fridge) ...[
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
                ],
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.item == null
                              ? (_storageLocation == StorageLocation.fridge
                                  ? 'Add to my fridge'
                                  : 'Add out-of-fridge item')
                              : 'Save changes',
                        ),
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
    if (picked != null) {
      setState(() {
        _expirationDate = picked;
        _expirationIsEstimated = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final controller = ref.read(inventoryProvider.notifier);
    final existing = widget.item;
    if (existing == null) {
      await controller.addItem(
        name: _name.text,
        expirationDate: _expirationDate,
        category: _category,
        quantity: _quantity.text,
        zone: _zone,
        storageLocation: _storageLocation,
      );
    } else {
      await controller.updateItem(
        existing.copyWith(
          name: _name.text.trim(),
          expirationDate: _expirationDate,
          category: _category,
          quantity: _quantity.text.trim(),
          zone: _zone,
          storageLocation: _storageLocation,
        ),
      );
    }
    if (mounted) context.pop();
  }

  Future<void> _showScanner() async {
    final barcode = await showDialog<String>(
      context: context,
      builder: (_) => const _BarcodeDialog(),
    );
    if (barcode == null || barcode.isEmpty || !mounted) return;
    try {
      final response = await http
          .get(Uri.parse(
              'https://world.openfoodfacts.org/api/v2/product/$barcode.json'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) throw const FormatException();
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final product = payload['product'] as Map<String, dynamic>?;
      final name = product?['product_name'] as String?;
      if (name == null || name.trim().isEmpty) throw const FormatException();
      final category = _categoryFromBarcode(product);
      final scannedExpiration = _expirationDateFromBarcode(product);
      final expirationWasEstimated = scannedExpiration == null;
      setState(() {
        _name.text = name.trim();
        _category = category;
        _quantity.text = _quantityFromBarcode(product);
        _storageLocation = _storageLocationFromCategory(category);
        _zone = _zoneFromCategory(category);
        _expirationDate = scannedExpiration ??
            DateTime.now().add(_estimatedShelfLife(category));
        _expirationIsEstimated = expirationWasEstimated;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              expirationWasEstimated
                  ? 'Food details, quantity, storage location, and estimated expiration filled from barcode.'
                  : 'Food details, quantity, storage location, and expiration filled from barcode.',
            ),
          ),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Barcode not found. Enter the food manually.')),
        );
      }
    }
  }

  FoodCategory _categoryFromBarcode(Map<String, dynamic>? product) {
    final tags = '${product?['categories'] ?? ''}'.toLowerCase();
    if (tags.contains('beverage') || tags.contains('drink')) {
      return FoodCategory.beverage;
    }
    if (tags.contains('dairy') ||
        tags.contains('milk') ||
        tags.contains('cheese')) {
      return FoodCategory.dairy;
    }
    if (tags.contains('meat') ||
        tags.contains('fish') ||
        tags.contains('chicken')) {
      return FoodCategory.protein;
    }
    if (tags.contains('fruit') || tags.contains('vegetable')) {
      return FoodCategory.produce;
    }
    return FoodCategory.pantry;
  }

  String _quantityFromBarcode(Map<String, dynamic>? product) {
    final quantity = product?['quantity'];
    if (quantity is String && quantity.trim().isNotEmpty) {
      return quantity.trim();
    }

    final amount = product?['product_quantity'];
    if (amount != null && amount.toString().trim().isNotEmpty) {
      final unit = product?['product_quantity_unit']?.toString().trim() ?? '';
      return unit.isEmpty
          ? amount.toString().trim()
          : '${amount.toString().trim()} $unit';
    }
    return '1 item';
  }

  StorageLocation _storageLocationFromCategory(FoodCategory category) =>
      category == FoodCategory.pantry
          ? StorageLocation.outOfFridge
          : StorageLocation.fridge;

  FridgeZone _zoneFromCategory(FoodCategory category) => switch (category) {
        FoodCategory.produce => FridgeZone.highHumidity,
        FoodCategory.protein => FridgeZone.lowerShelf,
        FoodCategory.dairy => FridgeZone.middleShelf,
        FoodCategory.beverage => FridgeZone.door,
        FoodCategory.leftovers => FridgeZone.topShelf,
        FoodCategory.pantry => FridgeZone.lowHumidity,
      };

  Duration _estimatedShelfLife(FoodCategory category) => switch (category) {
        FoodCategory.produce => const Duration(days: 5),
        FoodCategory.dairy => const Duration(days: 7),
        FoodCategory.protein => const Duration(days: 3),
        FoodCategory.beverage => const Duration(days: 14),
        FoodCategory.leftovers => const Duration(days: 4),
        FoodCategory.pantry => const Duration(days: 90),
      };

  DateTime? _expirationDateFromBarcode(Map<String, dynamic>? product) {
    for (final key in const [
      'expiration_date',
      'best_before_date',
      'best_before',
    ]) {
      final parsed = _parseBarcodeDate(product?[key]);
      if (parsed != null) return parsed;
    }
    return null;
  }

  DateTime? _parseBarcodeDate(Object? rawValue) {
    if (rawValue == null) return null;
    final value = rawValue.toString().trim();
    if (value.isEmpty) return null;

    final direct = DateTime.tryParse(value);
    if (direct != null) {
      return DateTime(direct.year, direct.month, direct.day);
    }

    final yearFirst =
        RegExp(r'^(\d{4})[-./]?(\d{2})[-./]?(\d{2})$').firstMatch(value);
    if (yearFirst != null) {
      return DateTime(
        int.parse(yearFirst.group(1)!),
        int.parse(yearFirst.group(2)!),
        int.parse(yearFirst.group(3)!),
      );
    }

    final dayFirst =
        RegExp(r'^(\d{2})[-./](\d{2})[-./](\d{4})$').firstMatch(value);
    if (dayFirst != null) {
      return DateTime(
        int.parse(dayFirst.group(3)!),
        int.parse(dayFirst.group(2)!),
        int.parse(dayFirst.group(1)!),
      );
    }
    return null;
  }
}

class _BarcodeDialog extends StatefulWidget {
  const _BarcodeDialog();

  @override
  State<_BarcodeDialog> createState() => _BarcodeDialogState();
}

class _BarcodeDialogState extends State<_BarcodeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Scan a barcode'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'UPC or EAN barcode',
            hintText: 'Example: 012345678905',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _controller.text.trim()),
            child: const Text('Look up'),
          ),
        ],
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
