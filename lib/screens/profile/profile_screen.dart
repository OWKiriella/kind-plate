import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../utils/navigation_helper.dart';
import '../../utils/language_provider.dart';
import '../../utils/app_localizations.dart';
import '../home/home_screen.dart';
import '../grama_niladhari/grama_home_screen.dart';
import '../auth/login_screen.dart';
import '../../main.dart'; // Import for routeObserver
import '../chat/chat_screen.dart';
import '../donation/donation_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  int _selectedIndex = 3; // Profile tab selected
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  
  // Text controllers for editable fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // User data map - will be populated from Firebase
  Map<String, dynamic> _userData = {
    'name': '',
    'email': '',
    'role': '',
  };
  
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }
  
  // Load user data from Firebase
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get user data from Firestore
      Map<String, dynamic>? userData = await _authService.getCurrentUserData();
      
      if (userData != null) {
        setState(() {
          _userData = userData;
          _isLoading = false;
          
          // Initialize controllers with current values
          _nameController.text = userData['name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _passwordController.text = '••••••••••'; // Placeholder
        });
      } else {
        // If no user data in Firestore, try to get basic data from Firebase Auth
        User? currentUser = _authService.getCurrentUser();
        if (currentUser != null) {
          setState(() {
            _userData = {
              'name': currentUser.displayName ?? 'User',
              'email': currentUser.email ?? '',
              'role': isGramaNiladhari ? 'Grama Niladhari Officer' : 'Donor',
            };
            _isLoading = false;
            
            // Initialize controllers with current values
            _nameController.text = _userData['name'] ?? '';
            _emailController.text = _userData['email'] ?? '';
            _passwordController.text = '••••••••••'; // Placeholder
          });
        } else {
          // If no user is logged in, redirect to login screen
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save updated profile
  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and email cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // First update profile (name and email)
      final profileUpdated = await _authService.updateUserProfile(
        _nameController.text,
        _emailController.text,
      );
      
      // Check if password was changed (not showing placeholder)
      bool passwordUpdated = false;
      if (_passwordController.text != '••••••••••' && _passwordController.text.isNotEmpty) {
        passwordUpdated = await _authService.updatePassword(_passwordController.text);
      }
      
      setState(() {
        _isSaving = false;
        _isEditing = false;
        
        // Update local user data
        _userData['name'] = _nameController.text;
        _userData['email'] = _emailController.text;
      });
      
      String message = '';
      if (profileUpdated && passwordUpdated) {
        message = 'Profile and password updated successfully';
      } else if (profileUpdated) {
        message = 'Profile updated successfully';
      } else if (passwordUpdated) {
        message = 'Password updated successfully';
      } else {
        message = 'No changes were made';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF4D9164),
        ),
      );
      
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Cancel editing and revert changes
  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      
      // Reset controllers to original values
      _nameController.text = _userData['name'] ?? '';
      _emailController.text = _userData['email'] ?? '';
      _passwordController.text = '••••••••••';
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPush() {
    // Route was pushed onto navigator and is now topmost route.
    setState(() {
      // Update UI if needed
    });
  }

  @override
  void didPopNext() {
    // Covering route was popped off the navigator.
    setState(() {
      _loadUserData(); // Reload user data when returning to this screen
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF4D9164),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4D9164),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Navigate to the appropriate home screen based on user role
            if (isGramaNiladhari) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const GramaHomeScreen(),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
            }
          },
        ),
        title: Text(
          localizations.account,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF4D9164),
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // Profile Avatar
                      _buildProfileAvatar(),
                      
                      const SizedBox(height: 30),
                      
                      // User Details Container
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100, // Lighter gray
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : Column(
                                children: [
                                  // Name
                                  _isEditing 
                                    ? _buildEditableField(localizations.name, _nameController, false)
                                    : _buildDetailRow(localizations.name, _userData['name'] ?? 'User'),
                                  const SizedBox(height: 20),
                                  
                                  // Email
                                  _isEditing 
                                    ? _buildEditableField(localizations.email, _emailController, false)
                                    : _buildDetailRow(localizations.email, _userData['email'] ?? ''),
                                  const SizedBox(height: 20),
                                  
                                  // Password
                                  _isEditing 
                                    ? _buildEditableField(localizations.password, _passwordController, true)
                                    : _buildDetailRow(localizations.password, '••••••••••'),
                                  const SizedBox(height: 24),
                                  
                                  // Change Language Button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.language,
                                        color: Colors.grey.shade700,
                                        size: 20,
                                      ),
                                      title: Text(
                                        localizations.changeLanguage,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: Colors.black54,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      dense: true,
                                      onTap: () {
                                        _showLanguageOptions(context);
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Donation History Button (show only for donors, not for Grama Niladhari)
                                  if (!isGramaNiladhari)
                                    Column(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: ListTile(
                                            leading: Icon(
                                              Icons.history,
                                              color: Colors.grey.shade700,
                                              size: 20,
                                            ),
                                            title: const Text(
                                              'Donation History',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            trailing: const Icon(
                                              Icons.arrow_forward_ios,
                                              size: 14,
                                              color: Colors.black54,
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 4,
                                            ),
                                            dense: true,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const DonationHistoryScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                    ),
                                  
                                  // Logout Button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.logout,
                                        color: Colors.red.shade600,
                                        size: 20,
                                      ),
                                      title: Text(
                                        'Logout',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.red.shade600,
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: Colors.black54,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      dense: true,
                                      onTap: () async {
                                        // Sign out the user
                                        await _authService.signOut();
                                        
                                        // Navigate to the login screen and clear all previous routes
                                        if (mounted) {
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const LoginScreen(),
                                            ),
                                            (route) => false,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Edit/Save Button
                                  _isEditing
                                    ? _buildEditingButtons(localizations)
                                    : SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _isEditing = true;
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF4D9164),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: Text(
                                            localizations.edit,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chatButtonProfile',
        onPressed: () {
          handleChatButtonPress(context);
        },
        backgroundColor: const Color(0xFF4D9164),
        child: const Icon(
          Icons.chat,
          color: Colors.white,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4D9164),
        unselectedItemColor: Colors.black54,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          handleNavigation(context, index);
        },
        items: getBottomNavigationItems(),
      ),
    );
  }
  
  Widget _buildEditingButtons(AppLocalizations localizations) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _isSaving ? null : _cancelEditing,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4D9164),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEditableField(String label, TextEditingController controller, bool isPassword) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4D9164)),
            ),
            fillColor: Colors.white,
            filled: true,
          ),
          onChanged: (value) {
            // Clear the password field if it still contains the placeholder
            if (isPassword && controller.text == '••••••••••') {
              controller.clear();
            }
          },
        ),
      ],
    );
  }
  
  Widget _buildProfileAvatar() {
    return Column(
      children: [
        Center(
          child: Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: const Color(0xFFDEF5E5), // Lighter green background
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              size: 38,
              color: Color(0xFF4D9164),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _userData['role'] ?? 'User',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  void _showLanguageOptions(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLocale = languageProvider.locale.languageCode;
    final localizations = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            localizations.selectLanguage,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                title: const Text('සිංහල'),
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
        );
      },
    );
  }
} 