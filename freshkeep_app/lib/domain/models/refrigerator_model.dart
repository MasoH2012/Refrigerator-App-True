enum RefrigeratorLayoutKind {
  frenchDoor3,
  frenchDoor4,
  sideBySide,
  topFreezer,
  bottomFreezer,
  compact,
}

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
        RefrigeratorLayoutKind.topFreezer => 'Top-freezer',
        RefrigeratorLayoutKind.bottomFreezer => 'Bottom-freezer',
        RefrigeratorLayoutKind.compact => 'Compact / mini fridge',
      };
}

abstract final class RefrigeratorCatalog {
  static const models = <RefrigeratorModel>[
    RefrigeratorModel(
      id: 'frigidaire-fftr1821ts',
      brand: 'Frigidaire',
      modelNumber: 'FFTR1821TS',
      productName: '18 cu. ft. Top-Freezer Refrigerator',
      layout: RefrigeratorLayoutKind.topFreezer,
      capacityCuFt: 18.3,
      refrigeratorShelves: 3,
      crisperDrawers: 2,
      pantryDrawers: 0,
      doorBins: 4,
      freezerLevels: 2,
      specialDrawerLabel: 'Humidity-controlled crispers',
      manufacturerUrl:
          'https://www.frigidaire.com/en/kitchen/refrigerators/top-freezer-refrigerators/FFTR1821TS',
    ),
    RefrigeratorModel(
      id: 'ge-gts19kmnres',
      brand: 'GE',
      modelNumber: 'GTS19KMNRES',
      productName: '19.2 cu. ft. Top-Freezer Refrigerator',
      layout: RefrigeratorLayoutKind.topFreezer,
      capacityCuFt: 19.2,
      refrigeratorShelves: 3,
      crisperDrawers: 2,
      pantryDrawers: 0,
      doorBins: 4,
      freezerLevels: 2,
      specialDrawerLabel: 'Adjustable glass shelves',
      manufacturerUrl:
          'https://www.geappliances.com/appliance/GE-19-2-Cu-Ft-Top-Freezer-Refrigerator-GTS19KMNRES',
    ),
    RefrigeratorModel(
      id: 'ge-gde03ggkbb',
      brand: 'GE',
      modelNumber: 'GDE03GGKBB',
      productName: '3.1 cu. ft. Compact Refrigerator',
      layout: RefrigeratorLayoutKind.compact,
      capacityCuFt: 3.1,
      refrigeratorShelves: 2,
      crisperDrawers: 1,
      pantryDrawers: 0,
      doorBins: 2,
      freezerLevels: 1,
      specialDrawerLabel: 'Separate chiller compartment',
      manufacturerUrl:
          'https://www.geappliances.com/appliance/GE-3-1-Cu-Ft-Compact-Refrigerator-GDE03GGKBB',
    ),
    RefrigeratorModel(
      id: 'lg-lrdcs2603s',
      brand: 'LG',
      modelNumber: 'LRDCS2603S',
      productName: '25.5 cu. ft. Bottom-Freezer Refrigerator',
      layout: RefrigeratorLayoutKind.bottomFreezer,
      capacityCuFt: 25.5,
      refrigeratorShelves: 4,
      crisperDrawers: 2,
      pantryDrawers: 1,
      doorBins: 6,
      freezerLevels: 2,
      specialDrawerLabel: 'Glide N’ Serve® drawer',
      manufacturerUrl:
          'https://www.lg.com/us/refrigerators/lg-lrdcs2603s-bottom-freezer-refrigerator',
    ),
    RefrigeratorModel(
      id: 'frigidaire-ffps4533um',
      brand: 'Frigidaire',
      modelNumber: 'FFPS4533UM',
      productName: '4.5 cu. ft. Compact Refrigerator',
      layout: RefrigeratorLayoutKind.compact,
      capacityCuFt: 4.5,
      refrigeratorShelves: 2,
      crisperDrawers: 1,
      pantryDrawers: 0,
      doorBins: 3,
      freezerLevels: 1,
      specialDrawerLabel: 'Separate freezer compartment',
      manufacturerUrl:
          'https://www.frigidaire.com/en/kitchen/refrigerators/compact-refrigerators/FFPS4533UM',
    ),
    RefrigeratorModel(
      id: 'amana-asi2175grs',
      brand: 'Amana',
      modelNumber: 'ASI2175GRS',
      productName: '21 cu. ft. Side-by-Side Refrigerator',
      layout: RefrigeratorLayoutKind.sideBySide,
      capacityCuFt: 21.4,
      refrigeratorShelves: 4,
      crisperDrawers: 2,
      pantryDrawers: 1,
      doorBins: 5,
      freezerLevels: 3,
      specialDrawerLabel: 'Humidity-controlled crispers',
      manufacturerUrl:
          'https://www.amana.com/refrigeration/refrigerators/side-by-side-refrigerators.html',
    ),
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
      id: 'cafe-cve28dm5ns5',
      brand: 'Café',
      modelNumber: 'CVE28DM5NS5',
      productName: '28.7 cu. ft. Smart French-Door Refrigerator',
      layout: RefrigeratorLayoutKind.frenchDoor3,
      capacityCuFt: 28.7,
      refrigeratorShelves: 5,
      crisperDrawers: 2,
      pantryDrawers: 1,
      doorBins: 6,
      freezerLevels: 2,
      specialDrawerLabel: 'Convertible temperature drawer',
      manufacturerUrl:
          'https://www.cafeappliances.com/appliance/Cafe-ENERGY-STAR-28-7-Cu-Ft-Smart-Fingerprint-Resistant-French-Door-Refrigerator-CVE28DM5NS5',
    ),
    RefrigeratorModel(
      id: 'electrolux-ermc2295as',
      brand: 'Electrolux',
      modelNumber: 'ERMC2295AS',
      productName: '22.9 cu. ft. French-Door Refrigerator',
      layout: RefrigeratorLayoutKind.frenchDoor3,
      capacityCuFt: 22.9,
      refrigeratorShelves: 4,
      crisperDrawers: 2,
      pantryDrawers: 1,
      doorBins: 6,
      freezerLevels: 2,
      specialDrawerLabel: 'Custom-Flex® door',
      manufacturerUrl:
          'https://www.electrolux.com/en/kitchen-appliances/refrigerators/french-door-refrigerators/',
    ),
    RefrigeratorModel(
      id: 'frigidaire-frfg272laf',
      brand: 'Frigidaire',
      modelNumber: 'FRFG272LAF',
      productName: '26.8 cu. ft. Gallery French-Door Refrigerator',
      layout: RefrigeratorLayoutKind.frenchDoor3,
      capacityCuFt: 26.8,
      refrigeratorShelves: 5,
      crisperDrawers: 2,
      pantryDrawers: 1,
      doorBins: 6,
      freezerLevels: 2,
      specialDrawerLabel: 'Full-width deli drawer',
      manufacturerUrl:
          'https://www.frigidaire.com/en/kitchen/refrigerators/french-door-refrigerators/FRFG272LAF',
    ),
    RefrigeratorModel(
      id: 'hisense-hrf266n6cse',
      brand: 'Hisense',
      modelNumber: 'HRF266N6CSE',
      productName: '26.6 cu. ft. French-Door Refrigerator',
      layout: RefrigeratorLayoutKind.frenchDoor3,
      capacityCuFt: 26.6,
      refrigeratorShelves: 4,
      crisperDrawers: 2,
      pantryDrawers: 1,
      doorBins: 6,
      freezerLevels: 2,
      specialDrawerLabel: 'My Fresh Choice® drawer',
      manufacturerUrl:
          'https://www.hisense-usa.com/refrigerators/french-door-refrigerators',
    ),
    RefrigeratorModel(
      id: 'kitchenaid-krff507hps',
      brand: 'KitchenAid',
      modelNumber: 'KRFF507HPS',
      productName: '26.8 cu. ft. Counter-Depth French-Door Refrigerator',
      layout: RefrigeratorLayoutKind.frenchDoor3,
      capacityCuFt: 26.8,
      refrigeratorShelves: 5,
      crisperDrawers: 2,
      pantryDrawers: 1,
      doorBins: 6,
      freezerLevels: 2,
      specialDrawerLabel: 'ExtendFresh™ temperature-controlled drawer',
      manufacturerUrl:
          'https://www.kitchenaid.com/major-appliances/refrigeration/refrigerators/french-door/p.36-inch-wide-counter-depth-french-door-refrigerator-with-interior-water-dispenser.krff507hps.html',
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
      id: 'lg-lrsxs2706s',
      brand: 'LG',
      modelNumber: 'LRSXS2706S',
      productName: '27 cu. ft. Side-by-Side Refrigerator',
      layout: RefrigeratorLayoutKind.sideBySide,
      capacityCuFt: 27.0,
      refrigeratorShelves: 4,
      crisperDrawers: 2,
      pantryDrawers: 1,
      doorBins: 8,
      freezerLevels: 4,
      specialDrawerLabel: 'Glide N’ Serve® drawer',
      manufacturerUrl:
          'https://www.lg.com/us/refrigerators/lg-lrsxs2706s-side-by-side-refrigerator',
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
      id: 'samsung-rs28a5f1sr',
      brand: 'Samsung',
      modelNumber: 'RS28A5F1SR',
      productName: '28 cu. ft. Side-by-Side Refrigerator',
      layout: RefrigeratorLayoutKind.sideBySide,
      capacityCuFt: 28.0,
      refrigeratorShelves: 4,
      crisperDrawers: 2,
      pantryDrawers: 1,
      doorBins: 8,
      freezerLevels: 4,
      specialDrawerLabel: 'FlexZone™ beverage center',
      manufacturerUrl:
          'https://www.samsung.com/us/home-appliances/refrigerators/side-by-side/',
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
    RefrigeratorModel(
      id: 'whirlpool-wrb322dmbm',
      brand: 'Whirlpool',
      modelNumber: 'WRB322DMBM',
      productName: '22 cu. ft. Bottom-Freezer Refrigerator',
      layout: RefrigeratorLayoutKind.bottomFreezer,
      capacityCuFt: 22.1,
      refrigeratorShelves: 4,
      crisperDrawers: 2,
      pantryDrawers: 1,
      doorBins: 5,
      freezerLevels: 3,
      specialDrawerLabel: 'Flexi-Slide™ bin',
      manufacturerUrl:
          'https://www.whirlpool.com/kitchen/refrigeration/refrigerators/bottom-freezer/p.30-inch-wide-bottom-freezer-refrigerator-22-cu.-ft.wrb322dmbm.html',
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
