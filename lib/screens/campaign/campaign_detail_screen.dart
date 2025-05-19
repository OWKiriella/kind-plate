import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/campaign.dart';
import '../../utils/navigation_helper.dart';
import '../../utils/app_localizations.dart';
import '../donation/donation_screen.dart';
import '../campaign/create_campaign_screen.dart';
import '../campaign/edit_campaign_screen.dart';
import '../post/create_post_screen.dart';
import '../grama_niladhari/grama_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/donation_service.dart';
import '../../services/payment_service.dart';

class CampaignDetailScreen extends StatefulWidget {
  final Campaign campaign;

  const CampaignDetailScreen({super.key, required this.campaign});

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  final DonationService _donationService = DonationService();
  late Campaign _campaign;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _campaign = widget.campaign;
    _loadCampaignData();
  }

  // Load the latest campaign data from Firestore
  Future<void> _loadCampaignData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final campaignDoc = await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(_campaign.id)
          .get();

      if (campaignDoc.exists) {
        final data = campaignDoc.data()!;
        
        // Format timeAgo for display
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

        final donatedAmount = data['donatedAmount'] != null ? (data['donatedAmount'] as num).toInt() : 0;
        final targetAmount = data['targetAmount'] != null ? (data['targetAmount'] as num).toInt() : 0;
        double progress = 0;
        if (targetAmount > 0) {
          progress = donatedAmount / targetAmount;
          if (progress > 1) progress = 1; // Cap at 100%
        }

        setState(() {
          _campaign = Campaign(
            id: _campaign.id,
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
        });
      }
    } catch (e) {
      debugPrint('Error loading campaign data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to deactivate a campaign
  Future<void> _deactivateCampaign(BuildContext context) async {
    // Show confirmation dialog
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Deactivate Campaign'),
          content: Text('Are you sure you want to deactivate "${_campaign.title}"? It will no longer be visible to donors.'),
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
          .doc(_campaign.id)
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

      // Navigate back to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const GramaHomeScreen(),
        ),
      );
    } catch (e) {
      debugPrint('Error deactivating campaign: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to deactivate campaign: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to show donation type selection popup
  Future<void> _showDonationTypeDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Donation Type',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('What type of donation would you like to make?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showMonetaryDonationDialog(context);
              },
              child: const Text(
                'Monetary',
                style: TextStyle(color: Color(0xFF4D9164)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showMaterialDonationDialog(context);
              },
              child: const Text(
                'Material',
                style: TextStyle(color: Color(0xFF4D9164)),
              ),
            ),
          ],
        );
      },
    );
  }

  // Method to show monetary donation amount dialog
  Future<void> _showMonetaryDonationDialog(BuildContext context) async {
    final TextEditingController amountController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Monetary Donation',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the amount you would like to donate:'),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(),
                  hintText: 'Amount',
                ),
              ),
              const SizedBox(height: 12),
              // Add test card info for testing purposes
              const Text(
                'For testing: Use card number 4242 4242 4242 4242, any future date, any CVC, and any ZIP code.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter an amount'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();
                _processDonation(context, 'monetary', amount, '');
              },
              child: const Text(
                'Donate',
                style: TextStyle(color: Color(0xFF4D9164)),
              ),
            ),
          ],
        );
      },
    );
  }

  // Method to show material donation dialog
  Future<void> _showMaterialDonationDialog(BuildContext context) async {
    final TextEditingController itemsController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Material Donation',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the items you would like to donate:'),
              const SizedBox(height: 16),
              TextField(
                controller: itemsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 5kg rice, 2 packets of milk, etc.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (itemsController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter the items'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();
                _processDonation(context, 'material', 0.0, itemsController.text);
              },
              child: const Text(
                'Donate',
                style: TextStyle(color: Color(0xFF4D9164)),
              ),
            ),
          ],
        );
      },
    );
  }

  // Method to process donation
  Future<void> _processDonation(
    BuildContext context, 
    String donationType, 
    double amount, 
    String items
  ) async {
    // Save the dialog context to ensure we can close it later
    final BuildContext dialogContext = context;
    
    try {
      // For monetary donations, start Stripe payment in background
      if (donationType == 'monetary' && amount > 0) {
        final PaymentService paymentService = PaymentService();
        
        // Instead of showing a loading animation, immediately show a message that donation is sent
        if (dialogContext.mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar(
              content: Text('Donation sent! Processing payment...'),
              backgroundColor: Color(0xFF4D9164),
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // Process payment with Stripe in the background
        paymentService.processPayment(amount).then((paymentStatus) {
          // Only show error if payment failed
          if (!paymentStatus.success && dialogContext.mounted) {
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              SnackBar(
                content: Text('Note: Payment processing issue: ${paymentStatus.message}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }).catchError((error) {
          // Handle errors silently or with minimal user disruption
          debugPrint('Stripe payment error (silent): $error');
        });
      }

      // Create donation record in database immediately
      final error = await _donationService.createDonation(
        campaignId: _campaign.id,
        donationType: donationType,
        amount: amount,
        items: items,
        campaignTitle: _campaign.title,
      );

      if (error != null) {
        if (dialogContext.mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(
              donationType == 'monetary'
                  ? 'Monetary donation of Rs. $amount recorded successfully!'
                  : 'Material donation sent successfully!',
            ),
            backgroundColor: const Color(0xFF4D9164),
          ),
        );
      }
      
      // Refresh campaign data to show updated amounts
      _loadCampaignData();
    } catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4D9164),
        title: const Text('Campaign Details'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Simply go back to previous screen
            Navigator.pop(context);
          },
        ),
        actions: [
          // Only show edit button for Grama Niladhari Officers
          if (isGramaNiladhari)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditCampaignScreen(campaignId: _campaign.id),
                  ),
                );
              },
            ),
          // Add delete button for Grama Niladhari Officers
          if (isGramaNiladhari)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () => _deactivateCampaign(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campaign image
            _campaign.imageUrl.startsWith('http') 
                ? Image.network(
                    _campaign.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
                        ),
                      );
                    },
                  )
                : Image.asset(
                    _campaign.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and urgency
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _campaign.urgencyLabel,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Add campaign title
                  Text(
                    _campaign.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Location and time
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _campaign.location,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _campaign.timeAgo,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _campaign.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Required items
                  const Text(
                    'Required Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _campaign.requiredItems.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F7F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF4D9164).withOpacity(0.3)),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: Color(0xFF4D9164),
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs. ${_campaign.donatedAmount}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF4D9164),
                        ),
                      ),
                      Text(
                        'Rs. ${_campaign.targetAmount}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _campaign.progress,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4D9164)),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Donate button - only show for donors, not for Grama Niladhari
                  if (!isGramaNiladhari)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showDonationTypeDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4D9164),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Donate Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Donation is selected for consistency
        selectedItemColor: const Color(0xFF4D9164),
        unselectedItemColor: Colors.black54,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          // Use the common navigation helper
          if (isGramaNiladhari && index == 1) {
            // Show create menu for Grama Niladhari officers
            _showCreateMenu(context);
          } else {
            handleNavigation(context, index);
          }
        },
        items: isGramaNiladhari 
            ? const [
                // Grama Niladhari bottom nav items
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
              ] 
            : const [
                // Regular user bottom nav items
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
}
