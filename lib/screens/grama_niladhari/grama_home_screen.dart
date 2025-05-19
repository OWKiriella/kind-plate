import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/navigation_helper.dart';
import '../../models/campaign.dart';
import '../../models/post.dart';
import '../campaign/create_campaign_screen.dart';
import '../campaign/campaign_detail_screen.dart';
import '../campaign/edit_campaign_screen.dart';
import '../post/create_post_screen.dart';
import '../post/edit_post_screen.dart';
import '../chat/grama_chat_screen.dart';
import '../../utils/language_helper.dart';
import '../../main.dart'; // Import for routeObserver
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/translated_text.dart';
import 'package:provider/provider.dart';
import '../../utils/language_provider.dart';
import '../../services/translation_service.dart';

class GramaHomeScreen extends StatefulWidget {
  const GramaHomeScreen({super.key});

  @override
  State<GramaHomeScreen> createState() => _GramaHomeScreenState();
}

class _GramaHomeScreenState extends State<GramaHomeScreen> with RouteAware {
  int _selectedIndex = 0;
  bool _isLoading = false;
  List<Map<String, dynamic>> _campaigns = [];
  List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
    _loadPosts();
  }

  Future<void> _loadCampaigns() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Modified query - getting all documents created by user first, then sorting in memory
      // This avoids the need for a composite index
      final QuerySnapshot campaignsSnapshot = await FirebaseFirestore.instance
          .collection('campaigns')
          .where('createdBy', isEqualTo: userId)
          .get();
          
      final campaigns = campaignsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
      
      // Sort by createdAt in memory instead of using orderBy
      campaigns.sort((a, b) {
        if (a['createdAt'] == null) return 1;
        if (b['createdAt'] == null) return -1;
        
        final aTimestamp = a['createdAt'] as Timestamp;
        final bTimestamp = b['createdAt'] as Timestamp;
        
        return bTimestamp.compareTo(aTimestamp); // Descending order
      });
      
      // Translate campaigns if not in English
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      if (languageProvider.locale.languageCode != 'en') {
        final translationService = TranslationService();
        final translatedCampaigns = await Future.wait(
          campaigns.map((campaign) async {
            // Save imageUrl before translation
            final String? originalImageUrl = campaign['imageUrl'] as String?;
            
            // Translate the campaign data
            final translatedCampaign = await translationService.translateFirebaseData(
              campaign,
              languageProvider.locale.languageCode,
            );
            
            // Ensure imageUrl is preserved exactly
            if (originalImageUrl != null) {
              translatedCampaign['imageUrl'] = originalImageUrl;
            }
            
            return translatedCampaign;
          }),
        );
        
        if (mounted) {
          setState(() {
            _campaigns = translatedCampaigns;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _campaigns = campaigns;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading campaigns: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load campaigns: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Get posts created by the current user
      final QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('createdBy', isEqualTo: userId)
          .get();
          
      final posts = postsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
      
      // Sort by createdAt in memory
      posts.sort((a, b) {
        if (a['createdAt'] == null) return 1;
        if (b['createdAt'] == null) return -1;
        
        final aTimestamp = a['createdAt'] as Timestamp;
        final bTimestamp = b['createdAt'] as Timestamp;
        
        return bTimestamp.compareTo(aTimestamp); // Descending order
      });
      
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading posts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load posts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      _loadCampaigns(); // Reload campaigns when returning to this screen
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4D9164),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: const Color(0xFF4D9164),
          elevation: 0,
          leading: null,
          automaticallyImplyLeading: false,
          title: const TranslatedText(
            'Home',
            translationKey: 'home',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.language, color: Colors.white),
              onPressed: () {
                showLanguageOptions(context);
              },
            ),
          ],
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Color(0xFF4D9164),
            statusBarIconBrightness: Brightness.light,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(),
                const SizedBox(height: 16),
                _buildCreateRequestCard(),
                const SizedBox(height: 16),
                _buildCreatePostCard(),
                const SizedBox(height: 16),
                _buildChatCard(),
                const SizedBox(height: 24),
                _buildPastCampaignsSection(),
                const SizedBox(height: 24),
                _buildPostsSection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4D9164),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          if (index == 1) {
            _showCreateMenu(context);
          } else {
            handleNavigation(context, index);
          }
        },
        items: const [
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
        ],
      ),
    );
  }

  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.soup_kitchen_outlined, color: Color(0xFF4D9164)),
                title: const Text('Create Donation Campaign'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateCampaignScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.post_add, color: Color(0xFF4D9164)),
                title: const Text('Create Information Post'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatePostScreen(),
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

  Widget _buildWelcomeSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to Kind-Plate',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4D9164),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateRequestCard() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F7F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.soup_kitchen_outlined,
                    color: Color(0xFF4D9164),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Donation Request',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to create donation request screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateCampaignScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4D9164),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatePostCard() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F7F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.post_add,
                    color: Color(0xFF4D9164),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Information Post',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to create post screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePostScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4D9164),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatCard() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F7F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chat_outlined,
                    color: Color(0xFF4D9164),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Donor',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Messages',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to donor chat screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GramaChatScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4D9164),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('View'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastCampaignsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Campaigns',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4D9164),
                ),
              )
            : _campaigns.isEmpty
                ? const Center(
                    child: Text(
                      'No campaigns found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Column(
                    children: _campaigns.map((campaign) => _buildCampaignCard(campaign)).toList(),
                  ),
      ],
    );
  }

  Future<void> _deactivateCampaign(String campaignId) async {
    // Show confirmation dialog
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Deactivate Campaign'),
          content: const Text('Are you sure you want to deactivate this campaign? It will no longer be visible to donors.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Deactivate',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirmDelete) return;

    try {
      // Update campaign status in Firestore
      await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(campaignId)
          .update({
        'status': 'inactive',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Campaign deactivated successfully'),
          backgroundColor: Color(0xFF4D9164),
        ),
      );

      // Reload campaigns
      _loadCampaigns();
    } catch (e) {
      debugPrint('Error deactivating campaign: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deactivate campaign: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _activateCampaign(String campaignId) async {
    // Show confirmation dialog
    bool confirmActivate = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Activate Campaign'),
          content: const Text('Are you sure you want to activate this campaign? It will become visible to donors again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Activate',
                style: TextStyle(color: Color(0xFF4D9164)),
              ),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirmActivate) return;

    try {
      // Update campaign status in Firestore
      await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(campaignId)
          .update({
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Campaign activated successfully'),
          backgroundColor: Color(0xFF4D9164),
        ),
      );

      // Reload campaigns
      _loadCampaigns();
    } catch (e) {
      debugPrint('Error activating campaign: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to activate campaign: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    // Format timestamp
    String timeAgo = 'Just now';
    if (campaign['createdAt'] != null) {
      final timestamp = campaign['createdAt'] as Timestamp;
      final now = DateTime.now();
      final difference = now.difference(timestamp.toDate());
      
      if (difference.inDays > 0) {
        timeAgo = '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        timeAgo = '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inMinutes > 0) {
        timeAgo = '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      }
    }
    
    final isActive = campaign['status'] == 'active';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
                child: campaign['imageUrl'] != null
                    ? Image.network(
                        campaign['imageUrl'],
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                          );
                        },
                      )
                    : Container(
                        height: 120,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
              ),
              // Edit button overlay
              if (isGramaNiladhari)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      // Edit button
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditCampaignScreen(campaignId: campaign['id']),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Color(0xFF4D9164),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Delete/Deactivate button
                      GestureDetector(
                        onTap: () => isActive ? _deactivateCampaign(campaign['id']) : _activateCampaign(campaign['id']),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isActive ? Icons.delete : Icons.check_circle,
                            color: isActive ? Colors.red : Color(0xFF4D9164),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Status indicator
              if (!isActive)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'INACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        campaign['title'] ?? 'No Title',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isActive ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ),
                    if (!isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Inactive',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Display urgency as a label
                if (isActive && campaign['urgency'] != null) 
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      campaign['urgency'],
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      campaign['location'] ?? 'Unknown location',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  campaign['description'] ?? 'No description',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // View button
                    ElevatedButton(
                    onPressed: () {
                        // Create a temporary Campaign object
                        final tempCampaign = Campaign(
                          id: campaign['id'],
                          title: campaign['title'] ?? 'No Title',
                          location: campaign['location'] ?? 'Unknown location',
                          description: campaign['description'] ?? 'No description',
                          imageUrl: campaign['imageUrl'] ?? 'assets/campaign.png',
                          timeAgo: timeAgo,
                          urgencyLabel: campaign['urgency'] ?? 'Unknown',
                          requiredItems: campaign['foodInNeed'] != null 
                              ? campaign['foodInNeed'].toString().split(',') 
                              : ['None specified'],
                          donatedAmount: campaign['donatedAmount'] != null 
                              ? (campaign['donatedAmount'] as num).toInt() 
                              : 0,
                          targetAmount: campaign['targetAmount'] != null 
                              ? (campaign['targetAmount'] as num).toInt() 
                              : 0,
                          progress: campaign['donatedAmount'] != null && campaign['targetAmount'] != null && (campaign['targetAmount'] as num) > 0
                              ? (campaign['donatedAmount'] as num) / (campaign['targetAmount'] as num)
                              : 0,
                          status: campaign['status'] ?? 'active',
                        );
                        
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CampaignDetailScreen(campaign: tempCampaign),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4D9164),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(70, 30),
                    ),
                    child: const Text('View'),
                  ),
                    if (isGramaNiladhari && isActive)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ElevatedButton(
                          onPressed: () => _deactivateCampaign(campaign['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Colors.red),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: const Size(30, 30),
                          ),
                          child: const Text('Deactivate'),
                        ),
                      ),
                    if (isGramaNiladhari && !isActive)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ElevatedButton(
                          onPressed: () => _activateCampaign(campaign['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF4D9164),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Color(0xFF4D9164)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: const Size(30, 30),
                          ),
                          child: const Text('Activate'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Posts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4D9164),
                ),
              )
            : _posts.isEmpty
                ? const Center(
                    child: Text(
                      'No posts found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Column(
                    children: _posts.map((post) => _buildPostCard(post)).toList(),
                  ),
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    // Format timestamp
    String timeAgo = 'Just now';
    if (post['createdAt'] != null) {
      final timestamp = post['createdAt'] as Timestamp;
      final now = DateTime.now();
      final difference = now.difference(timestamp.toDate());
      
      if (difference.inDays > 0) {
        timeAgo = '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        timeAgo = '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inMinutes > 0) {
        timeAgo = '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: post['imageUrl'] != null
                    ? Image.network(
                        post['imageUrl'],
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                          );
                        },
                      )
                    : Container(
                        height: 120,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
              ),
              // Edit and Delete buttons overlay
              if (isGramaNiladhari)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      // Edit button
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditPostScreen(postId: post['id']),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Color(0xFF4D9164),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Delete button
                      GestureDetector(
                        onTap: () => _deletePost(post['id']),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['title'] ?? 'No Title',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post['description'] ?? 'No description',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    if (isGramaNiladhari)
                      ElevatedButton(
                        onPressed: () => _deletePost(post['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Colors.red),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: const Size(30, 30),
                        ),
                        child: const Text('Delete'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(String postId) async {
    // Show confirmation dialog
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirmDelete) return;

    try {
      // Delete post from Firestore
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post deleted successfully'),
          backgroundColor: Color(0xFF4D9164),
        ),
      );

      // Reload posts
      _loadPosts();
    } catch (e) {
      debugPrint('Error deleting post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete post: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 