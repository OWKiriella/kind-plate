import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _initialized = false;

  /// Initialize Firebase for the app
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyA66lzFDcjWA6oKeM-L7FcMNz8NUUs0rQU",
          authDomain: "kindplate-b3c94.firebaseapp.com",
          projectId: "kindplate-b3c94",
          storageBucket: "kindplate-b3c94.firebasestorage.app",
          messagingSenderId: "506436980209",
          appId: "1:506436980209:web:cf968e31f33ba6ecbe0850"
        ),
      );
      _initialized = true;
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
    }
  }

  /// Check if Firebase is initialized
  bool get isInitialized => _initialized;
} 