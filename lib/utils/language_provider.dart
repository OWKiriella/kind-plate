import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/translation_service.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  static const String _prefsKey = 'language_code';
  final TranslationService _translationService = TranslationService();
  bool _isTranslating = false;
  
  // List of supported languages
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'si', 'name': 'සිංහල (Sinhala)'},
  ];

  Locale get locale => _locale;
  bool get isTranslating => _isTranslating;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_prefsKey);
    
    if (savedLanguage != null) {
      _locale = Locale(savedLanguage);
      // Preload translations for the saved language
      await _translationService.loadPersistedTranslations(savedLanguage);
      notifyListeners();
    }
  }

  Future<void> setLocale(String languageCode) async {
    if (_locale.languageCode != languageCode) {
      _isTranslating = true;
      notifyListeners();
      
      _locale = Locale(languageCode);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, languageCode);
      
      // Preload translations for the new language
      await _translationService.loadPersistedTranslations(languageCode);
      
      // Allow some time for the UI to show the loading state
      await Future.delayed(const Duration(milliseconds: 300));
      
      _isTranslating = false;
      notifyListeners();
    }
  }

  // Gets the human-readable name of the current language
  String getCurrentLanguageName() {
    final lang = supportedLanguages.firstWhere(
      (lang) => lang['code'] == _locale.languageCode,
      orElse: () => supportedLanguages.first,
    );
    return lang['name']!;
  }
} 