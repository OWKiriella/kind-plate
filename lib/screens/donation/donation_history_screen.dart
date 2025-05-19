import 'package:flutter/material.dart';
import '../../models/donation.dart';
import '../../services/donation_service.dart';
import '../../utils/app_localizations.dart';
import '../../utils/navigation_helper.dart';
import '../../widgets/translated_text.dart';
import '../donation/donation_screen.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  final DonationService _donationService = DonationService();
  List<Donation> _donations = [];
  bool _isLoading = true;
  String _currentFilter = 'all'; // 'all', 'pending', 'accepted', or 'rejected'
  
  @override
  void initState() {
    super.initState();
    _loadDonationHistory();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh donation history when coming back to this screen
    _loadDonationHistory();
  }
  
  Future<void> _loadDonationHistory() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      debugPrint('Loading donation history with filter: $_currentFilter');
      final donations = await _donationService.getUserDonationHistory(
        statusFilter: _currentFilter == 'all' ? null : _currentFilter,
      );
      debugPrint('Loaded ${donations.length} donations for history screen');
      
      // For debugging purposes, manually creating sample donations if none are found
      if (donations.isEmpty && _currentFilter == 'all') {
        debugPrint('No donations found - checking if we need to create test data');
        
        // Uncomment to create test data
        // This can be used temporarily for testing purposes
        /*
        final testDonations = [
          Donation(
            id: 'test1',
            campaignId: 'campaign1',
            campaignTitle: 'Test Campaign 1',
            donorId: 'donor1',
            donorName: 'Test Donor',
            amount: 100.0,
            items: '',
            donationType: 'monetary',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            status: 'pending',
          ),
          Donation(
            id: 'test2',
            campaignId: 'campaign2',
            campaignTitle: 'Test Campaign 2',
            donorId: 'donor1',
            donorName: 'Test Donor',
            amount: 0.0,
            items: 'Rice, Oil, Sugar',
            donationType: 'items',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
            status: 'accepted',
          ),
        ];
        setState(() {
          _donations = testDonations;
          _isLoading = false;
        });
        return;
        */
      }
      
      setState(() {
        _donations = donations;
        _isLoading = false;
      });
      
      // If no donations were found, show a message
      if (donations.isEmpty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText(_getEmptyStateMessage()),
            backgroundColor: Colors.amber,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading donation history: $e');
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('Error loading donation history: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getEmptyStateMessage() {
    switch (_currentFilter) {
      case 'pending':
        return 'You don\'t have any pending donations yet.\n\nWhen you make a donation, it will appear here while waiting for approval.';
      case 'accepted':
        return 'You don\'t have any accepted donations yet.\n\nYour donations will appear here once they\'re approved by the campaign organizer.';
      case 'rejected':
        return 'You don\'t have any rejected donations.\n\nThat\'s good news! If a donation is rejected, it will appear here.';
      default:
        return 'You haven\'t made any donations yet.\n\nSupporting a campaign is just a few taps away! Click the button below to browse active campaigns and make a difference.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF4D9164),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4D9164),
        title: const TranslatedText(
          'Donation History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Filter buttons
                  _buildFilterButtons(),
                  
                  // Donations list
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF4D9164),
                            ),
                          )
                        : _donations.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _donations.length,
                                itemBuilder: (context, index) {
                                  final donation = _donations[index];
                                  return _buildDonationCard(donation);
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // Profile is selected
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
        items: const [
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
  
  Widget _buildFilterButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TranslatedText(
            'Filter by status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Accepted', 'accepted'),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', 'rejected'),
              ],
            ),
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, String filter) {
    final isSelected = _currentFilter == filter;
    
    return FilterChip(
      selected: isSelected,
      label: TranslatedText(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: Colors.grey.shade200,
      selectedColor: const Color(0xFF4D9164),
      checkmarkColor: Colors.white,
      onSelected: (selected) {
        setState(() {
          _currentFilter = filter;
        });
        _loadDonationHistory();
      },
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.volunteer_activism,
              size: 80,
              color: Color(0xFF4D9164),
            ),
            const SizedBox(height: 16),
            TranslatedText(
              _getEmptyStateMessage(),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_currentFilter != 'all')
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentFilter = 'all';
                  });
                  _loadDonationHistory();
                },
                child: const TranslatedText(
                  'Show all donations instead',
                  style: TextStyle(
                    color: Color(0xFF4D9164),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (_currentFilter == 'all')
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to the donation screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DonationScreen()),
                  ).then((_) {
                    // Refresh the donations when returning from the donation screen
                    _loadDonationHistory();
                  });
                },
                icon: const Icon(Icons.volunteer_activism),
                label: const TranslatedText('Make a Donation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4D9164),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadDonationHistory,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4D9164),
                side: const BorderSide(color: Color(0xFF4D9164)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const TranslatedText('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDonationCard(Donation donation) {
    // Define colors and icons based on donation status
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (donation.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        statusText = 'Pending';
        break;
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Accepted';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = 'Unknown';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, size: 18, color: statusColor),
                const SizedBox(width: 8),
                TranslatedText(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TranslatedText(
                  donation.formattedDate,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Donation details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDonationDetailRow('Campaign', donation.campaignTitle),
                const SizedBox(height: 8),
                _buildDonationDetailRow('Donor Name', donation.donorName),
                const SizedBox(height: 8),
                _buildDonationDetailRow(
                  donation.donationType == 'monetary' ? 'Amount' : 'Items',
                  donation.donationValue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslatedText(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
} 