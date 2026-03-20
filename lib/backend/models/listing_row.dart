/// Typed model for the `listings` table in Supabase.
class ListingRow {
  final String id;
  String? propertyName;
  String? propertyType;
  String? description;
  String? propertyAddress;
  String? city;
  String? state;
  int? price;
  List<String> images;
  List<String> amenities;
  String? roomType;
  int? beds;
  int? halls;
  int? kitchen;
  String? washrooms;
  int? securityDeposit;
  int? monthlyMaintenance;
  bool? parkingFee;
  bool? utilitiesIncluded;
  String? propertyManagementPreferences;
  int? pincode;
  String status;
  String? floorInHouse;
  int? propertyOnFloor;
  int? totalFloor;
  String? furnishing;
  String? area;
  String? areaMeasuringUnit;
  String? conditioning;
  int? totalRoom;
  int? roomAvailable;
  String? propertyFor;
  String? mealOption;
  double? latitude;
  double? longitude;

  ListingRow({
    required this.id,
    this.propertyName,
    this.propertyType,
    this.description,
    this.propertyAddress,
    this.city,
    this.state,
    this.price,
    List<String>? images,
    List<String>? amenities,
    this.roomType,
    this.beds,
    this.halls,
    this.kitchen,
    this.washrooms,
    this.securityDeposit,
    this.monthlyMaintenance,
    this.parkingFee,
    this.utilitiesIncluded,
    this.propertyManagementPreferences,
    this.pincode,
    this.status = 'active',
    this.floorInHouse,
    this.propertyOnFloor,
    this.totalFloor,
    this.furnishing,
    this.area,
    this.areaMeasuringUnit,
    this.conditioning,
    this.totalRoom,
    this.roomAvailable,
    this.propertyFor,
    this.mealOption,
    this.latitude,
    this.longitude,
  }) : images = images ?? [],
       amenities = amenities ?? [];

  factory ListingRow.fromJson(Map<String, dynamic> json) {
    return ListingRow(
      id: json['id']?.toString() ?? '',
      propertyName: json['property_name'] as String?,
      propertyType: json['property_type'] as String?,
      description: json['description'] as String?,
      propertyAddress: json['property_add'] as String?,
      city: json['prop_city'] as String?,
      state: json['prop_state'] as String?,
      price: (json['price'] as num?)?.toInt(),
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      amenities:
          (json['aminities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      roomType: json['room_type'] as String?,
      beds: (json['beds'] as num?)?.toInt(),
      halls: (json['halls'] as num?)?.toInt(),
      kitchen: (json['kitchen'] as num?)?.toInt(),
      washrooms: json['washrooms'] as String?,
      securityDeposit: (json['security_deposit'] as num?)?.toInt(),
      monthlyMaintenance: (json['monthly_maintence'] as num?)?.toInt(),
      parkingFee: json['parking_fee'] as bool?,
      utilitiesIncluded: json['utilies_included'] as bool?,
      propertyManagementPreferences:
          json['property_management_prefences'] as String?,
      pincode: (json['pincode'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'active',
      floorInHouse: json['Floor in house'] as String?,
      propertyOnFloor: (json['property on floor'] as num?)?.toInt(),
      totalFloor: (json['total floor'] as num?)?.toInt(),
      furnishing: json['furnishing'] as String?,
      area: json['area'] as String?,
      areaMeasuringUnit: json['area_measuringunit'] as String?,
      conditioning: json['conditioning'] as String?,
      totalRoom: (json['total_room'] as num?)?.toInt(),
      roomAvailable: (json['room_available'] as num?)?.toInt(),
      propertyFor: json['propety_for'] as String?,
      mealOption: json['meal_option'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (propertyName != null) 'property_name': propertyName,
      if (propertyType != null) 'property_type': propertyType,
      if (description != null) 'description': description,
      if (propertyAddress != null) 'property_add': propertyAddress,
      if (city != null) 'prop_city': city,
      if (state != null) 'prop_state': state,
      if (price != null) 'price': price,
      'images': images,
      'aminities': amenities,
      if (roomType != null) 'room_type': roomType,
      if (beds != null) 'beds': beds,
      if (halls != null) 'halls': halls,
      if (kitchen != null) 'kitchen': kitchen,
      if (washrooms != null) 'washrooms': washrooms,
      if (securityDeposit != null) 'security_deposit': securityDeposit,
      if (monthlyMaintenance != null) 'monthly_maintence': monthlyMaintenance,
      if (parkingFee != null) 'parking_fee': parkingFee,
      if (utilitiesIncluded != null) 'utilies_included': utilitiesIncluded,
      if (propertyManagementPreferences != null)
        'property_management_prefences': propertyManagementPreferences,
      if (pincode != null) 'pincode': pincode,
      'status': status,
      if (floorInHouse != null) 'Floor in house': floorInHouse,
      if (propertyOnFloor != null) 'property on floor': propertyOnFloor,
      if (totalFloor != null) 'total floor': totalFloor,
      if (furnishing != null) 'furnishing': furnishing,
      if (area != null) 'area': area,
      if (areaMeasuringUnit != null) 'area_measuringunit': areaMeasuringUnit,
      if (conditioning != null) 'conditioning': conditioning,
      if (totalRoom != null) 'total_room': totalRoom,
      if (roomAvailable != null) 'room_available': roomAvailable,
      if (propertyFor != null) 'propety_for': propertyFor,
      if (mealOption != null) 'meal_option': mealOption,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
