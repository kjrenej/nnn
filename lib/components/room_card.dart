import 'package:flutter/material.dart';

import '../../backend/models/view_room_card_row.dart';
import '../../theme/rento_theme.dart';
import 'package:intl/intl.dart';

/// Card showing the rentee's active room with due date — enhanced design.
class RoomCard extends StatelessWidget {
  final ViewRoomCardRow card;
  final VoidCallback? onPayRent;

  const RoomCard({super.key, required this.card, this.onPayRent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDue =
        card.rentDueDate != null &&
        card.rentDueDate!.isBefore(DateTime.now().add(const Duration(days: 3)));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? RentoTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: RentoTheme.cardShadow,
        border: isDue
            ? Border.all(
                color: RentoTheme.accentColor.withValues(alpha: 0.3),
                width: 1.5,
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    card.propertyName ?? 'Property',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: card.status == 'active'
                        ? const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                          )
                        : null,
                    color: card.status != 'active' ? Colors.grey[200] : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    card.status ?? 'active',
                    style: TextStyle(
                      color: card.status == 'active'
                          ? Colors.white
                          : Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (card.roomType != null)
              Row(
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    card.roomType!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : RentoTheme.primaryColor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rent Amount',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.rentAmount != null ? '₹${card.rentAmount}' : 'N/A',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: RentoTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 36,
                    width: 1,
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Due Date',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.rentDueDate != null
                            ? DateFormat(
                                'dd MMM yyyy',
                              ).format(card.rentDueDate!)
                            : 'N/A',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isDue ? RentoTheme.accentColor : null,
                          fontWeight: isDue ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onPayRent != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: RentoTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: RentoTheme.primaryColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: onPayRent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Pay Rent'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
