import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../domain/models/food_item.dart';
import '../../../domain/models/fridge_organization.dart';
import '../../../domain/models/refrigerator_model.dart';

class FridgeOrganizationException implements Exception {
  const FridgeOrganizationException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class FridgeOrganizationService {
  FridgeOrganizationService(
      {required http.Client client, required Uri? endpoint})
      : _client = client,
        _endpoint = endpoint;

  final http.Client _client;
  final Uri? _endpoint;

  Future<FridgeOrganizationPlan> organize({
    required List<FoodItem> items,
    required RefrigeratorModel refrigerator,
  }) async {
    if (_endpoint == null) {
      throw const FridgeOrganizationException(
        'AI fridge organization is not configured for this build.',
        statusCode: 503,
      );
    }
    final response = await _client
        .post(
          _endpoint!,
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'refrigerator': {
              'id': refrigerator.id,
              'displayName': refrigerator.displayName,
              'layout': refrigerator.layout.name,
              'shelves': refrigerator.refrigeratorShelves,
              'crisperDrawers': refrigerator.crisperDrawers,
              'doorBins': refrigerator.doorBins,
              'freezerLevels': refrigerator.freezerLevels,
            },
            'items': items
                .map(
                  (item) => {
                    'id': item.id,
                    'name': item.name,
                    'quantity': item.quantity,
                    'category': item.category.name,
                    'currentZone': item.zone.name,
                    'expirationDate': item.expirationDate.toIso8601String(),
                  },
                )
                .toList(),
          }),
        )
        // Organization plans use the same AI service as recipes and may
        // include web-backed reasoning, so allow the longer server window.
        .timeout(const Duration(seconds: 90));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FridgeOrganizationException(
        'Organization service returned ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }
    final payload = jsonDecode(response.body);
    if (payload is! Map<String, Object?> || payload['assignments'] is! List) {
      throw const FormatException('Invalid organization service response.');
    }
    final assignments = <FridgeOrganizationAssignment>[];
    for (final value in payload['assignments']! as List) {
      if (value is! Map) continue;
      try {
        assignments.add(
          FridgeOrganizationAssignment.fromJson(
            Map<String, Object?>.from(value),
          ),
        );
      } on Object {
        continue;
      }
    }
    return FridgeOrganizationPlan(
      assignments: assignments,
      summary: payload['summary'] as String? ??
          'Your fridge has an updated organization plan.',
      generatedAt: DateTime.now(),
    );
  }
}
