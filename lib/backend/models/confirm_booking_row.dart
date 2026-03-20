/// Typed model for the `confirm_booking_page` table.
class ConfirmBookingRow {
  final String id;
  final DateTime createdAt;
  String? propertyName;
  String? roomType;
  String? owner;
  int? contactNumber;
  double? totalPaid;
  String? address;

  ConfirmBookingRow({
    required this.id,
    DateTime? createdAt,
    this.propertyName,
    this.roomType,
    this.owner,
    this.contactNumber,
    this.totalPaid,
    this.address,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ConfirmBookingRow.fromJson(Map<String, dynamic> json) {
    return ConfirmBookingRow(
      id: json['id'] as String,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      propertyName: json['property_name'] as String?,
      roomType: json['room_type'] as String?,
      owner: json['owner'] as String?,
      contactNumber: (json['contact_number'] as num?)?.toInt(),
      totalPaid: (json['total_paid'] as num?)?.toDouble(),
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      if (propertyName != null) 'property_name': propertyName,
      if (roomType != null) 'room_type': roomType,
      if (owner != null) 'owner': owner,
      if (contactNumber != null) 'contact_number': contactNumber,
      if (totalPaid != null) 'total_paid': totalPaid,
      if (address != null) 'address': address,
    };
  }
}
