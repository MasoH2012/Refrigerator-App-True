import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/food_item.dart';
import '../../../domain/models/app_preferences.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../application/inventory_controller.dart';
import '../application/inventory_sort.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  var _didShowAlert = false;
  var _sortOrder = InventorySortOrder.expirationSoonest;

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryProvider);
    return SafeArea(
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/add'),
          icon: const Icon(Icons.add),
          label: const Text('New'),
        ),
        body: RefreshIndicator(
          onRefresh: () => ref.refresh(inventoryProvider.future),
          child: inventory.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                _ErrorState(onRetry: () => ref.invalidate(inventoryProvider)),
            data: (items) {
              final sortedItems = sortFoodItems(items, _sortOrder);
              final profile = ref.watch(authProvider).value?.profile;
              final settings = profile == null
                  ? const AppPreferences()
                  : ref
                      .read(userPreferencesRepositoryProvider)
                      .load(profile.username);
              final urgent = items
                  .where(
                    (item) =>
                        settings.notificationsEnabled &&
                        item.daysUntilExpiration(DateTime.now()) >= 0 &&
                        item.daysUntilExpiration(DateTime.now()) <=
                            settings.warningDays,
                  )
                  .toList();
              if (!_didShowAlert && urgent.isNotEmpty) {
                _didShowAlert = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _showExpirySheet(context, urgent, settings.warningDays);
                  }
                });
              }
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: _Header(
                        username:
                            ref.watch(authProvider).value?.profile?.username ??
                                'there',
                      ),
                    ),
                  ),
                  if (urgent.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      sliver: SliverToBoxAdapter(
                        child: _ExpiryBanner(
                          count: urgent.length,
                          onTap: () => _showExpirySheet(
                            context,
                            urgent,
                            settings.warningDays,
                          ),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your food',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                '${items.length} items · ${_sortOrder.shortLabel}',
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton.filledTonal(
                                tooltip: 'Shopping list',
                                onPressed: () => context.push('/shopping'),
                                icon: const Icon(Icons.shopping_cart_outlined),
                              ),
                              const SizedBox(width: 6),
                              IconButton.filledTonal(
                                tooltip: 'Sort items',
                                onPressed: _showSortSheet,
                                icon: const Icon(Icons.sort),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (items.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList.separated(
                        itemCount: sortedItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _FoodCard(item: sortedItems[index]),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showExpirySheet(
    BuildContext context,
    List<FoodItem> items,
    int warningDays,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Use these soon',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                '${items.length} items expire within $warningDays ${warningDays == 1 ? 'day' : 'days'}',
              ),
              const SizedBox(height: 16),
              ...items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _FoodImage(item: item, size: 44),
                  title: Text(item.name),
                  subtitle: Text(
                    _expiryText(item.daysUntilExpiration(DateTime.now())),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Find recipes using these'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSortSheet() async {
    final selected = await showModalBottomSheet<InventorySortOrder>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  'Sort by',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              ...InventorySortOrder.values.map(
                (order) => ListTile(
                  leading: Icon(_sortIcon(order)),
                  title: Text(order.label),
                  trailing: order == _sortOrder
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  selected: order == _sortOrder,
                  onTap: () => Navigator.pop(context, order),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && selected != _sortOrder && mounted) {
      setState(() => _sortOrder = selected);
    }
  }

  IconData _sortIcon(InventorySortOrder order) => switch (order) {
        InventorySortOrder.expirationSoonest => Icons.schedule,
        InventorySortOrder.expirationLatest => Icons.calendar_month_outlined,
        InventorySortOrder.nameAscending => Icons.sort_by_alpha,
        InventorySortOrder.categoryAscending => Icons.category_outlined,
      };
}

class _Header extends StatelessWidget {
  const _Header({required this.username});
  final String username;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d')
                      .format(DateTime.now())
                      .toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Good afternoon,\n$username',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(username.substring(0, 1).toUpperCase()),
          ),
        ],
      );
}

class _ExpiryBanner extends StatelessWidget {
  const _ExpiryBanner({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        child: ListTile(
          onTap: onTap,
          leading: const CircleAvatar(child: Icon(Icons.schedule)),
          title: Text('$count items need your attention'),
          subtitle: const Text('Use them soon to prevent food waste.'),
          trailing: const Text('View'),
        ),
      );
}

class _FoodCard extends ConsumerWidget {
  const _FoodCard({required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = item.daysUntilExpiration(DateTime.now());
    final color = days <= 0
        ? AppColors.danger
        : days <= 3
            ? AppColors.warning
            : Theme.of(context).colorScheme.primary;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.none,
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(10),
          leading: _FoodImage(item: item),
          title: Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${item.storageLocation == StorageLocation.outOfFridge ? 'Out of fridge · ' : ''}${item.category.name} · ${item.quantity}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _expiryText(days),
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    DateFormat('MMM d').format(item.expirationDate),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Remove quantity from ${item.name}',
                onPressed: () => _removeQuantity(context, ref),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          onTap: () => context.push('/add', extra: item),
        ),
      ),
    );
  }

  Future<void> _removeQuantity(BuildContext context, WidgetRef ref) async {
    final match =
        RegExp(r'^\s*(\d+(?:\.\d+)?)\s*(.*)$').firstMatch(item.quantity);
    if (match == null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Remove ${item.name}?'),
          content: Text(
            'The quantity “${item.quantity}” is not numeric, so this item can only be removed in full.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove item'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await ref.read(inventoryProvider.notifier).removeItem(item.id);
      }
      return;
    }

    final available = double.parse(match.group(1)!);
    final unit = match.group(2)!.trim();
    final controller = TextEditingController(text: '1');
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'You have ${item.quantity}. How much would you like to remove?'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount to remove',
                suffixText: unit.isEmpty ? null : unit,
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
              final value = double.tryParse(controller.text.trim());
              if (value == null || value <= 0 || value > available) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Enter an amount from 0 to $available.')),
                );
                return;
              }
              Navigator.pop(context, value);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount != null) {
      await ref
          .read(inventoryProvider.notifier)
          .removeQuantity(item.id, amount);
    }
  }
}

class _FoodImage extends StatelessWidget {
  const _FoodImage({required this.item, this.size = 56});
  final FoodItem item;
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: item.imageUrl == null
            ? Container(
                width: size,
                height: size,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.eco_outlined),
              )
            : Image.network(
                item.imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => SizedBox(
                  width: size,
                  height: size,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
      );
}

String _expiryText(int days) => days < 0
    ? 'Expired'
    : days == 0
        ? 'Today'
        : days == 1
            ? 'Tomorrow'
            : '$days days';

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Your fridge is empty. Add your first item.'));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: FilledButton(onPressed: onRetry, child: const Text('Try again')),
      );
}
