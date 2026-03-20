import 'package:flutter/material.dart';

/// Simple two-locale localisation (en, hi) with in-memory maps.
class RentoLocalizations {
  final Locale locale;
  RentoLocalizations(this.locale);

  static RentoLocalizations of(BuildContext context) {
    return Localizations.of<RentoLocalizations>(context, RentoLocalizations)!;
  }

  static const LocalizationsDelegate<RentoLocalizations> delegate =
      _RentoLocalizationsDelegate();

  static const List<Locale> supportedLocales = [Locale('en'), Locale('hi')];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'Rento',
      'login': 'Login',
      'signUp': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'forgotPassword': 'Forgot Password?',
      'createAccount': 'Create Account',
      'alreadyHaveAccount': 'Already have an account?',
      'dontHaveAccount': "Don't have an account?",
      'home': 'Home',
      'map': 'Map',
      'addProperty': 'Add Property',
      'messages': 'Messages',
      'profile': 'Profile',
      'search': 'Search properties...',
      'categories': 'Categories',
      'featured': 'Featured Properties',
      'seeAll': 'See All',
      'propertyDetails': 'Property Details',
      'bookNow': 'Book Now',
      'payRent': 'Pay Rent',
      'rentAmount': 'Rent Amount',
      'securityDeposit': 'Security Deposit',
      'amenities': 'Amenities',
      'description': 'Description',
      'location': 'Location',
      'propertyType': 'Property Type',
      'roomType': 'Room Type',
      'furnishing': 'Furnishing',
      'price': 'Price',
      'perMonth': '/month',
      'beds': 'Beds',
      'washrooms': 'Washrooms',
      'area': 'Area',
      'editProfile': 'Edit Profile',
      'settings': 'Settings',
      'language': 'Language',
      'darkMode': 'Dark Mode',
      'notifications': 'Notifications',
      'support': 'Support',
      'logout': 'Logout',
      'selectRole': 'Select Your Role',
      'rentee': 'Rentee',
      'landlord': 'Landlord',
      'renteeDesc': 'I\'m looking for a place to rent',
      'landlordDesc': 'I want to list my property',
      'continue_': 'Continue',
      'cancel': 'Cancel',
      'save': 'Save',
      'name': 'Full Name',
      'phone': 'Phone Number',
      'address': 'Address',
      'city': 'City',
      'state': 'State',
      'emergencyNumber': 'Emergency Number',
      'paymentHistory': 'Payment History',
      'myBookings': 'My Bookings',
      'favourites': 'Favourites',
      'noResults': 'No results found',
      'loading': 'Loading...',
      'error': 'Something went wrong',
      'retry': 'Retry',
      'bookingConfirmed': 'Booking Confirmed!',
      'paymentSuccessful': 'Payment Successful',
      'filter': 'Filter',
      'apply': 'Apply',
      'reset': 'Reset',
      'minPrice': 'Min Price',
      'maxPrice': 'Max Price',
      'updatePassword': 'Update Password',
      'newPassword': 'New Password',
      'confirmPassword': 'Confirm Password',
    },
    'hi': {
      'appName': 'रेंटो',
      'login': 'लॉगिन',
      'signUp': 'साइन अप',
      'email': 'ईमेल',
      'password': 'पासवर्ड',
      'forgotPassword': 'पासवर्ड भूल गए?',
      'createAccount': 'अकाउंट बनाएं',
      'alreadyHaveAccount': 'पहले से अकाउंट है?',
      'dontHaveAccount': 'अकाउंट नहीं है?',
      'home': 'होम',
      'map': 'मैप',
      'addProperty': 'प्रॉपर्टी जोड़ें',
      'messages': 'संदेश',
      'profile': 'प्रोफ़ाइल',
      'search': 'प्रॉपर्टी खोजें...',
      'categories': 'श्रेणियां',
      'featured': 'फ़ीचर्ड प्रॉपर्टी',
      'seeAll': 'सभी देखें',
      'propertyDetails': 'प्रॉपर्टी विवरण',
      'bookNow': 'अभी बुक करें',
      'payRent': 'किराया भुगतान',
      'rentAmount': 'किराया राशि',
      'securityDeposit': 'सुरक्षा जमा',
      'amenities': 'सुविधाएं',
      'description': 'विवरण',
      'location': 'स्थान',
      'propertyType': 'प्रॉपर्टी प्रकार',
      'roomType': 'कमरे का प्रकार',
      'furnishing': 'फर्निशिंग',
      'price': 'कीमत',
      'perMonth': '/माह',
      'beds': 'बेड',
      'washrooms': 'वॉशरूम',
      'area': 'क्षेत्रफल',
      'editProfile': 'प्रोफ़ाइल संपादित करें',
      'settings': 'सेटिंग्स',
      'language': 'भाषा',
      'darkMode': 'डार्क मोड',
      'notifications': 'सूचनाएं',
      'support': 'सहायता',
      'logout': 'लॉगआउट',
      'selectRole': 'अपनी भूमिका चुनें',
      'rentee': 'किरायेदार',
      'landlord': 'मकान मालिक',
      'renteeDesc': 'मैं किराये पर रहने की जगह ढूंढ रहा हूं',
      'landlordDesc': 'मैं अपनी प्रॉपर्टी लिस्ट करना चाहता हूं',
      'continue_': 'जारी रखें',
      'cancel': 'रद्द करें',
      'save': 'सहेजें',
      'name': 'पूरा नाम',
      'phone': 'फ़ोन नंबर',
      'address': 'पता',
      'city': 'शहर',
      'state': 'राज्य',
      'emergencyNumber': 'आपातकालीन नंबर',
      'paymentHistory': 'भुगतान इतिहास',
      'myBookings': 'मेरी बुकिंग',
      'favourites': 'पसंदीदा',
      'noResults': 'कोई परिणाम नहीं मिला',
      'loading': 'लोड हो रहा है...',
      'error': 'कुछ गलत हो गया',
      'retry': 'पुनः प्रयास करें',
      'bookingConfirmed': 'बुकिंग की पुष्टि हो गई!',
      'paymentSuccessful': 'भुगतान सफल',
      'filter': 'फ़िल्टर',
      'apply': 'लागू करें',
      'reset': 'रीसेट',
      'minPrice': 'न्यूनतम कीमत',
      'maxPrice': 'अधिकतम कीमत',
      'updatePassword': 'पासवर्ड अपडेट करें',
      'newPassword': 'नया पासवर्ड',
      'confirmPassword': 'पासवर्ड की पुष्टि करें',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class _RentoLocalizationsDelegate
    extends LocalizationsDelegate<RentoLocalizations> {
  const _RentoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);

  @override
  Future<RentoLocalizations> load(Locale locale) async =>
      RentoLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate old) => false;
}
