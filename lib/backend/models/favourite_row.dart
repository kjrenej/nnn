/// Typed model for the `favourite` table.
class FavouriteRow {
  final String id;
  final DateTime createdAt;
  String? favourite;

  FavouriteRow({required this.id, DateTime? createdAt, this.favourite})
    : createdAt = createdAt ?? DateTime.now();

  factory FavouriteRow.fromJson(Map<String, dynamic> json) {
    return FavouriteRow(
      id: json['id'] as String,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      favourite: json['favourite'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      if (favourite != null) 'favourite': favourite,
    };
  }
}
