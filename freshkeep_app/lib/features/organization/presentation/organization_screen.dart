import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/food_item.dart';
import '../../auth/application/auth_controller.dart';
import '../../inventory/application/inventory_controller.dart';

class OrganizationScreen extends ConsumerWidget {
  const OrganizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(inventoryProvider).valueOrNull ?? const <FoodItem>[];
    final refrigerator =
        ref.watch(authProvider).valueOrNull?.profile?.refrigeratorModel ??
            'Your refrigerator';
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Text(
            'SMART PLACEMENT',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Text(
            'Organize your fridge',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.kitchen)),
              title: Text(refrigerator),
              subtitle: const Text('Personal organization plan'),
              trailing: TextButton(onPressed: () {}, child: const Text('Edit')),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 5,
              ),
            ),
            child: Column(
              children: [
                _ZoneCard(
                  title: 'TOP SHELF · READY TO EAT',
                  icon: Icons.room_service_outlined,
                  items: _names(items, [FridgeZone.topShelf]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ZoneCard(
                        title: 'MIDDLE',
                        icon: Icons.local_drink_outlined,
                        items: _names(items, [
                          FridgeZone.middleShelf,
                          FridgeZone.door,
                        ]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ZoneCard(
                        title: 'LOWER',
                        icon: Icons.set_meal_outlined,
                        items: _names(items, [FridgeZone.lowerShelf]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ZoneCard(
                        title: 'HUMIDITY HIGH',
                        icon: Icons.eco_outlined,
                        items: _names(items, [FridgeZone.highHumidity]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ZoneCard(
                        title: 'HUMIDITY LOW',
                        icon: Icons.apple_outlined,
                        items: _names(items, [FridgeZone.lowHumidity]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 18),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Raw proteins stay low to prevent cross-contamination.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _names(List<FoodItem> items, List<FridgeZone> zones) => items
      .where((item) => zones.contains(item.zone))
      .map((item) => item.name)
      .toList();
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({
    required this.title,
    required this.icon,
    required this.items,
  });
  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: items.length > 3
              ? () => showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (context) => ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(title,
                            style: Theme.of(context).textTheme.titleLarge),
                        ...items.map(
                          (item) =>
                              ListTile(leading: Icon(icon), title: Text(item)),
                        ),
                      ],
                    ),
                  )
              : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 130),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    items.isEmpty
                        ? 'No items assigned'
                        : '${items.take(3).join(' · ')}${items.length > 3 ? ' · …' : ''}',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
