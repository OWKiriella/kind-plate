import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/donation/donation_screen.dart';
import '../screens/notification/notification_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/grama_niladhari/grama_home_screen.dart';
import '../widgets/screen_with_chat.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/chat/grama_chat_screen.dart';
// Don't import profile screen yet since it doesn't exist

// Global variable to track user role
bool isGramaNiladhari = false;

// Get bottom navigation items based on user role
List<BottomNavigationBarItem> getBottomNavigationItems() {
  if (isGramaNiladhari) {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.add_circle),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.notifications),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: '',
      ),
    ];
  } else {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.volunteer_activism),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.notifications_none),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: '',
      ),
    ];
  }
}

void handleNavigation(BuildContext context, int index) {
  // Get current route name to avoid pushing the same route
  final String? currentRoute = ModalRoute.of(context)?.settings.name;
  
  switch (index) {
    case 0: // Home
      final String homeRoute = isGramaNiladhari ? '/grama_home' : '/home';
      if (currentRoute != homeRoute) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => isGramaNiladhari 
                ? const GramaHomeScreen() 
                : const HomeScreen(),
            settings: RouteSettings(name: homeRoute),
          ),
          (route) => false,
        );
      }
      break;
      
    case 1: // Donations
      if (currentRoute != '/donations') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const DonationScreen(),
            settings: const RouteSettings(name: '/donations'),
          ),
          (route) => false,
        );
      }
      break;
      
    case 2: // Notifications
      if (currentRoute != '/notifications') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationScreen(),
            settings: const RouteSettings(name: '/notifications'),
          ),
          (route) => false,
        );
      }
      break;
      
    case 3: // Profile
      if (currentRoute != '/profile') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileScreen(),
            settings: const RouteSettings(name: '/profile'),
          ),
          (route) => false,
        );
      }
      break;
  }
}

// Function to handle chat button press
void handleChatButtonPress(BuildContext context) {
  // Navigate to the appropriate chat screen based on user role
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => isGramaNiladhari 
        ? const GramaChatScreen() 
        : const ChatScreen(),
      settings: RouteSettings(
        name: isGramaNiladhari ? '/grama_chat' : '/chat'
      ),
    ),
  );
}

// Check if the current screen is a chat-related screen
bool isChatScreen(String? routeName) {
  if (routeName == null) return false;
  
  return routeName == '/chat' || 
         routeName.contains('chat') || 
         routeName.contains('message');
}

// Determine if the floating chat button should be shown on the current route
bool shouldShowChatButton(String? routeName) {
  // If no route name is provided, don't show the chat button
  if (routeName == null) return false;
  
  // ONLY show chat button on these specific screens
  final List<String> allowedRoutes = [
    '/home',
    '/notifications',
    '/profile',
    '/donations',
    '/grama_home'
  ];
  
  // Also allow screens containing these substrings
  if (routeName.contains('home') || 
      routeName.contains('notification') || 
      routeName.contains('profile') || 
      routeName.contains('donation')) {
    return true;
  }
  
  return allowedRoutes.contains(routeName);
} 