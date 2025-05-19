import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'app_localizations.dart';

void showLanguageOptions(BuildContext context) {
  final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
  final currentLocale = languageProvider.locale.languageCode;
  final localizations = AppLocalizations.of(context);
  
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localizations.selectLanguage,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  currentLocale == 'en' ? Icons.check_circle : Icons.circle_outlined, 
                  color: currentLocale == 'en' ? const Color(0xFF4D9164) : Colors.grey
                ),
                title: const Text('English'),
                onTap: () {
                  // Set language to English
                  languageProvider.setLocale('en');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations(const Locale('en')).languageChanged),
                      backgroundColor: const Color(0xFF4D9164),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  currentLocale == 'si' ? Icons.check_circle : Icons.circle_outlined, 
                  color: currentLocale == 'si' ? const Color(0xFF4D9164) : Colors.grey
                ),
                title: const Text('සිංහල (Sinhala)'),
                onTap: () {
                  // Set language to Sinhala
                  languageProvider.setLocale('si');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations(const Locale('si')).languageChanged),
                      backgroundColor: const Color(0xFF4D9164),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
} 