import '../../domain/models/food_item.dart';

abstract interface class NotificationService {
  Future<void> initialize();
  Future<void> scheduleExpiryReminder(FoodItem item, {int warningDays = 3});
  Future<void> cancelReminder(String itemId);
}

/// Safe default used until a platform notification adapter is configured.
class NoopNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleExpiryReminder(
    FoodItem item, {
    int warningDays = 3,
  }) async {}

  @override
  Future<void> cancelReminder(String itemId) async {}
}
