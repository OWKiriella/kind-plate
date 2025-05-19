import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Donation {
  final String id;
  final String campaignId;
  final String campaignTitle;
  final String donorId;
  final String donorName;
  final double amount;
  final String items;
  final String donationType;
  final DateTime createdAt;
  final String status; // 'pending', 'accepted', 'rejected'

  Donation({
    required this.id,
    required this.campaignId,
    required this.campaignTitle,
    required this.donorId,
    required this.donorName,
    required this.amount,
    required this.items,
    required this.donationType,
    required this.createdAt,
    required this.status,
  });

  String get formattedDate => DateFormat('dd/MM/yyyy').format(createdAt);
  
  String get donationValue {
    if (donationType == 'monetary') {
      return 'Rs.${amount.toStringAsFixed(2)}';
    } else {
      return items;
    }
  }

  factory Donation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Donation(
      id: doc.id,
      campaignId: data['campaignId'] ?? '',
      campaignTitle: data['campaignTitle'] ?? 'Unknown Campaign',
      donorId: data['donorId'] ?? '',
      donorName: data['donorName'] ?? 'Anonymous',
      amount: (data['amount'] ?? 0.0).toDouble(),
      items: data['items'] ?? '',
      donationType: data['donationType'] ?? 'monetary',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'campaignId': campaignId,
      'campaignTitle': campaignTitle,
      'donorId': donorId,
      'donorName': donorName,
      'amount': amount,
      'items': items,
      'donationType': donationType,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }
} 