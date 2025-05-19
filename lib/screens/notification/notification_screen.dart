import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/notification_model.dart';
import '../../utils/navigation_helper.dart';
import '../home/home_screen.dart';
import '../grama_niladhari/grama_home_screen.dart';
import '../../main.dart'; // Import for routeObserver
import '../chat/chat_screen.dart';
import '../chat/grama_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/donation_service.dart';
import 'package:intl/intl.dart';
import '../../widgets/translated_text.dart';
import '../../utils/app_localizations.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with RouteAware {
  int _selectedIndex = 2; // Notification tab selected
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DonationService _donationService = DonationService();
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];
  Stream<QuerySnapshot>? _notificationsStream;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  void _initNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      _notificationsStream = _donationService.getNotifications(userId);
    }
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
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
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
      // Update UI if needed
    });
  }

  // Format Firestore timestamp to a readable date
  String _formatDate(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MM/dd/yyyy').format(dateTime);
    }
  }

  // Accept donation
  Future<void> _acceptDonation(String donationId, String notificationId) async {
    try {
      final error = await _donationService.acceptDonation(donationId);
      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: TranslatedText('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        // Mark notification as read
        await _firestore.collection('notifications').doc(notificationId).update({
          'isRead': true,
        });

        // Extra verification: double-check that donation status was updated
        try {
          final donationDoc = await _firestore.collection('donations').doc(donationId).get();
          if (donationDoc.exists) {
            final data = donationDoc.data() as Map<String, dynamic>;
            final status = data['status'] as String? ?? '';
            debugPrint('Verified donation status after accept: $status');
            
            // If status is not 'accepted', try to fix it
            if (status != 'accepted') {
              debugPrint('Donation status not properly updated to accepted, retrying update...');
              await _firestore.collection('donations').doc(donationId).update({
                'status': 'accepted',
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }
        } catch (verifyError) {
          debugPrint('Error verifying donation status: $verifyError');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TranslatedText('Donation accepted successfully'),
            backgroundColor: Color(0xFF4D9164),
          ),
        );
        
        // Force refresh of the notifications
        setState(() {
          _initNotifications();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Reject donation
  Future<void> _rejectDonation(String donationId, String notificationId) async {
    try {
      final error = await _donationService.rejectDonation(donationId);
      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: TranslatedText('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        // Mark notification as read
        await _firestore.collection('notifications').doc(notificationId).update({
          'isRead': true,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TranslatedText('Donation rejected successfully'),
            backgroundColor: Color(0xFF4D9164),
          ),
        );
        
        // Force refresh of the notifications
        setState(() {
          _initNotifications();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white, // WHITE BACKGROUND, not green
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
        title: TranslatedText(
          'Notifications',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF4D9164),
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _notificationsStream == null
            ? Center(child: TranslatedText('No notifications available'))
            : StreamBuilder<QuerySnapshot>(
                stream: _notificationsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4D9164),
                      ),
                    );
                  }

                  final notifications = snapshot.data!.docs;
                  if (notifications.isEmpty) {
                    return const Center(
                      child: TranslatedText('No notifications yet'),
                    );
                  }

                  // Sort notifications by createdAt timestamp (newest first)
                  final sortedNotifications = notifications.toList()
                    ..sort((a, b) {
                      final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      if (aTime == null) return 1;
                      if (bTime == null) return -1;
                      return bTime.compareTo(aTime); // Descending order
                    });

                  return ListView.builder(
                    itemCount: sortedNotifications.length,
                    itemBuilder: (context, index) {
                      final notificationData = sortedNotifications[index].data() as Map<String, dynamic>;
                      final notificationId = sortedNotifications[index].id;
                      final notificationType = notificationData['type'] as String? ?? '';
                      final donationId = notificationData['donationId'] as String? ?? '';
                      final title = notificationData['title'] as String? ?? 'Notification';
                      final description = notificationData['description'] as String? ?? '';
                      final date = notificationData['date'] as Timestamp? ?? Timestamp.now();
                      final isRead = notificationData['isRead'] as bool? ?? false;

                      return _buildNotificationCard(
                        notificationId,
                        donationId,
                        title,
                        description,
                        _formatDate(date),
                        notificationType,
                        isRead,
                      );
                    },
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chatButtonNotification',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => isGramaNiladhari 
                ? const GramaChatScreen() 
                : const ChatScreen(),
            ),
          );
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

  Widget _buildNotificationCard(
    String notificationId,
    String donationId,
    String title, 
    String description, 
    String date,
    String type,
    bool isRead,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey.shade200 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: isRead ? null : Border.all(color: const Color(0xFF4D9164), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bell icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none,
                    color: Color(0xFF4D9164),
                    size: 18,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Date
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            
            // Show action buttons only for Grama Niladhari and new donation notifications
            if (isGramaNiladhari && type == 'new_donation' && !isRead)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Reject button
                    OutlinedButton(
                      onPressed: () => _rejectDonation(donationId, notificationId),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                      ),
                      child: const TranslatedText('Reject'),
                    ),
                    const SizedBox(width: 8),
                    // Accept button
                    ElevatedButton(
                      onPressed: () => _acceptDonation(donationId, notificationId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4D9164),
                        foregroundColor: Colors.white,
                      ),
                      child: const TranslatedText('Accept'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
} 