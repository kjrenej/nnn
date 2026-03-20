import 'package:flutter/material.dart';
import '../../auth/auth_service.dart';
import '../../backend/database_service.dart';
import '../../backend/models/booking_row.dart';
import '../../components/common_widgets.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  List<BookingRow> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _bookings = await DatabaseService.instance.getBookingsForUser(
        AuthService.instance.currentUserUid,
      );
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
          ? const EmptyState(icon: Icons.receipt_long, title: 'No payments yet')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _bookings.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final b = _bookings[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: b.paymentStatus == 'paid'
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      child: Icon(
                        b.paymentStatus == 'paid' ? Icons.check : Icons.pending,
                        color: b.paymentStatus == 'paid'
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                    title: Text(
                      '₹${b.rentAmount ?? b.bookingFees ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${b.paymentMode ?? 'N/A'} • ${b.paymentStatus ?? 'pending'}',
                    ),
                    trailing: Text(
                      b.createdAt.toString().substring(0, 10),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
