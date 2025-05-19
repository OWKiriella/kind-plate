import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/donation.dart';

class DonationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new donation
  Future<String?> createDonation({
    required String campaignId,
    required String donationType,
    required double amount,
    required String items,
    required String campaignTitle,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return 'User not authenticated';
      }

      // Get user data
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        return 'User profile not found';
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final userName = userData['name'] ?? 'Anonymous Donor';

      // Get campaign data
      final campaignDoc = await _firestore.collection('campaigns').doc(campaignId).get();
      if (!campaignDoc.exists) {
        return 'Campaign not found';
      }
      
      final campaignData = campaignDoc.data() as Map<String, dynamic>;
      final campaignCreator = campaignData['createdBy'] as String;

      // Create donation document
      final donationRef = await _firestore.collection('donations').add({
        'campaignId': campaignId,
        'donorId': currentUser.uid,
        'donorName': userName,
        'donationType': donationType,
        'amount': amount,
        'items': items,
        'status': 'pending', // pending, accepted, rejected
        'createdAt': FieldValue.serverTimestamp(),
        'campaignTitle': campaignTitle,
      });
      
      debugPrint('Created new donation with ID: ${donationRef.id}');

      // Create notification for the Grama Niladhari
      await _firestore.collection('notifications').add({
        'userId': campaignCreator, // The campaign creator (Grama Niladhari)
        'title': 'New Donation Received',
        'description': donationType == 'monetary' 
            ? 'Rs. $amount received for $campaignTitle'
            : 'Materials donated for $campaignTitle',
        'date': Timestamp.now(),
        'isRead': false,
        'donationId': donationRef.id,
        'type': 'new_donation',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // Success - no error message
    } catch (e) {
      debugPrint('Error creating donation: $e');
      return e.toString();
    }
  }

  // Accept a donation
  Future<String?> acceptDonation(String donationId) async {
    try {
      debugPrint('Accepting donation: $donationId');
      
      // Get donation data
      final donationDoc = await _firestore.collection('donations').doc(donationId).get();
      if (!donationDoc.exists) {
        debugPrint('Donation not found: $donationId');
        return 'Donation not found';
      }
      
      final donationData = donationDoc.data() as Map<String, dynamic>;
      final donorId = donationData['donorId'] as String;
      final campaignId = donationData['campaignId'] as String;
      final donationType = donationData['donationType'] as String? ?? donationData['type'] as String;
      final amount = (donationData['amount'] ?? 0).toDouble();
      final campaignTitle = donationData['campaignTitle'] as String;
      
      debugPrint('Current donation status: ${donationData['status']}');

      // Update donation status
      try {
      await _firestore.collection('donations').doc(donationId).update({
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });
        debugPrint('Updated donation status to accepted');
      } catch (updateError) {
        debugPrint('Error updating donation status: $updateError');
        return 'Error updating donation status: $updateError';
      }

      // If monetary donation, update campaign's donated amount
      if (donationType == 'monetary') {
        try {
        // Get current campaign data
        final campaignDoc = await _firestore.collection('campaigns').doc(campaignId).get();
        if (!campaignDoc.exists) {
            debugPrint('Campaign not found: $campaignId');
          return 'Campaign not found';
        }
        
        final campaignData = campaignDoc.data() as Map<String, dynamic>;
        final currentDonated = (campaignData['donatedAmount'] ?? 0).toDouble();
        final targetAmount = (campaignData['targetAmount'] ?? 0).toDouble();
        
        // Calculate new values
        final newDonatedAmount = currentDonated + amount;
        double progress = 0.0;
        if (targetAmount > 0) {
          progress = newDonatedAmount / targetAmount;
          if (progress > 1.0) progress = 1.0; // Cap at 100%
        }
        
        // Update campaign with new values
        await _firestore.collection('campaigns').doc(campaignId).update({
          'donatedAmount': newDonatedAmount,
          'progress': progress
        });
          debugPrint('Updated campaign donated amount to $newDonatedAmount');
        } catch (campaignError) {
          debugPrint('Error updating campaign: $campaignError');
          // Continue even if there's an error updating the campaign
        }
      }

      // Create notification for the donor
      try {
      await _firestore.collection('notifications').add({
        'userId': donorId,
        'title': 'Donation Accepted',
        'description': 'Your donation to $campaignTitle has been accepted',
        'date': Timestamp.now(),
        'isRead': false,
        'donationId': donationId,
        'type': 'donation_accepted',
        'createdAt': FieldValue.serverTimestamp(),
      });
        debugPrint('Created acceptance notification for donor');
      } catch (notificationError) {
        debugPrint('Error creating notification: $notificationError');
        // Continue even if there's an error creating the notification
      }

      // Verify donation status was updated correctly
      final verifyDoc = await _firestore.collection('donations').doc(donationId).get();
      if (verifyDoc.exists) {
        final data = verifyDoc.data() as Map<String, dynamic>;
        debugPrint('Verified donation status: ${data['status']}');
      }

      return null; // Success - no error message
    } catch (e) {
      debugPrint('Error accepting donation: $e');
      return e.toString();
    }
  }

  // Reject a donation
  Future<String?> rejectDonation(String donationId) async {
    try {
      // Get donation data
      final donationDoc = await _firestore.collection('donations').doc(donationId).get();
      if (!donationDoc.exists) {
        return 'Donation not found';
      }
      
      final donationData = donationDoc.data() as Map<String, dynamic>;
      final donorId = donationData['donorId'] as String;
      final campaignTitle = donationData['campaignTitle'] as String;

      // Update donation status
      await _firestore.collection('donations').doc(donationId).update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create notification for the donor
      await _firestore.collection('notifications').add({
        'userId': donorId,
        'title': 'Donation Rejected',
        'description': 'Your donation to $campaignTitle has been rejected',
        'date': Timestamp.now(),
        'isRead': false,
        'donationId': donationId,
        'type': 'donation_rejected',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // Success - no error message
    } catch (e) {
      debugPrint('Error rejecting donation: $e');
      return e.toString();
    }
  }

  // Get pending donations for a Grama Niladhari
  Stream<QuerySnapshot> getPendingDonations(String userId) {
    return _firestore
        .collection('donations')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get notifications for a user
  Stream<QuerySnapshot> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }
  
  // Get donation history for the current user
  Future<List<Donation>> getUserDonationHistory({String? statusFilter}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('getUserDonationHistory: No current user found');
        return [];
      }
      
      debugPrint('getUserDonationHistory: Fetching for user ID: ${currentUser.uid} with filter: $statusFilter');
      
      // First, get all donations for this user to check if any exist
      final allDonationsSnapshot = await _firestore
          .collection('donations')
          .where('donorId', isEqualTo: currentUser.uid)
          .get();
      
      debugPrint('getUserDonationHistory: Total donations for user (unfiltered): ${allDonationsSnapshot.docs.length}');
      
      // Check if we need to create a test donation for demonstration purposes
      if (allDonationsSnapshot.docs.isEmpty) {
        debugPrint('getUserDonationHistory: No donations found for this user');
        
        // Uncomment if you want to automatically create a test donation
        // This is just for testing purposes
        /*
        bool createTestDonation = true;
        if (createTestDonation) {
          debugPrint('Creating a test donation for demonstration');
          try {
            final testDonationRef = await _firestore.collection('donations').add({
              'campaignId': 'test-campaign-id',
              'campaignTitle': 'Test Campaign',
              'donorId': currentUser.uid,
              'donorName': currentUser.displayName ?? 'Test User',
              'amount': 500.0,
              'items': 'Rice, Sugar, Oil',
              'donationType': 'items',
              'status': 'pending',
              'createdAt': FieldValue.serverTimestamp(),
            });
            
            debugPrint('Created test donation with ID: ${testDonationRef.id}');
            
            // Wait for a moment to ensure the donation is saved
            await Future.delayed(const Duration(seconds: 1));
            
            // Get the new donation
            final newDonation = await _firestore
                .collection('donations')
                .doc(testDonationRef.id)
                .get();
                
            if (newDonation.exists) {
              return [Donation.fromFirestore(newDonation)];
            }
          } catch (e) {
            debugPrint('Error creating test donation: $e');
          }
        }
        */
        
        return [];
      }
      
      // Log all statuses to help debug
      for (var doc in allDonationsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('Donation ${doc.id}: status = ${data['status'] ?? 'unknown'}, type = ${data['donationType'] ?? 'unknown'}');
      }
      
      // If there's no status filter or it's 'all', return all donations
      if (statusFilter == null || statusFilter == 'all') {
        debugPrint('getUserDonationHistory: No filter applied, showing all donations');
        
        // Convert to Donation objects directly from the snapshot we already have
        final donations = allDonationsSnapshot.docs
            .map((doc) => Donation.fromFirestore(doc))
            .toList();
        
        // Sort by creation date (newest first)
        donations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        debugPrint('getUserDonationHistory: Returning ${donations.length} total donations');
        return donations;
      }
      
      // If we have a specific status filter, apply it
      debugPrint('getUserDonationHistory: Applying filter: $statusFilter');
      
      // First try to filter in memory from documents we already have
      final filteredDocs = allDonationsSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['status'] == statusFilter;
      }).toList();
      
      if (filteredDocs.isNotEmpty) {
        debugPrint('getUserDonationHistory: Found ${filteredDocs.length} donations with status: $statusFilter (in-memory filter)');
        
        final donations = filteredDocs
            .map((doc) => Donation.fromFirestore(doc))
            .toList();
        
        // Sort by creation date (newest first)
        donations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        return donations;
      }
      
      // If in-memory filtering returns no results, try a direct query as backup
      debugPrint('getUserDonationHistory: No results from in-memory filter, trying direct query');
      final querySnapshot = await _firestore
          .collection('donations')
          .where('donorId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: statusFilter)
          .orderBy('createdAt', descending: true)
          .get();
      
      debugPrint('getUserDonationHistory: Direct query found ${querySnapshot.docs.length} donations with status: $statusFilter');
      
      final donations = querySnapshot.docs
          .map((doc) => Donation.fromFirestore(doc))
          .toList();
      
      return donations;
    } catch (e) {
      debugPrint('Error getting donation history: $e');
      return [];
    }
  }
} 