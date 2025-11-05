import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/loan_model.dart';
import '../services/firestore_service.dart';

class LoanProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List _loans = [];
  bool _isLoading = false;
  LoanModel? _selectedLoan;

  List get loans => _loans;
  bool get isLoading => _isLoading;
  LoanModel? get selectedLoan => _selectedLoan;

  Future fetchUserLoans(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _loans = await _firestoreService.getUserLoans(userId);
    } catch (e) {
      print('Error fetching loans: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future applyForLoan({
    required String userId,
    required double amount,
    required int durationMonths,
    required String purpose,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final totalPayable = LoanModel.calculateTotalPayable(amount, 15.0, durationMonths);
      final monthlyInstallment = LoanModel.calculateMonthlyInstallment(totalPayable, durationMonths);

      final loan = LoanModel(
        id: const Uuid().v4(),
        userId: userId,
        amount: amount,
        durationMonths: durationMonths,
        purpose: purpose,
        appliedAt: DateTime.now(),
        totalPayable: totalPayable,
        monthlyInstallment: monthlyInstallment,
      );

      await _firestoreService.createLoan(loan);
      _loans.insert(0, loan);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void selectLoan(LoanModel loan) {
    _selectedLoan = loan;
    notifyListeners();
  }

  double getTotalBorrowed(String userId) {
    return _loans
        .where((loan) => loan.userId == userId && loan.status == LoanStatus.disbursed)
        .fold(0, (sum, loan) => sum + loan.amount);
  }

  double getTotalOutstanding(String userId) {
    return _loans
        .where((loan) => loan.userId == userId && loan.status == LoanStatus.disbursed)
        .fold(0, (sum, loan) => sum + loan.totalPayable);
  }
}