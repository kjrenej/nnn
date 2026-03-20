// App-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'Rento';

  // Roles
  static const String roleRentee = 'rentee';
  static const String roleLandlord = 'landlord';

  // Property types
  static const List<String> propertyTypes = ['House', 'Flat', 'Hostel', 'PG'];

  // Room types
  static const List<String> roomTypes = ['Single', 'Double', 'Triple'];

  // Furnishing
  static const List<String> furnishingTypes = [
    'Furnished',
    'Semi-Furnished',
    'Unfurnished',
  ];

  // Conditioning
  static const List<String> conditioningOptions = ['AC', 'Non-AC'];

  // Washroom types
  static const List<String> washroomTypes = ['Attached', 'Common'];

  // Meal options
  static const List<String> mealOptions = ['Included', 'Not-Included'];

  // Property for
  static const List<String> propertyForOptions = ['Boys', 'Girls', 'Both'];

  // Payment modes
  static const List<String> paymentModes = ['upi', 'card', 'bank'];

  // Amenities
  static const List<String> amenities = [
    'WiFi',
    'Parking',
    'Laundry',
    'Gym',
    'Swimming Pool',
    'Power Backup',
    'Security',
    'CCTV',
    'Elevator',
    'Garden',
    'Water Supply',
    'Gas Pipeline',
  ];
}
