import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/campaign.dart';
import '../../models/post.dart';
import '../campaign/campaign_detail_screen.dart';
import '../donation/donation_screen.dart';
import '../../utils/navigation_helper.dart';
import '../../utils/language_helper.dart';
import '../../main.dart'; // Import for routeObserver
import '../../widgets/post_card.dart';
import '../post/all_posts_screen.dart';
import '../chat/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/translated_text.dart';
import 'package:provider/provider.dart';
import '../../utils/language_provider.dart';
import '../../services/translation_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  int _selectedIndex = 0;
  bool _isLoading = false;
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _campaigns = [];
  
  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadCampaigns();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get latest 5 posts
      final QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
          
      if (postsSnapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _posts = [];
            _isLoading = false;
          });
        }
        return;
      }
          
      final posts = postsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
      
      // Translate posts if not in English
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      if (languageProvider.locale.languageCode != 'en') {
        final translationService = TranslationService();
        final translatedPosts = await Future.wait(
          posts.map((post) => translationService.translateFirebaseData(
            post,
            languageProvider.locale.languageCode,
          )),
        );
        
        if (mounted) {
          setState(() {
            _posts = translatedPosts;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _posts = posts;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading posts: $e');
      if (mounted) {
        setState(() {
          _posts = [];
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

  Future<void> _loadCampaigns() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Modified query to avoid composite index requirement
      // Get active campaigns first, then sort in memory
      final QuerySnapshot campaignsSnapshot = await FirebaseFirestore.instance
          .collection('campaigns')
          .where('status', isEqualTo: 'active')
          .get();
          
      if (campaignsSnapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _campaigns = [];
            _isLoading = false;
          });
        }
        return;
      }
      
      // Convert to list and sort in memory
      final campaigns = campaignsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
      
      // Sort by createdAt in memory
      campaigns.sort((a, b) {
        if (a['createdAt'] == null) return 1;
        if (b['createdAt'] == null) return -1;
        
        final aTimestamp = a['createdAt'] as Timestamp;
        final bTimestamp = b['createdAt'] as Timestamp;
        
        return bTimestamp.compareTo(aTimestamp); // Descending order
      });
      
      // Limit to 5 campaigns after sorting
      final limitedCampaigns = campaigns.take(5).toList();
      
      // Translate campaigns if not in English
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      if (languageProvider.locale.languageCode != 'en') {
        final translationService = TranslationService();
        final translatedCampaigns = await Future.wait(
          limitedCampaigns.map((campaign) async {
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
            _campaigns = limitedCampaigns;
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
    setState(() {
      _loadPosts();
      _loadCampaigns();
    });
  }

  @override
  void didPopNext() {
    setState(() {
      _loadPosts();
      _loadCampaigns();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4D9164),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Main content with curved top
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card with Chart
                  _buildWelcomeCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Horizontal scrollable post feed
                  _buildPostsFeed(),
                  
                  const SizedBox(height: 24),
                  
                  // Latest Campaigns
                  _buildCampaignSection(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chatButtonHome',
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
        currentIndex: 0, // Home is selected
        selectedItemColor: const Color(0xFF4D9164),
        unselectedItemColor: Colors.black54,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          // Use the common navigation helper
          handleNavigation(context, index);
        },
        items: getBottomNavigationItems(),
      ),
    );
  }

  Widget _buildPostsFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const TranslatedText(
              'Latest Updates',
              translationKey: 'latestUpdates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllPostsScreen(),
                  ),
                );
              },
              child: const TranslatedText(
                'See All',
                translationKey: 'seeAll',
                style: TextStyle(
                  color: Color(0xFF4D9164),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        
        // Horizontal scrollable list
        SizedBox(
          height: 280,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4D9164),
                  ),
                )
              : _posts.isEmpty
                  ? const Center(
                      child: TranslatedText(
                        'No posts available',
                        translationKey: 'noPostsAvailable',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _posts.length,
            itemBuilder: (context, index) {
                        final post = _posts[index];
                        return Container(
                          width: 280,
                          margin: EdgeInsets.only(
                            right: index != _posts.length - 1 ? 16 : 0,
                          ),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            color: const Color(0xFFF5F5F5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                  child: post['imageUrl'] != null
                                      ? Image.network(
                                          post['imageUrl'],
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              height: 150,
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: Icon(Icons.image_not_supported, color: Colors.grey),
                                              ),
                                            );
                                          },
                                        )
                                      : Image.asset(
                                          'assets/campaign.png',
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                
                                // Content
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post['title'] ?? 'No Title',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        post['description'] ?? 'No description available',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      if (post['createdAt'] != null)
                                        Text(
                                          _formatDate(post['createdAt'] as Timestamp),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
          ),
        ),
      ],
    );
  }

  String _formatDate(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildWelcomeCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TranslatedText(
              'Welcome to Kind-Plate',
              translationKey: 'welcomeToKindPlate',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4D9164),
              ),
            ),
            const SizedBox(height: 8),
            const TranslatedText(
              'Food Insecurity and Malnutrition in Sri Lanka',
              translationKey: 'foodInsecurityTitle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const TranslatedText(
              '6.7 million Sri Lankans are struggling to eat enough. Your help today can bring hope and nourishment to those in need.',
              translationKey: 'foodInsecurityDescription',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            // Chart
            Container(
              height: 150,
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Poverty',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 20,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.3),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            axisNameWidget: const Text(
                              'Year',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                const style = TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                );
                                Widget text;
                                switch (value.toInt()) {
                                  case 0:
                                    text = const Text('2020', style: style);
                                    break;
                                  case 1:
                                    text = const Text('2021', style: style);
                                    break;
                                  case 2:
                                    text = const Text('2022', style: style);
                                    break;
                                  case 3:
                                    text = const Text('2023', style: style);
                                    break;
                                  case 4:
                                    text = const Text('2024', style: style);
                                    break;
                                  default:
                                    text = const Text('', style: style);
                                    break;
                                }
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 8.0,
                                  child: text,
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            axisNameWidget: Text(
                              '',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 20,
                              reservedSize: 40,
                              getTitlesWidget: leftTitleWidgets,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        minX: 0,
                        maxX: 4,
                        minY: 0,
                        maxY: 100,
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 10),
                              FlSpot(1, 30),
                              FlSpot(2, 70),
                              FlSpot(3, 50),
                              FlSpot(4, 80),
                            ],
                            isCurved: true,
                            color: const Color(0xFF4D9164),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(
                              show: false,
                            ),
                            belowBarData: BarAreaData(
                              show: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TranslatedText(
          'Latest Campaigns',
          translationKey: 'latestCampaigns',
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
                    child: TranslatedText(
                      'No campaigns found',
                      translationKey: 'noCampaignsFound',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Column(
                    children: _campaigns.map((campaign) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildCampaignCard(campaign),
                    )).toList(),
                  ),
      ],
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      color: const Color(0xFFF5F5F5),
      child: InkWell(
        onTap: () {
          try {
            // Ensure all required fields are available
            final campaignModel = Campaign(
              id: campaign['id'] ?? '',
              title: campaign['title'] ?? 'No Title',
              location: campaign['location'] ?? 'Unknown location',
              description: campaign['description'] ?? 'No description',
              imageUrl: campaign['imageUrl'] ?? 'assets/campaign.png',
              timeAgo: campaign['createdAt'] != null 
                  ? _formatDate(campaign['createdAt'] as Timestamp)
                  : 'Just now',
              urgencyLabel: campaign['urgency'] ?? 'Unknown',
              requiredItems: campaign['foodInNeed'] != null 
                  ? (campaign['foodInNeed'] as String).split(',').map((item) => item.trim()).toList()
                  : ['None specified'],
              donatedAmount: (campaign['donatedAmount'] as num?)?.toInt() ?? 0,
              targetAmount: (campaign['targetAmount'] as num?)?.toInt() ?? 0,
              progress: (campaign['donatedAmount'] != null && campaign['targetAmount'] != null && 
                        (campaign['targetAmount'] as num) > 0)
                  ? ((campaign['donatedAmount'] as num).toDouble() / (campaign['targetAmount'] as num).toDouble())
                  : 0.0,
              status: campaign['status'] ?? 'active',
            );
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CampaignDetailScreen(campaign: campaignModel),
              ),
            );
          } catch (e) {
            debugPrint('Error navigating to campaign detail: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error opening campaign: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: campaign['imageUrl'] != null
                ? Image.network(
                    campaign['imageUrl'],
                    height: 110,
                    width: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 110,
                        width: 110,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      );
                    },
                  )
                : Image.asset(
                    'assets/campaign.png',
                    height: 110,
                    width: 110,
                    fit: BoxFit.cover,
                  ),
            ),
            
            // Right content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Display urgency as a label
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        campaign['urgency'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          campaign['location'] ?? 'Unknown location',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    
                    Text(
                      campaign['description'] ?? 'No description',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black87,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          "...more",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 10,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 26,
                          child: ElevatedButton(
                            onPressed: () {
                              try {
                                // Ensure all required fields are available
                                final campaignModel = Campaign(
                                  id: campaign['id'] ?? '',
                                  title: campaign['title'] ?? 'No Title',
                                  location: campaign['location'] ?? 'Unknown location',
                                  description: campaign['description'] ?? 'No description',
                                  imageUrl: campaign['imageUrl'] ?? 'assets/campaign.png',
                                  timeAgo: campaign['createdAt'] != null 
                                      ? _formatDate(campaign['createdAt'] as Timestamp)
                                      : 'Just now',
                                  urgencyLabel: campaign['urgency'] ?? 'Unknown',
                                  requiredItems: campaign['foodInNeed'] != null 
                                      ? (campaign['foodInNeed'] as String).split(',').map((item) => item.trim()).toList()
                                      : ['None specified'],
                                  donatedAmount: (campaign['donatedAmount'] as num?)?.toInt() ?? 0,
                                  targetAmount: (campaign['targetAmount'] as num?)?.toInt() ?? 0,
                                  progress: (campaign['donatedAmount'] != null && campaign['targetAmount'] != null && 
                                            (campaign['targetAmount'] as num) > 0)
                                      ? ((campaign['donatedAmount'] as num).toDouble() / (campaign['targetAmount'] as num).toDouble())
                                      : 0.0,
                                  status: campaign['status'] ?? 'active',
                                );
                                
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CampaignDetailScreen(campaign: campaignModel),
                                  ),
                                );
                              } catch (e) {
                                debugPrint('Error navigating to campaign detail: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error opening campaign: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4D9164),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            ),
                            child: const Text(
                              'Donate Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget leftTitleWidgets(double value, TitleMeta meta) {
  const style = TextStyle(
    color: Colors.black54,
    fontSize: 10,
  );
  
  String text;
  switch (value.toInt()) {
    case 0:
      text = '0%';
      break;
    case 20:
      text = '20%';
      break;
    case 40:
      text = '40%';
      break;
    case 60:
      text = '60%';
      break;
    case 80:
      text = '80%';
      break;
    case 100:
      text = '100%';
      break;
    default:
      return Container();
  }

  return Text(text, style: style, textAlign: TextAlign.center);
}