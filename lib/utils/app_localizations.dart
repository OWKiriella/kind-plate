import 'package:flutter/material.dart';
import '../services/translation_service.dart';

class AppLocalizations {
  final Locale locale;
  final TranslationService _translationService = TranslationService();
  Map<String, String>? _dynamicTranslations;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  static const _localizedValues = {
    'en': {
      'welcome': 'WELCOME',
      'kindnessPlate': 'Your Kindness Can Fill a Plate!',
      'getStarted': 'Get Started',
      'selectLanguage': 'Select Language',
      'languageChanged': 'Language changed to English',
      'home': 'Home',
      'donations': 'Donations',
      'donation': 'Donation',
      'details': 'Details',
      'account': 'Account',
      'foodInNeed': 'Food in need',
      'requestDonation': 'Request Donation',
      'donateNow': 'Donate Now',
      'urgencyStatus': 'Urgency status',
      'becomeFoodDonor': 'Become a Food Donor Today',
      'latestCampaigns': 'Latest Campaigns',
      'changeLanguage': 'Change language',
      'edit': 'Edit',
      'name': 'Name',
      'email': 'Email',
      'password': 'Password',
      'newPassword': 'New Password',
      'location': 'Location',
      'welcomeToKindPlate': 'Welcome to Kind-Plate',
      'foodInsecurityTitle': 'Food Insecurity and Malnutrition in Sri Lanka',
      'foodInsecurityDescription': '6.7 million Sri Lankans are struggling to eat enough. Your help today can bring hope and nourishment to those in need.',
      'latestUpdates': 'Latest Updates',
      'seeAll': 'See All',
      'noPostsAvailable': 'No posts available',
      'becomeAFoodDonor': 'Become a',
      'foodDonorToday': 'Food Donor Today',
      'donateFood': 'Donate Food',
      'noCampaignsFound': 'No campaigns found',
      'notifications': 'Notifications',
      'viewDetails': 'View Details',
      'donate': 'Donate',
      'accept': 'Accept',
      'reject': 'Reject',
      'donationHistory': 'Donation History',
      'noDonationHistoryFound': 'No donation history found',
      'yourAcceptedDonationsWillAppearHere': 'Your accepted donations will appear here',
      'refresh': 'Refresh',
      'donatorName': 'Donator Name',
      'donatorDate': 'Donator Date',
      'whatDidYouDonate': 'What did you donate',
      'activeCampaigns': 'Active Campaigns',
      'filterCampaigns': 'Filter Campaigns',
      'clearFilters': 'Clear Filters',
      'resetFilters': 'Reset Filters',
      'noCampaignsMatchYourFilters': 'No campaigns match your filters',
      'noNotificationsAvailable': 'No notifications available',
      'noNotificationsYet': 'No notifications yet',
      'donationAcceptedSuccessfully': 'Donation accepted successfully',
      'donationRejectedSuccessfully': 'Donation rejected successfully',
      'noAcceptedDonationsFoundYet': 'No accepted donations found yet',
    },
    'si': {
      'welcome': 'සාදරයෙන් පිළිගනිමු',
      'kindnessPlate': 'ඔබේ කරුණාව පිඟානක් පුරවයි!',
      'getStarted': 'ආරම්භ කරන්න',
      'selectLanguage': 'භාෂාව තෝරන්න',
      'languageChanged': 'භාෂාව සිංහල වෙත වෙනස් කරන ලදී',
      'home': 'මුල් පිටුව',
      'donations': 'පරිත්‍යාග',
      'donation': 'පරිත්‍යාගය',
      'details': 'විස්තර',
      'account': 'ගිණුම',
      'foodInNeed': 'අවශ්‍ය ආහාර',
      'requestDonation': 'පරිත්‍යාග ඉල්ලීම',
      'donateNow': 'දැන් පරිත්‍යාග කරන්න',
      'urgencyStatus': 'හදිසි තත්වය',
      'becomeFoodDonor': 'අද ආහාර පරිත්‍යාගශීලියෙකු වන්න',
      'latestCampaigns': 'නවතම ව්‍යාපාර',
      'changeLanguage': 'භාෂාව වෙනස් කරන්න',
      'edit': 'සංස්කරණය කරන්න',
      'name': 'නම',
      'email': 'විද්‍යුත් තැපෑල',
      'password': 'මුරපදය',
      'newPassword': 'නව මුරපදය',
      'location': 'ස්ථානය',
      'welcomeToKindPlate': 'කයින්ඩ්-ප්ලේට් වෙත සාදරයෙන් පිළිගනිමු',
      'foodInsecurityTitle': 'ශ්‍රී ලංකාවේ ආහාර අවිශ්වසනීයත්වය සහ පෝෂණ අඩුවීම',
      'foodInsecurityDescription': 'ශ්‍රී ලංකාවේ මිලියන 6.7 ක් පමණ ජනතාවට ප්‍රමාණවත් ආහාර ලබා ගැනීමට අපහසු වී ඇත. ඔබේ අද උදව්ව අවශ්‍ය අයට බලාපොරොත්තුව සහ පෝෂණය ගෙන ඒමට උපකාර විය හැකිය.',
      'latestUpdates': 'නවතම යාවත්කාලීන කිරීම්',
      'seeAll': 'සියල්ල බලන්න',
      'noPostsAvailable': 'ලබා ගත හැකි පළ කිරීම් නැත',
      'becomeAFoodDonor': 'එක් වන්න',
      'foodDonorToday': 'අද ආහාර පරිත්‍යාගශීලියෙකු වන්න',
      'donateFood': 'ආහාර පරිත්‍යාග කරන්න',
      'noCampaignsFound': 'ව්‍යාපාර හමු නොවීය',
      'notifications': 'දැනුම්දීම්',
      'viewDetails': 'විස්තර බලන්න',
      'donate': 'පරිත්යාග කරන්න',
      'accept': 'පිළිගන්න',
      'reject': 'ප්‍රතික්ෂේප කරන්න',
      'donationHistory': 'පරිත්‍යාග ඉතිහාසය',
      'noDonationHistoryFound': 'පරිත්‍යාග ඉතිහාසයක් හමු නොවීය',
      'yourAcceptedDonationsWillAppearHere': 'ඔබගේ පිළිගත් පරිත්‍යාග මෙහි දිස් වනු ඇත',
      'refresh': 'යළි පූරණය කරන්න',
      'donatorName': 'පරිත්‍යාගශීලියාගේ නම',
      'donatorDate': 'පරිත්‍යාග දිනය',
      'whatDidYouDonate': 'ඔබ පරිත්‍යාග කළේ කුමක්ද',
      'activeCampaigns': 'ක්‍රියාකාරී ව්‍යාපාර',
      'filterCampaigns': 'ව්‍යාපාර පෙරන්න',
      'clearFilters': 'පෙරහන් හිස් කරන්න',
      'resetFilters': 'පෙරහන් යළි පිහිටුවන්න',
      'noCampaignsMatchYourFilters': 'ඔබගේ පෙරහන්වලට ගැලපෙන ව්‍යාපාර නොමැත',
      'noNotificationsAvailable': 'දැනුම්දීම් ලබා ගත නොහැක',
      'noNotificationsYet': 'තවම දැනුම්දීම් නැත',
      'donationAcceptedSuccessfully': 'පරිත්‍යාගය සාර්ථකව පිළිගන්නා ලදී',
      'donationRejectedSuccessfully': 'පරිත්‍යාගය සාර්ථකව ප්‍රතික්ෂේප කරන ලදී',
      'noAcceptedDonationsFoundYet': 'තවම පිළිගත් පරිත්‍යාග හමු වී නැත',
    },
  };
  
