enum RefrigeratorLayoutKind { frenchDoor3, frenchDoor4, sideBySide }

class RefrigeratorModel {
  const RefrigeratorModel({
    required this.id,
    required this.brand,
    required this.modelNumber,
    required this.productName,
    required this.layout,
    required this.capacityCuFt,
    required this.refrigeratorShelves,
    required this.crisperDrawers,
    required this.pantryDrawers,
    required this.doorBins,
    required this.freezerLevels,
    required this.manufacturerUrl,
    this.specialDrawerLabel,
  });

  final String id;
  final String brand;
  final String modelNumber;
  final String productName;
  final RefrigeratorLayoutKind layout;
  final double capacityCuFt;
  final int refrigeratorShelves;
  final int crisperDrawers;
  final int pantryDrawers;
  final int doorBins;
  final int freezerLevels;
  final String manufacturerUrl;
  final String? specialDrawerLabel;

  String get shortName => '$brand $modelNumber';

  String get displayName => '$brand $modelNumber — $productName';

  String get layoutLabel => switch (layout) {
        RefrigeratorLayoutKind.frenchDoor3 => '3-door French door',
        RefrigeratorLayoutKind.frenchDoor4 => '4-door French door',
        RefrigeratorLayoutKind.sideBySide => 'Side-by-side',
      };
}

abstract final class RefrigeratorCatalog {
  static const models = <RefrigeratorModel>[
    RefrigeratorModel(
      id: 'bosch-b36cl80ens',
      brand: 'Bosch',
      modelNumber: 'B36CL80ENS',
      productName: '800 Series Counter-Depth Refrigerator',
      layout: RefrigeratorLayoutKind.frenchDoor4,
      capacityCuFt: 20.5,
      refrigeratorShelves: 5,
      crisperDrawers: 2,
      pantryDrawers: 1,
      doorBins: 3,
      freezerLevels: 3,
      specialDrawerLabel: 'VitaFreshPro™ drawer',
      manufacturerUrl:
          'https://www.bosch-home.com/us/en/product/refrigerators/french-door/freestanding/B36CL80ENS',
    ),
    RefrigeratorModel(
      id: 'ge-gne27jymfs',
      brand: 'GE',
      modelNumber: 'GNE27JYMFS',
      productName: '27 cu. ft. French-Door Refrigerator',
      layout: RefrigeratorLayoutKind.frenchDoor3,
      capacityCuFt: 27,
      refrigeratorShelves: 5,
      crisperDrawers: 2,
      pantryDrawers: 1,
      doorBins: 6,
      freezerLevels: 2,
      specialDrawerLabel: 'Full-width temperature drawer',
      manufacturerUrl:
          'https://www.geappliances.com/appliance/GE-ENERGY-STAR-27-0-Cu-Ft-Fingerprint-Resistant-French-Door-Refrigerator-GNE27JYMFS',
    ),
    RefrigeratorModel(
      id: 'lg-lrflc2706s',
      brand: 'LG',
      modelNumber: 'LRFLC2706S',
      productName: 'Counter-Depth MAX French Door Refrigerator',
      layout: RefrigeratorLayoutKind.frenchDoor3,
      capacityCuFt: 26.5,
      refrigeratorShelves: 4,
      crisperDrawers: 2,
      pantryDrawers: 1,
      doorBins: 8,
      freezerLevels: 2,
      specialDrawerLabel: 'Glide N’ Serve® pantry drawer',
      manufacturerUrl:
          'https://www.lg.com/us/refrigerators/lg-lrflc2706s-french-3-door-refrigerator',
    ),
    RefrigeratorModel(
      id: 'maytag-mfi2570fez',
      brand: 'Maytag',
      modelNumber: 'MFI2570FEZ',
      productName: '25 cu. ft. French Door Refrigerator',
      layout: RefrigeratorLayoutKind.frenchDoor3,
      capacityCuFt: 25,
      refrigeratorShelves: 5,
      crisperDrawers: 2,
      pantryDrawers: 1,
      doorBins: 6,
      freezerLevels: 2,
      specialDrawerLabel: 'Wide-N-Fresh™ deli drawer',
      manufacturerUrl:
          'https://www.maytag.com/kitchen/refrigeration/refrigerators/french-door/p.36-inch-wide-french-door-refrigerator-with-powercold-feature-25-cu.-ft.mfi2570fez.html',
    ),
    RefrigeratorModel(
      id: 'samsung-rf28t5001sr',
      brand: 'Samsung',
      modelNumber: 'RF28T5001SR',
      productName: '28 cu. ft. Large Capacity French Door Refrigerator',
      layout: RefrigeratorLayoutKind.frenchDoor3,
      capacityCuFt: 28.2,
      refrigeratorShelves: 5,
      crisperDrawers: 2,
      pantryDrawers: 1,
      doorBins: 6,
      freezerLevels: 1,
      specialDrawerLabel: 'Full-width drawer',
      manufacturerUrl:
          'https://www.samsung.com/us/support/service/warranty/RF28T5001SR/AA/',
    ),
    RefrigeratorModel(
      id: 'whirlpool-wrs325sdhz',
      brand: 'Whirlpool',
      modelNumber: 'WRS325SDHZ',
      productName: '25 cu. ft. Side-by-Side Refrigerator',
      layout: RefrigeratorLayoutKind.sideBySide,
      capacityCuFt: 25,
      refrigeratorShelves: 4,
      crisperDrawers: 2,
      pantryDrawers: 1,
      doorBins: 5,
      freezerLevels: 3,
      specialDrawerLabel: 'Deli drawer',
      manufacturerUrl:
          'https://www.whirlpool.com/kitchen/refrigeration/refrigerators/side-by-side/p.36-inch-wide-side-by-side-refrigerator-25-cu.-ft.wrs325sdhz.html',
    ),
  ];

  static List<RefrigeratorModel> get alphabetized {
    final result = [...models]
      ..sort((left, right) => left.displayName.compareTo(right.displayName));
    return result;
  }

  static RefrigeratorModel? byId(String idOrLegacyName) {
    final query = idOrLegacyName.toLowerCase();
    for (final model in models) {
      if (model.id == query ||
          query.contains(model.modelNumber.toLowerCase())) {
        return model;
      }
    }
    return null;
  }
}
