import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/food_item.dart';
import '../../auth/application/auth_controller.dart';
import '../application/inventory_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  var _didShowAlert = false;

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
              final urgent = items
                  .where(
                    (item) => item.daysUntilExpiration(DateTime.now()) <= 3,
                  )
                  .toList();
              if (!_didShowAlert && urgent.isNotEmpty) {
                _didShowAlert = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _showExpirySheet(context, urgent);
                });
              }
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: _Header(
                        username: ref
                                .watch(authProvider)
                                .valueOrNull
                                ?.profile
                                ?.username ??
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
                          onTap: () => _showExpirySheet(context, urgent),
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
                                'Your fridge',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text('${items.length} items · sorted by expiry'),
                            ],
                          ),
                          IconButton.filledTonal(
                            onPressed: () {},
                            icon: const Icon(Icons.tune),
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
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _FoodCard(item: items[index]),
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

  Future<void> _showExpirySheet(BuildContext context, List<FoodItem> items) {
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
              Text('${items.length} items expire within three days'),
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
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) =>
          ref.read(inventoryProvider.notifier).removeItem(item.id),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(10),
          leading: _FoodImage(item: item),
          title: Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text('${item.category.name} · ${item.quantity}'),
          trailing: Column(
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
        ),
      ),
    );
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
