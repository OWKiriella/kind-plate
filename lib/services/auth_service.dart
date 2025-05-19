import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/home/home_screen.dart';
import '../screens/grama_niladhari/grama_home_screen.dart';
import '../utils/navigation_helper.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Initialize Firebase
  static Future<void> initializeFirebase() async {
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
  }
  
  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // User canceled the sign-in
      }
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Save user data to Firestore with the selected role
      if (userCredential.user != null) {
        final userData = {
          'name': userCredential.user?.displayName ?? 'User',
          'email': userCredential.user?.email ?? '',
          'role': isGramaNiladhari ? 'Grama Niladhari Officer' : 'Donor',
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData, SetOptions(merge: true));
      }
      
      return userCredential;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return null;
    }
  }
  
  // Login with email and password
  Future<bool> login(String email, String password, String role) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      debugPrint('Error logging in: $e');
      return false;
    }
  }
  
  // Sign up with email and password
  Future<bool> signup(String name, String email, String password, String role) async {
    try {
      // Check password length before attempting to create user
      if (password.length < 8) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Password must be at least 8 characters long',
        );
      }
      
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update the user's display name
      await result.user?.updateDisplayName(name);
      
      // Set the user role
      await FirebaseFirestore.instance
          .collection('users')
          .doc(result.user!.uid)
          .set({
            'name': name,
            'email': email,
            'role': role,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error signing up: ${e.code} - ${e.message}');
      // Let the calling code handle the error with the specific code
      rethrow;
    } catch (e) {
      debugPrint('Error signing up: $e');
      return false;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
  
  // Navigate to the correct home screen based on user role
  void navigateToHomeScreen(BuildContext context, String role) {
    // Update the global flag in navigation helper
    isGramaNiladhari = role == 'Grama Niladhari Officer';
    
    if (role == 'Grama Niladhari Officer') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const GramaHomeScreen(),
          settings: const RouteSettings(name: '/grama_home'),
        ),
        (route) => false,
      );
    } else {
      // Default to donor home screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
          settings: const RouteSettings(name: '/home'),
        ),
        (route) => false,
      );
    }
  }
  
  // Get current user data from Firestore
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      User? user = _auth.currentUser;
      
      if (user != null) {
        // Get user data from Firestore
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
            
        if (userData.exists) {
          return userData.data() as Map<String, dynamic>;
        } else {
          // If user document doesn't exist in Firestore, create a basic one with auth data
          Map<String, dynamic> basicUserData = {
            'name': user.displayName ?? 'User',
            'email': user.email ?? '',
            'role': 'Donor', // Default role
            'createdAt': FieldValue.serverTimestamp(),
          };
          
          // Save this basic data to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(basicUserData);
              
          return basicUserData;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }
  
  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
  
  // Update user profile data
  Future<bool> updateUserProfile(String name, String email) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Update display name in Firebase Auth
        await user.updateDisplayName(name);
        
        // Update email if it's different
        if (user.email != email) {
          await user.updateEmail(email);
        }
        
        // Update user data in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'name': name,
              'email': email,
              'updatedAt': FieldValue.serverTimestamp(),
            });
        
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }
  
  // Update user password
  Future<bool> updatePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating password: $e');
      return false;
    }
  }
  
  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error sending password reset email: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      return false;
    }
  }
} 