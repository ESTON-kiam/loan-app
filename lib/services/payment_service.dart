import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/payment_model.dart';
import '../services/firestore_service.dart';

class PaymentProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List _payments = [];
  bool _isLoading = false;

  List get payments => _payments;
  bool get isLoading => _isLoading;

  Future fetchUserPayments(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _payments = await _firestoreService.getUserPayments(userId);
    } catch (e) {
      print('Error fetching payments: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future makePayment({
    required String loanId,
    required String userId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final payment = PaymentModel(
        id: const Uuid().v4(),
        loanId: loanId,
        userId: userId,
        amount: amount,
        paymentDate: DateTime.now(),
        paymentMethod: paymentMethod,
        status: PaymentStatus.completed,
        transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
      );

      await _firestoreService.createPayment(payment);
      _payments.insert(0, payment);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  double getTotalPaid(String loanId) {
    return _payments
        .where((payment) => payment.loanId == loanId && payment.status == PaymentStatus.completed)
        .fold(0, (sum, payment) => sum + payment.amount);
  }
}