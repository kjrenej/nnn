/// Typed model for the `booking` table.
class BookingRow {
  final String id;
  final DateTime createdAt;
  String? listingId;
  String? paymentStatus;
  String? paymentMode;
  int? rentAmount;
  String? bookingFees;

  BookingRow({
    required this.id,
    DateTime? createdAt,
    this.listingId,
    this.paymentStatus,
    this.paymentMode,
    this.rentAmount,
    this.bookingFees,
  }) : createdAt = createdAt ?? DateTime.now();

  factory BookingRow.fromJson(Map<String, dynamic> json) {
    return BookingRow(
      id: json['id'] as String,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      listingId: json['listing_id'] as String?,
      paymentStatus: json['payment_status'] as String?,
      paymentMode: json['payment_mode'] as String?,
      rentAmount: (json['rent_amount'] as num?)?.toInt(),
      bookingFees: json['booking_fees'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      if (listingId != null) 'listing_id': listingId,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (paymentMode != null) 'payment_mode': paymentMode,
      if (rentAmount != null) 'rent_amount': rentAmount,
      if (bookingFees != null) 'booking_fees': bookingFees,
    };
  }
}
