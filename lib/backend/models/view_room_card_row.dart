/// Typed model for the `view_room_card` table.
class ViewRoomCardRow {
  final String id;
  final DateTime createdAt;
  String? propertyName;
  String? roomType;
  String? status;
  DateTime? rentDueDate;
  int? rentAmount;
  String? propertyId;

  ViewRoomCardRow({
    required this.id,
    DateTime? createdAt,
    this.propertyName,
    this.roomType,
    this.status,
    this.rentDueDate,
    this.rentAmount,
    this.propertyId,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ViewRoomCardRow.fromJson(Map<String, dynamic> json) {
    return ViewRoomCardRow(
      id: json['id']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      propertyName: json['property name'] as String?,
      roomType: json['room type'] as String?,
      status: json['status'] as String?,
      rentDueDate: DateTime.tryParse(json['rent due_date']?.toString() ?? ''),
      rentAmount: (json['rent amount'] as num?)?.toInt(),
      propertyId: json['property_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      if (propertyName != null) 'property name': propertyName,
      if (roomType != null) 'room type': roomType,
      if (status != null) 'status': status,
      if (rentDueDate != null) 'rent due_date': rentDueDate!.toIso8601String(),
      if (rentAmount != null) 'rent amount': rentAmount,
      if (propertyId != null) 'property_id': propertyId,
    };
  }
}
