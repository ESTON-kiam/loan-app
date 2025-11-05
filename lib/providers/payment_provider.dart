import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/payment_model.dart';
// import 'firestore_service.dart';
import '../services/firestore_service.dart';

class PaymentService {
  final FirestoreService _firestoreService = FirestoreService();

  // M-Pesa Configuration (use sandbox for testing)
  static const String _baseUrl = 'https://sandbox.safaricom.co.ke';
  static const String _consumerKey = 'YOUR_CONSUMER_KEY';
  static const String _consumerSecret = 'YOUR_CONSUMER_SECRET';
  static const String _shortCode = 'YOUR_SHORTCODE';
  static const String _passKey = 'YOUR_PASSKEY';
  static const String _callbackUrl = 'YOUR_CALLBACK_URL';

  // Get M-Pesa access token
  Future<String> _getAccessToken() async {
    final credentials = base64.encode(
      utf8.encode('$_consumerKey:$_consumerSecret'),
    );

    final response = await http.get(
      Uri.parse('$_baseUrl/oauth/v1/generate?grant_type=client_credentials'),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['access_token'];
    } else {
      throw Exception('Failed to get access token');
    }
  }

  // Initiate M-Pesa STK Push
  Future<Map<String, dynamic>> initiateMpesaPayment({
    required String phoneNumber,
    required double amount,
    required String accountReference,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      final timestamp = _getTimestamp();
      final password = _generatePassword(timestamp);

      // Clean phone number (remove +254 or 254 prefix, ensure it starts with 254)
      String cleanPhone = phoneNumber.replaceAll('+', '').replaceAll(' ', '');
      if (cleanPhone.startsWith('0')) {
        cleanPhone = '254${cleanPhone.substring(1)}';
      } else if (!cleanPhone.startsWith('254')) {
        cleanPhone = '254$cleanPhone';
      }

      final requestBody = {
        'BusinessShortCode': _shortCode,
        'Password': password,
        'Timestamp': timestamp,
        'TransactionType': 'CustomerPayBillOnline',
        'Amount': amount.toInt().toString(),
        'PartyA': cleanPhone,
        'PartyB': _shortCode,
        'PhoneNumber': cleanPhone,
        'CallBackURL': _callbackUrl,
        'AccountReference': accountReference,
        'TransactionDesc': 'Loan Payment',
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/mpesa/stkpush/v1/processrequest'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('STK Push failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Payment initiation failed: $e');
    }
  }

  // Query M-Pesa transaction status
  Future<Map<String, dynamic>> queryTransactionStatus({
    required String checkoutRequestId,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      final timestamp = _getTimestamp();
      final password = _generatePassword(timestamp);

      final requestBody = {
        'BusinessShortCode': _shortCode,
        'Password': password,
        'Timestamp': timestamp,
        'CheckoutRequestID': checkoutRequestId,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/mpesa/stkpushquery/v1/query'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Query failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Transaction query failed: $e');
    }
  }

  // Process card payment (Stripe/PayPal integration)
  Future<bool> processCardPayment({
    required String loanId,
    required String userId,
    required double amount,
    required Map<String, dynamic> cardDetails,
  }) async {
    try {
      // TODO: Implement Stripe or PayPal integration
      // This is a placeholder for card payment processing
      
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Create payment record
      final payment = PaymentModel(
        id: const Uuid().v4(),
        loanId: loanId,
        userId: userId,
        amount: amount,
        paymentDate: DateTime.now(),
        paymentMethod: 'Card',
        status: PaymentStatus.completed,
        transactionId: 'CARD${DateTime.now().millisecondsSinceEpoch}',
      );

      await _firestoreService.createPayment(payment);
      return true;
    } catch (e) {
      print('Card payment failed: $e');
      return false;
    }
  }

  // Process bank transfer
  Future<bool> processBankTransfer({
    required String loanId,
    required String userId,
    required double amount,
    required Map<String, dynamic> bankDetails,
  }) async {
    try {
      // TODO: Implement bank transfer integration
      // This is a placeholder for bank transfer processing
      
      // Create pending payment record
      final payment = PaymentModel(
        id: const Uuid().v4(),
        loanId: loanId,
        userId: userId,
        amount: amount,
        paymentDate: DateTime.now(),
        paymentMethod: 'Bank Transfer',
        status: PaymentStatus.pending,
        transactionId: 'BANK${DateTime.now().millisecondsSinceEpoch}',
      );

      await _firestoreService.createPayment(payment);
      return true;
    } catch (e) {
      print('Bank transfer failed: $e');
      return false;
    }
  }

  // Helper: Generate M-Pesa password
  String _generatePassword(String timestamp) {
    final data = '$_shortCode$_passKey$timestamp';
    return base64.encode(utf8.encode(data));
  }

  // Helper: Get timestamp
  String _getTimestamp() {
    final now = DateTime.now();
    return '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
  }

  // Verify payment completion
  Future<bool> verifyPayment(String transactionId) async {
    try {
      // Query payment status from database
      // This is a simplified version
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      print('Payment verification failed: $e');
      return false;
    }
  }

  // Get payment history
  Future<List<PaymentModel>> getPaymentHistory(String userId) async {
    return await _firestoreService.getUserPayments(userId);
  }

  // Calculate payment processing fee
  double calculateProcessingFee(double amount, String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'm-pesa':
        return amount * 0.01; // 1% fee
      case 'card':
        return amount * 0.025; // 2.5% fee
      case 'bank transfer':
        return 50.0; // Fixed fee
      default:
        return 0.0;
    }
  }
}