  // Method to fetch predefined strings
  String _getStaticTranslation(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key]!;
  }
  
  // Method to get dynamic translation (on-the-fly translation)
  Future<String> translateText(String text) async {
    if (locale.languageCode == 'en') {
      return text; // No translation needed for English
    }
    
    try {
      return await _translationService.translate(
        text, 
        locale.languageCode,
        sourceLanguage: 'en'
      );
    } catch (e) {
      debugPrint('Error translating text: $e');
      return text; // Return original text if translation fails
    }
  }
  
  // New method to translate any text dynamically
  Future<String> translate(String key, {String? fallbackText}) async {
    // First check if we have a predefined translation
    if (_localizedValues[locale.languageCode]?.containsKey(key) == true) {
      return _getStaticTranslation(key);
    }
    
    // Check if we have a cached dynamic translation
    _dynamicTranslations ??= {};
    if (_dynamicTranslations!.containsKey(key)) {
      return _dynamicTranslations![key]!;
    }
    
    // If not, translate on the fly
    if (locale.languageCode != 'en') {
      final text = fallbackText ?? key;
      final translated = await translateText(text);
      _dynamicTranslations![key] = translated;
      return translated;
    }
    
    return fallbackText ?? key;
  }
  
  // Getter methods for predefined strings - ensures backward compatibility
  String get welcome => _getStaticTranslation('welcome');
  String get kindnessPlate => _getStaticTranslation('kindnessPlate');
  String get getStarted => _getStaticTranslation('getStarted');
  String get selectLanguage => _getStaticTranslation('selectLanguage');
  String get languageChanged => _getStaticTranslation('languageChanged');
  String get home => _getStaticTranslation('home');
  String get donations => _getStaticTranslation('donations');
  String get donation => _getStaticTranslation('donation');
  String get details => _getStaticTranslation('details');
  String get account => _getStaticTranslation('account');
  String get foodInNeed => _getStaticTranslation('foodInNeed');
  String get requestDonation => _getStaticTranslation('requestDonation');
  String get donateNow => _getStaticTranslation('donateNow');
  String get urgencyStatus => _getStaticTranslation('urgencyStatus');
  String get becomeFoodDonor => _getStaticTranslation('becomeFoodDonor');
  String get latestCampaigns => _getStaticTranslation('latestCampaigns');
  String get changeLanguage => _getStaticTranslation('changeLanguage');
  String get edit => _getStaticTranslation('edit');
  String get name => _getStaticTranslation('name');
  String get email => _getStaticTranslation('email');
  String get password => _getStaticTranslation('password');
  String get newPassword => _getStaticTranslation('newPassword');
  String get location => _getStaticTranslation('location');
  String get notifications => _getStaticTranslation('notifications');
  String get viewDetails => _getStaticTranslation('viewDetails');
  String get donate => _getStaticTranslation('donate');
  String get accept => _getStaticTranslation('accept');
  String get reject => _getStaticTranslation('reject');
  String get donationHistory => _getStaticTranslation('donationHistory');
  String get refresh => _getStaticTranslation('refresh');
  String get activeCampaigns => _getStaticTranslation('activeCampaigns');
  String get filterCampaigns => _getStaticTranslation('filterCampaigns');
  String get clearFilters => _getStaticTranslation('clearFilters');
  String get resetFilters => _getStaticTranslation('resetFilters');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return ['en', 'si'].contains(locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
  
  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
} 