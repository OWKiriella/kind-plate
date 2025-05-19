import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/campaign.dart';
import '../campaign/campaign_detail_screen.dart';
import '../campaign/create_campaign_screen.dart';
import '../../utils/navigation_helper.dart';
import '../home/home_screen.dart';
import '../grama_niladhari/grama_home_screen.dart';
import '../../main.dart'; // Import for routeObserver
import '../chat/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/translated_text.dart';
import '../../utils/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../utils/language_provider.dart';
import '../../services/translation_service.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> with RouteAware {
  int _selectedIndex = 0;
  bool _isLoading = false;
  List<Campaign> _activeCampaigns = [];
  List<Campaign> _filteredCampaigns = [];
  
  // Filter variables
  String? _selectedLocation;
  String? _selectedUrgency;
  List<String> _locations = [];
  List<String> _urgencyLevels = [];

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Modified query - getting active campaigns first, then sorting in memory
      // This avoids the need for a composite index
      final QuerySnapshot campaignsSnapshot = await FirebaseFirestore.instance
          .collection('campaigns')
          .where('status', isEqualTo: 'active')
          .get();
          
      final campaignsData = campaignsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
      
      // Sort by createdAt in memory instead of using orderBy
      campaignsData.sort((a, b) {
        if (a['createdAt'] == null) return 1;
        if (b['createdAt'] == null) return -1;
        
        final aTimestamp = a['createdAt'] as Timestamp;
        final bTimestamp = b['createdAt'] as Timestamp;
        
        return bTimestamp.compareTo(aTimestamp); // Descending order
      });

      // Check if we need to translate the campaigns
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      if (languageProvider.locale.languageCode != 'en') {
        final translationService = TranslationService();
        
        final translatedCampaignsData = await Future.wait(
          campaignsData.map((data) async {
            // Preserve important fields like imageUrl
            final originalImageUrl = data['imageUrl'];
            
            // Translate the data
            final translatedData = await translationService.translateFirebaseData(
              data,
              languageProvider.locale.languageCode,
            );
            
            // Ensure imageUrl is preserved exactly
            if (originalImageUrl != null) {
              translatedData['imageUrl'] = originalImageUrl;
            }
            
            return translatedData;
          }),
        );
        
        campaignsData.clear();
        campaignsData.addAll(translatedCampaignsData);
      }
      
      // Convert to Campaign objects
      final campaigns = campaignsData.map((data) {
        // Format timestamp
        String timeAgo = 'Just now';
        if (data['createdAt'] != null) {
          final timestamp = data['createdAt'] as Timestamp;
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
        
        // Extract donation amounts and calculate progress
        final donatedAmount = data['donatedAmount'] != null ? (data['donatedAmount'] as num).toInt() : 0;
        final targetAmount = data['targetAmount'] != null ? (data['targetAmount'] as num).toInt() : 0;
        double progress = 0.0;
        if (targetAmount > 0) {
          progress = donatedAmount / targetAmount;
          if (progress > 1.0) progress = 1.0; // Cap at 100%
        }
        
        debugPrint('Campaign ${data['id']}: Donated=$donatedAmount, Target=$targetAmount, Progress=$progress');
        
        // Create a Campaign object
        return Campaign(
          id: data['id'],
          title: data['title'] ?? 'No Title',
          location: data['location'] ?? 'Unknown location',
          description: data['description'] ?? 'No description',
          imageUrl: data['imageUrl'] ?? 'assets/campaign.png',
          timeAgo: timeAgo,
          urgencyLabel: data['urgency'] ?? 'Unknown',
          requiredItems: data['foodInNeed'] != null 
              ? data['foodInNeed'].toString().split(',') 
              : ['None specified'],
          donatedAmount: donatedAmount,
          targetAmount: targetAmount,
          progress: progress,
          status: data['status'] ?? 'active',
        );
      }).toList();
      
      // Extract unique locations and urgency levels for filtering
      final Set<String> locationSet = {};
      final Set<String> urgencySet = {};
      
      for (var campaign in campaigns) {
        if (campaign.location.isNotEmpty) {
          locationSet.add(campaign.location);
        }
        if (campaign.urgencyLabel.isNotEmpty) {
          urgencySet.add(campaign.urgencyLabel);
        }
      }
      
      if (mounted) {
        setState(() {
          _activeCampaigns = campaigns;
          _filteredCampaigns = campaigns;
          _locations = locationSet.toList()..sort();
          _urgencyLevels = urgencySet.toList()..sort();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading campaigns: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('Failed to load campaigns: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _applyFilters() {
    setState(() {
      if (_selectedLocation == null && _selectedUrgency == null) {
        // If no filters selected, show all campaigns
        _filteredCampaigns = _activeCampaigns;
        return;
      }
      
      _filteredCampaigns = _activeCampaigns.where((campaign) {
        // Debug filter matching
        final bool matchesLocation = _selectedLocation == null || 
                              campaign.location.trim() == _selectedLocation!.trim();
                              
        final bool matchesUrgency = _selectedUrgency == null || 
                             campaign.urgencyLabel.trim() == _selectedUrgency!.trim();
        
        debugPrint('Filtering campaign: ${campaign.title}');
        debugPrint('Location: ${campaign.location} vs $_selectedLocation - Match: $matchesLocation');
        debugPrint('Urgency: ${campaign.urgencyLabel} vs $_selectedUrgency - Match: $matchesUrgency');
        
        return matchesLocation && matchesUrgency;
      }).toList();
      
      debugPrint('After filtering: ${_filteredCampaigns.length} campaigns');
    });
  }
  
  void _resetFilters() {
    setState(() {
      _selectedLocation = null;
      _selectedUrgency = null;
      _filteredCampaigns = _activeCampaigns;
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
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF4D9164),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
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
            localizations.donations,
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
                _buildFilterSection(),
                const SizedBox(height: 16),
                _buildActiveCampaignsSection(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chatButtonDonation',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatScreen(),
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
        currentIndex: 1, // Donation tab is selected
        selectedItemColor: const Color(0xFF4D9164),
        unselectedItemColor: Colors.grey,
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
  
  Widget _buildFilterSection() {
    final localizations = AppLocalizations.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslatedText(
              'Filter Campaigns',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    hint: localizations.location,
                    value: _selectedLocation,
                    items: _locations,
                    onChanged: (value) {
                      setState(() {
                        _selectedLocation = value;
                        _applyFilters();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDropdown(
                    hint: localizations.urgencyStatus,
                    value: _selectedUrgency,
                    items: _urgencyLevels,
                    onChanged: (value) {
                      setState(() {
                        _selectedUrgency = value;
                        _applyFilters();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.clear, size: 16),
                label: const TranslatedText('Clear Filters'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4D9164),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          iconSize: 24,
          elevation: 16,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActiveCampaignsSection() {
    final localizations = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TranslatedText(
              'Active Campaigns',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_filteredCampaigns.length} ${_filteredCampaigns.length != 1 ? 'results' : 'result'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4D9164),
                ),
              )
            : _filteredCampaigns.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const TranslatedText(
                            'No campaigns match your filters',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _resetFilters,
                            child: const TranslatedText('Reset Filters'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF4D9164),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: _filteredCampaigns.map((campaign) => _buildCampaignCard(campaign)).toList(),
                  ),
      ],
    );
  }

  Widget _buildCampaignCard(Campaign campaign) {
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Campaign image
            campaign.imageUrl.startsWith('http')
                ? Image.network(
                    campaign.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Error loading campaign image: $error for URL: ${campaign.imageUrl}');
                      return Container(
                        height: 150,
                        color: Colors.grey[300],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.image_not_supported, color: Colors.grey, size: 30),
                            const SizedBox(height: 8),
                            Text('Image load error', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xFF4D9164),
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  )
                : Image.asset(
                    campaign.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Error loading asset image: $error for path: ${campaign.imageUrl}');
                      return Container(
                        height: 150,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      );
                    },
                  ),
            
            // Campaign details
          Padding(
              padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Urgency tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      campaign.urgencyLabel,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Title
                Text(
                  campaign.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                ),
                const SizedBox(height: 4),
                  
                  // Location and time
                Row(
                  children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      campaign.location,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                Text(
                        campaign.timeAgo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    campaign.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                  
                  const SizedBox(height: 16),
                  
                  // Progress
                  LinearProgressIndicator(
                    value: campaign.progress,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4D9164)),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs. ${campaign.donatedAmount}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4D9164),
                        ),
                      ),
                      Text(
                        'Rs. ${campaign.targetAmount}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CampaignDetailScreen(campaign: campaign),
                        ),
                      );
                    },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4D9164),
                          side: const BorderSide(color: Color(0xFF4D9164)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const TranslatedText('View Details'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to campaign detail screen for donation
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CampaignDetailScreen(campaign: campaign),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4D9164),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const TranslatedText('Donate'),
                      ),
                    ],
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