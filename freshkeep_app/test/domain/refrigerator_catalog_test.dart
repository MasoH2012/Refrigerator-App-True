import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep_app/domain/models/refrigerator_model.dart';

void main() {
  test('catalog options are alphabetized by brand and model', () {
    final labels = RefrigeratorCatalog.alphabetized
        .map((model) => model.displayName)
        .toList();
    final sorted = [...labels]..sort();

    expect(labels, sorted);
  });

  test('catalog contains unique selectable IDs and valid structures', () {
    final models = RefrigeratorCatalog.models;

    expect(models.map((model) => model.id).toSet().length, models.length);
    for (final model in models) {
      expect(model.refrigeratorShelves, greaterThan(0));
      expect(model.crisperDrawers, greaterThan(0));
      expect(model.doorBins, greaterThan(0));
      expect(model.freezerLevels, greaterThan(0));
      expect(model.manufacturerUrl, startsWith('https://'));
    }
  });

  test('catalog resolves IDs and legacy model-number values', () {
    expect(
      RefrigeratorCatalog.byId('samsung-rf28t5001sr')?.modelNumber,
      'RF28T5001SR',
    );
    expect(
      RefrigeratorCatalog.byId('Samsung RF28T5001SR')?.id,
      'samsung-rf28t5001sr',
    );
  });
}
