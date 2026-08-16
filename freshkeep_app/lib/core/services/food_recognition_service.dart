import '../../domain/models/food_item.dart';

class RecognizedFood {
  const RecognizedFood({
    required this.name,
    this.expirationDate,
    this.category,
  });
  final String name;
  final DateTime? expirationDate;
  final FoodCategory? category;
}

abstract interface class FoodRecognitionService {
  Future<RecognizedFood?> recognize(String imagePath);
}

class UnsupportedFoodRecognitionService implements FoodRecognitionService {
  @override
  Future<RecognizedFood?> recognize(String imagePath) async => null;
}
