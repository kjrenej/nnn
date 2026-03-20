import '../backend/models/models.dart';
import '../backend/database_service.dart';

/// Domain service that checks rent due dates and produces reminders.
class RentReminderService {
  RentReminderService._();
  static final RentReminderService instance = RentReminderService._();

  final _db = DatabaseService.instance;

  /// Returns room cards whose rent is due within [daysAhead] days.
  Future<List<ViewRoomCardRow>> getDueReminders(
    String uid, {
    int daysAhead = 3,
  }) async {
    final cards = await _db.getViewRoomCards(uid);
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: daysAhead));

    return cards.where((c) {
      if (c.rentDueDate == null) return false;
      return c.rentDueDate!.isBefore(cutoff) &&
          c.rentDueDate!.isAfter(now.subtract(const Duration(days: 1)));
    }).toList();
  }

  /// Advances the due date by one month after rent payment.
  Future<void> advanceDueDate(String cardId) async {
    final cards = await _db.getViewRoomCards(cardId);
    if (cards.isEmpty) return;
    final card = cards.first;
    final currentDue = card.rentDueDate ?? DateTime.now();
    final nextDue = DateTime(
      currentDue.year,
      currentDue.month + 1,
      currentDue.day,
    );
    await _db.updateViewRoomCard(cardId, {
      'rent due_date': nextDue.toIso8601String(),
    });
  }
}
