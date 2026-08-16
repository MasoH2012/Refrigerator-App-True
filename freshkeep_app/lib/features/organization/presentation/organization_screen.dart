import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/food_item.dart';
import '../../../domain/models/refrigerator_model.dart';
import '../../auth/application/auth_controller.dart';
import '../../inventory/application/inventory_controller.dart';

class OrganizationScreen extends ConsumerWidget {
  const OrganizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(inventoryProvider).valueOrNull ?? const <FoodItem>[];
    final savedModelId =
        ref.watch(authProvider).valueOrNull?.profile?.refrigeratorModel ?? '';
    final refrigerator = RefrigeratorCatalog.byId(savedModelId);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Text(
            'MODEL-SPECIFIC PLACEMENT',
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
          if (refrigerator == null)
            const _UnsupportedModelCard()
          else ...[
            _ModelSummary(model: refrigerator),
            const SizedBox(height: 16),
            _FridgeDiagram(model: refrigerator, items: items),
            const SizedBox(height: 14),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_outlined, size: 18),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Layout and compartment counts match the selected manufacturer model.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 18),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Keep raw proteins on the lowest refrigerator shelf to reduce cross-contamination risk.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ModelSummary extends StatelessWidget {
  const _ModelSummary({required this.model});

  final RefrigeratorModel model;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.kitchen)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.shortName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(model.productName),
                      ],
                    ),
                  ),
                  const Icon(Icons.verified, color: Color(0xFF2F7D5B)),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(model.layoutLabel)),
                  Chip(label: Text('${model.capacityCuFt} cu. ft.')),
                  Chip(label: Text('${model.refrigeratorShelves} shelves')),
                  Chip(label: Text('${model.doorBins} door bins')),
                ],
              ),
            ],
          ),
        ),
      );
}

class _FridgeDiagram extends StatelessWidget {
  const _FridgeDiagram({required this.model, required this.items});

  final RefrigeratorModel model;
  final List<FoodItem> items;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 5,
          ),
        ),
        child: switch (model.layout) {
          RefrigeratorLayoutKind.frenchDoor3 => _threeDoor(context),
          RefrigeratorLayoutKind.frenchDoor4 => _fourDoor(context),
          RefrigeratorLayoutKind.sideBySide => _sideBySide(context),
        },
      );

  Widget _threeDoor(BuildContext context) => Column(
        children: [
          _Compartment(
            title: 'FRESH-FOOD SHELVES',
            detail: '${model.refrigeratorShelves} adjustable shelves',
            icon: Icons.view_agenda_outlined,
            items: _names([
              FridgeZone.topShelf,
              FridgeZone.middleShelf,
              FridgeZone.lowerShelf,
              FridgeZone.door,
            ]),
            minimumHeight: 140,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Compartment(
                  title: 'HIGH-HUMIDITY CRISPER',
                  detail: '${model.crisperDrawers} crisper drawers total',
                  icon: Icons.eco_outlined,
                  items: _names([FridgeZone.highHumidity]),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Compartment(
                  title: 'LOW-HUMIDITY CRISPER',
                  detail: 'Fruit and low-humidity produce',
                  icon: Icons.apple_outlined,
                  items: _names([FridgeZone.lowHumidity]),
                ),
              ),
            ],
          ),
          if (model.pantryDrawers > 0) ...[
            const SizedBox(height: 8),
            _Compartment(
              title:
                  (model.specialDrawerLabel ?? 'Pantry drawer').toUpperCase(),
              detail: '${model.pantryDrawers} full-width drawer',
              icon: Icons.table_rows_outlined,
              items: _names([FridgeZone.lowerShelf]),
            ),
          ],
          const SizedBox(height: 8),
          _Compartment(
            title: 'BOTTOM FREEZER',
            detail:
                '${model.freezerLevels} storage level${model.freezerLevels == 1 ? '' : 's'}',
            icon: Icons.ac_unit,
            items: const ['Frozen foods'],
            minimumHeight: 92,
          ),
        ],
      );

  Widget _fourDoor(BuildContext context) => Column(
        children: [
          _Compartment(
            title: 'FRENCH-DOOR FRESH-FOOD CABINET',
            detail:
                '${model.refrigeratorShelves} shelves · ${model.doorBins} gallon bins',
            icon: Icons.view_agenda_outlined,
            items: _names([
              FridgeZone.topShelf,
              FridgeZone.middleShelf,
              FridgeZone.door,
            ]),
            minimumHeight: 150,
          ),
          const SizedBox(height: 8),
          _Compartment(
            title:
                (model.specialDrawerLabel ?? 'Freshness drawer').toUpperCase(),
            detail:
                '${model.crisperDrawers} humidity compartments · temperature controlled',
            icon: Icons.thermostat_outlined,
            items: _names([
              FridgeZone.highHumidity,
              FridgeZone.lowHumidity,
              FridgeZone.lowerShelf,
            ]),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Compartment(
                  title: 'LEFT FREEZER',
                  detail: '${model.freezerLevels} internal drawers total',
                  icon: Icons.ac_unit,
                  items: const ['Frozen proteins'],
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _Compartment(
                  title: 'RIGHT FREEZER',
                  detail: 'Organized lower storage',
                  icon: Icons.ac_unit,
                  items: ['Frozen produce'],
                ),
              ),
            ],
          ),
        ],
      );

  Widget _sideBySide(BuildContext context) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Compartment(
                title: 'FREEZER COLUMN',
                detail:
                    '${model.freezerLevels} shelves · ice and frozen storage',
                icon: Icons.ac_unit,
                items: const ['Frozen foods'],
                minimumHeight: 360,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Compartment(
                title: 'REFRIGERATOR COLUMN',
                detail:
                    '${model.refrigeratorShelves} shelves · ${model.doorBins} door bins · ${model.crisperDrawers} crispers',
                icon: Icons.kitchen_outlined,
                items: _names(FridgeZone.values),
                minimumHeight: 360,
              ),
            ),
          ],
        ),
      );

  List<String> _names(Iterable<FridgeZone> zones) => items
      .where((item) => zones.contains(item.zone))
      .map((item) => item.name)
      .toList();
}

class _Compartment extends StatelessWidget {
  const _Compartment({
    required this.title,
    required this.detail,
    required this.icon,
    required this.items,
    this.minimumHeight = 116,
  });

  final String title;
  final String detail;
  final IconData icon;
  final List<String> items;
  final double minimumHeight;

  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints(minHeight: minimumHeight),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(detail, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              items.isEmpty
                  ? 'No items assigned'
                  : '${items.take(4).join(' · ')}${items.length > 4 ? ' · …' : ''}',
            ),
          ],
        ),
      );
}

class _UnsupportedModelCard extends StatelessWidget {
  const _UnsupportedModelCard();

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: const ListTile(
          leading: Icon(Icons.warning_amber_rounded),
          title: Text('Refrigerator model needs to be selected again'),
          subtitle: Text(
            'This profile was created before the verified refrigerator catalog was added.',
          ),
        ),
      );
}
