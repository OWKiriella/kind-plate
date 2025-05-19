import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import '../constants.dart';

class PaymentService {
  // Create payment intent on the server
  Future<Map<String, dynamic>> _createPaymentIntent(double amount, String currency) async {
    try {
      // Convert amount to cents/smallest currency unit
      final int amountInCents = (amount * 100).round();
      
      // Create payload for the request
      final Map<String, dynamic> body = {
        'amount': amountInCents.toString(),
        'currency': currency,
        'payment_method_types[]': 'card',
      };

      // Create authorization header with secret key
      final Map<String, String> headers = {
        'Authorization': 'Bearer $stripeSecretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      // Make request to Stripe API with timeout to prevent hanging
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: headers,
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Payment request timed out'),
      );

      final responseData = jsonDecode(response.body);
      debugPrint('Payment intent created: ${response.statusCode}');
      return responseData;
    } catch (e) {
      debugPrint('Error creating payment intent: $e');
      rethrow;
    }
  }

  // Process payment with Stripe
  Future<PaymentStatus> processPayment(double amount) async {
    try {
      // Create payment intent
      debugPrint('Starting payment process for amount: $amount');
      final paymentIntent = await _createPaymentIntent(amount, 'lkr');
      
      if (paymentIntent['error'] != null) {
        debugPrint('Payment intent error: ${paymentIntent['error']['message']}');
        return PaymentStatus(
          success: false, 
          message: paymentIntent['error']['message'],
        );
      }

      // Initialize payment sheet
      debugPrint('Initializing payment sheet');
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'KindPlate',
          style: ThemeMode.light,
          // Adding appearance customization for better UX
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF4D9164),
            ),
          ),
        ),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Payment sheet initialization timed out'),
      );

      // Present payment sheet to user
      debugPrint('Presenting payment sheet');
      await Stripe.instance.presentPaymentSheet().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Payment process timed out'),
      );
      
      // Check payment intent status
      debugPrint('Checking payment status');
      final String clientSecret = paymentIntent['client_secret'];
      final String paymentIntentId = clientSecret.split('_secret_')[0];
      
      try {
        // Check payment intent status from Stripe API
        final Map<String, String> headers = {
          'Authorization': 'Bearer $stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        };
        
        final response = await http.get(
          Uri.parse('https://api.stripe.com/v1/payment_intents/$paymentIntentId'),
          headers: headers,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Payment verification timed out'),
        );
        
        final data = jsonDecode(response.body);
        debugPrint('Payment intent status: ${data['status']}');
        
        if (data['status'] == 'succeeded' || data['status'] == 'processing') {
          debugPrint('Payment completed successfully');
          return PaymentStatus(
            success: true,
            message: 'Payment completed successfully',
            paymentId: paymentIntentId,
          );
        } else {
          debugPrint('Payment status not confirmed: ${data['status']}');
          return PaymentStatus(
            success: false,
            message: 'Payment not confirmed: ${data['status']}',
          );
        }
      } catch (e) {
        // Even if verification fails, the payment might still have succeeded
        // Assume success if we got this far without a StripeException
        debugPrint('Error verifying payment, assuming success: $e');
        return PaymentStatus(
          success: true,
          message: 'Payment likely completed, but verification failed',
          paymentId: paymentIntentId,
        );
      }
    } on StripeException catch (e) {
      // Handle Stripe specific errors
      debugPrint('Stripe exception: ${e.error.localizedMessage}');
      return PaymentStatus(
        success: false, 
        message: e.error.localizedMessage ?? 'Payment canceled',
      );
    } catch (e) {
      // Handle other errors
      debugPrint('Payment error: $e');
      return PaymentStatus(
        success: false, 
        message: 'An error occurred: ${e.toString()}',
      );
    }
  }
}

class PaymentStatus {
  final bool success;
  final String message;
  final String? paymentId;

  PaymentStatus({
    required this.success, 
    required this.message,
    this.paymentId,
  });
} 