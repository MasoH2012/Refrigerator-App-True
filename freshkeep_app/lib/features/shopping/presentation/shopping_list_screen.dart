import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/shopping_list_controller.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  @override
  Widget build(BuildContext context) {
    final items = ref.watch(shoppingListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping list')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (values) => values.isEmpty
            ? const Center(child: Text('Your shopping list is empty.'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: values.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = values[index];
                  return Card(
                    child: ListTile(
                      leading: Checkbox(
                        value: item.checked,
                        onChanged: (_) => ref
                            .read(shoppingListProvider.notifier)
                            .toggle(item),
                      ),
                      title: Text(
                        item.name,
                        style: TextStyle(
                          decoration:
                              item.checked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text(item.quantity),
                      trailing: IconButton(
                        tooltip: 'Remove from shopping list',
                        onPressed: () => ref
                            .read(shoppingListProvider.notifier)
                            .remove(item.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _addItem() async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _AddShoppingItemDialog(),
    );
    if (!mounted || result == null) return;
    await ref.read(shoppingListProvider.notifier).addItem(
          name: result.$1,
          quantity: result.$2,
        );
  }
}

class _AddShoppingItemDialog extends StatefulWidget {
  const _AddShoppingItemDialog();

  @override
  State<_AddShoppingItemDialog> createState() => _AddShoppingItemDialogState();
}

class _AddShoppingItemDialogState extends State<_AddShoppingItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _quantityController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add to shopping list'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Item'),
            ),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              (_nameController.text, _quantityController.text),
            ),
            child: const Text('Add'),
          ),
        ],
      );
}
