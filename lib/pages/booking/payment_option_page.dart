import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../backend/database_service.dart';
import '../../backend/models/listing_row.dart';
import '../../backend/models/booking_row.dart';
import '../../backend/models/view_room_card_row.dart';
import '../../config/app_config.dart';
import '../../components/custom_alert.dart';

class PaymentOptionPage extends StatefulWidget {
  final String listingId;
  const PaymentOptionPage({super.key, required this.listingId});

  @override
  State<PaymentOptionPage> createState() => _PaymentOptionPageState();
}

class _PaymentOptionPageState extends State<PaymentOptionPage> {
  ListingRow? _listing;
  bool _loading = true;
  bool _paying = false;
  String _paymentMode = 'upi';
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _load();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_listing == null) return;
    try {
      final uid = AuthService.instance.currentUserUid;
      final paymentId =
          response.paymentId ?? 'pay_${DateTime.now().millisecondsSinceEpoch}';

      await DatabaseService.instance.insertBooking(
        BookingRow(
          id: uid,
          listingId: widget.listingId,
          paymentStatus: 'paid',
          paymentMode: _paymentMode,
          rentAmount: _listing!.price,
          bookingFees: _totalAmount.toStringAsFixed(0),
        ),
      );

      // Create a room card so it displays on the home page for the user
      await DatabaseService.instance.upsertViewRoomCard(
        ViewRoomCardRow(
          id: uid,
          propertyId: widget.listingId,
          propertyName: _listing!.propertyName,
          roomType: _listing!.roomType,
          status: 'active',
          rentAmount: _listing!.price,
          rentDueDate: DateTime.now().add(const Duration(days: 30)),
        ),
      );

      // Change listing status to booked so it isn't shown to others
      await DatabaseService.instance.updateListing(widget.listingId, {
        'status': 'booked',
      });

      if (mounted) {
        context.go(
          '/book-confirm?listingId=${widget.listingId}'
          '&totalPaid=$_totalAmount'
          '&paymentId=$paymentId',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomAlert.showToast(context, 'Database Error: $e', type: AlertType.error);
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      CustomAlert.showToast(context, 'Payment Failed: ${response.message}', type: AlertType.error);
    }
    setState(() => _paying = false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      CustomAlert.showToast(context, 'External wallet selected: ${response.walletName}');
    }
  }

  Future<void> _load() async {
    try {
      _listing = await DatabaseService.instance.getListing(widget.listingId);
    } catch (e) {
      if (mounted) {
        CustomAlert.showToast(context, 'Error loading listing: $e', type: AlertType.error);
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  double get _brokerage {
    return (_listing?.price ?? 0) * 0.05;
  }

  double get _totalAmount {
    if (_listing == null) return 0;
    return (_listing!.price ?? 0) +
        (_listing!.securityDeposit ?? 0) +
        (_listing!.monthlyMaintenance ?? 0) +
        _brokerage;
  }

  void _pay() {
    if (_totalAmount <= 0) {
      if (mounted) {
         CustomAlert.showToast(context, 'Invalid amount', type: AlertType.error);
      }
      return;
    }
    setState(() => _paying = true);
    final options = {
      'key': AppConfig.razorpayKeyId,
      'amount': (_totalAmount * 100).toInt(),
      'name': 'Rento',
      'description': 'Booking for ${_listing?.propertyName ?? "Property"}',
      'timeout': 60,
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() => _paying = false);
      if (mounted) {
        CustomAlert.showToast(context, 'Error starting payment', type: AlertType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_listing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: const Center(child: Text('Listing not found')),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Price Breakdown card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Price Breakdown',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          _breakdownRow(
                            'Monthly Rent',
                            '₹${_listing!.price ?? 0}',
                            theme,
                          ),
                          const SizedBox(height: 12),
                          _breakdownRow(
                            'Security Deposit (Refundable)',
                            '₹${_listing!.securityDeposit ?? 0}',
                            theme,
                          ),
                          const SizedBox(height: 12),
                          _breakdownRow(
                            'Maintenance',
                            '₹${_listing!.monthlyMaintenance ?? 0}',
                            theme,
                          ),
                          const SizedBox(height: 12),
                          _breakdownRow(
                            'Brokerage (one-time)',
                            '₹${_brokerage.toStringAsFixed(0)}',
                            theme,
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '₹${_totalAmount.toStringAsFixed(0)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Select Payment Method
                    Text(
                      'Select Payment Method',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Credit/Debit Card
                    _PaymentMethodCard(
                      icon: Icons.credit_card,
                      title: 'Credit/Debit Card',
                      subtitle: 'Pay with Visa, Mastercard, etc.',
                      selected: _paymentMode == 'card',
                      onTap: () => setState(() => _paymentMode = 'card'),
                    ),
                    const SizedBox(height: 16),

                    // Bank Transfer
                    _PaymentMethodCard(
                      icon: Icons.account_balance,
                      title: 'Bank Transfer',
                      subtitle: 'Pay directly from your bank account',
                      selected: _paymentMode == 'bank',
                      onTap: () => setState(() => _paymentMode = 'bank'),
                    ),
                    const SizedBox(height: 16),

                    // UPI
                    _PaymentMethodCard(
                      icon: Icons.payment,
                      title: 'UPI',
                      subtitle: 'Apple Pay, Google Pay, PayPal',
                      selected: _paymentMode == 'upi',
                      onTap: () => setState(() => _paymentMode = 'upi'),
                    ),
                    const SizedBox(height: 16),

                    // Info row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Free cancellation until 24 hours before check-in',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // Bottom bar
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '₹${_totalAmount.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _paying ? null : _pay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.onSurface,
                      foregroundColor: theme.colorScheme.surface,
                      elevation: 2,
                      padding: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      textStyle: theme.textTheme.titleLarge,
                    ),
                    child: _paying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Pay Now'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Checkbox(
              value: selected,
              onChanged: (_) => onTap(),
              activeColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(width: 2, color: Colors.grey[300]!),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
