import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../domain/models/food_item.dart';
import '../../../domain/models/fridge_organization.dart';
import '../../../domain/models/refrigerator_model.dart';
import '../../auth/application/auth_controller.dart';
import '../../inventory/application/inventory_controller.dart';
import '../data/fridge_organization_service.dart';

const _organizationApiUrl =
    String.fromEnvironment('FRESHKEEP_ORGANIZATION_API_URL');

final organizationHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final fridgeOrganizationServiceProvider = Provider<FridgeOrganizationService>(
  (ref) => FridgeOrganizationService(
    client: ref.watch(organizationHttpClientProvider),
    endpoint: _organizationEndpoint(),
  ),
);

Uri? _organizationEndpoint() {
  final configured = _organizationApiUrl.trim();
  if (configured.isNotEmpty) {
    final uri = Uri.tryParse(configured);
    if (uri != null &&
        {'http', 'https'}.contains(uri.scheme) &&
        uri.host.isNotEmpty) {
      return uri;
    }
  }
  if (!kDebugMode) return null;
  final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : '127.0.0.1';
  return Uri.parse('http://$host:8787/fridge-organization');
}

final fridgeOrganizationProvider = AsyncNotifierProvider<
    FridgeOrganizationController, FridgeOrganizationPlan?>(
  FridgeOrganizationController.new,
);

class FridgeOrganizationController
    extends AsyncNotifier<FridgeOrganizationPlan?> {
  @override
  Future<FridgeOrganizationPlan?> build() async => null;

  Future<void> generate() async {
    final profile = ref.read(authProvider).value?.profile;
    final refrigerator = profile == null
        ? null
        : RefrigeratorCatalog.byId(profile.refrigeratorModel);
    if (refrigerator == null) {
      state = AsyncError(
        const FridgeOrganizationException(
            'Select a supported refrigerator model first.'),
        StackTrace.current,
      );
      return;
    }
    final items = (await ref.read(inventoryProvider.future))
        .where((item) => item.storageLocation == StorageLocation.fridge)
        .toList();
    if (items.isEmpty) {
      state = AsyncError(
        const FridgeOrganizationException(
            'Add food to your fridge before organizing it.'),
        StackTrace.current,
      );
      return;
    }
    state = const AsyncLoading<FridgeOrganizationPlan?>();
    try {
      final plan = await ref.read(fridgeOrganizationServiceProvider).organize(
            items: items,
            refrigerator: refrigerator,
          );
      state = AsyncData(plan);
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> applyPlan(FridgeOrganizationPlan plan) async {
    final assignments = {
      for (final assignment in plan.assignments)
        assignment.itemId: assignment.zone,
    };
    final current = await ref.read(inventoryProvider.future);
    final updated = current
        .map((item) => item.copyWith(zone: assignments[item.id] ?? item.zone))
        .toList();
    final inventory = ref.read(inventoryProvider.notifier);
    await inventory.replaceItems(updated);
  }
}
