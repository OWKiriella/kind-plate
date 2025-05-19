import 'package:translator/translator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  final GoogleTranslator _translator = GoogleTranslator();
  final Map<String, Map<String, String>> _translationCache = {};
  
  static final TranslationService _instance = TranslationService._internal();
  
  factory TranslationService() {
    return _instance;
  }
  
  TranslationService._internal();
  
  Future<String> translate(String text, String targetLanguage, {String sourceLanguage = 'en'}) async {
    // If target language is English, no need to translate
    if (targetLanguage == 'en' || targetLanguage == sourceLanguage) {
      return text;
    }
    
    // Check cache first
    if (_translationCache[targetLanguage]?[text] != null) {
      return _translationCache[targetLanguage]![text]!;
    }
    
    try {
      final translation = await _translator.translate(
        text,
        from: sourceLanguage,
        to: targetLanguage,
      );
      
      // Cache the result
      _translationCache[targetLanguage] ??= {};
      _translationCache[targetLanguage]![text] = translation.text;
      
      // Also persist the translation in SharedPreferences
      _saveTranslationToCache(text, translation.text, targetLanguage);
      
      return translation.text;
    } catch (e) {
      print('Translation error: $e');
      return text; // Return original text on error
    }
  }
  
  Future<void> _saveTranslationToCache(String original, String translated, String targetLanguage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'translation_${targetLanguage}_${original.hashCode}';
      await prefs.setString(cacheKey, translated);
    } catch (e) {
      print('Error saving translation to cache: $e');
    }
  }
  
  Future<String?> _getTranslationFromCache(String original, String targetLanguage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'translation_${targetLanguage}_${original.hashCode}';
      return prefs.getString(cacheKey);
    } catch (e) {
      print('Error getting translation from cache: $e');
      return null;
    }
  }
  
  Future<void> loadPersistedTranslations(String targetLanguage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith('translation_${targetLanguage}_')) {
          final original = key.replaceFirst('translation_${targetLanguage}_', '');
          final translated = prefs.getString(key);
          if (translated != null) {
            _translationCache[targetLanguage] ??= {};
            _translationCache[targetLanguage]![original] = translated;
          }
        }
      }
    } catch (e) {
      print('Error loading persisted translations: $e');
    }
  }
  
  Future<Map<String, String>> translateBatch(
    Map<String, String> texts, 
    String targetLanguage, 
    {String sourceLanguage = 'en'}
  ) async {
    final result = <String, String>{};
    
    for (final entry in texts.entries) {
      result[entry.key] = await translate(entry.value, targetLanguage, sourceLanguage: sourceLanguage);
    }
    
    return result;
  }

  // New method to translate Firebase data
  Future<Map<String, dynamic>> translateFirebaseData(
    Map<String, dynamic> data,
    String targetLanguage,
    {String sourceLanguage = 'en'}
  ) async {
    final translatedData = Map<String, dynamic>.from(data);
    
    // List of fields that should not be translated
    final List<String> excludedFields = [
      'imageUrl', 
      'id', 
      'createdAt', 
      'updatedAt', 
      'createdBy', 
      'updatedBy', 
      'donatedAmount', 
      'targetAmount', 
      'progress',
      'status',
      'userId',
      'email',
      'phone',
      'url',
      'link',
      'href'
    ];
    
    for (final entry in data.entries) {
      // Skip translation for excluded fields
      if (excludedFields.contains(entry.key)) {
        continue;
      }
      
      if (entry.value is String) {
        translatedData[entry.key] = await translate(
          entry.value as String,
          targetLanguage,
          sourceLanguage: sourceLanguage
        );
      } else if (entry.value is Map<String, dynamic>) {
        translatedData[entry.key] = await translateFirebaseData(
          entry.value as Map<String, dynamic>,
          targetLanguage,
          sourceLanguage: sourceLanguage
        );
      } else if (entry.value is List) {
        final translatedList = <dynamic>[];
        for (final item in entry.value as List) {
          if (item is String) {
            translatedList.add(await translate(
              item,
              targetLanguage,
              sourceLanguage: sourceLanguage
            ));
          } else if (item is Map<String, dynamic>) {
            translatedList.add(await translateFirebaseData(
              item,
              targetLanguage,
              sourceLanguage: sourceLanguage
            ));
          } else {
            translatedList.add(item);
          }
        }
        translatedData[entry.key] = translatedList;
      }
    }
    
    return translatedData;
  }
} 