import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/loan_model.dart';
import '../models/payment_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Loan Operations
  Future<void> createLoan(LoanModel loan) async {
    await _firestore.collection('loans').doc(loan.id).set(loan.toJson());
  }

  Future<List<LoanModel>> getUserLoans(String userId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('loans')
        .where('userId', isEqualTo: userId)
        .orderBy('appliedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => LoanModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<LoanModel?> getLoanById(String loanId) async {
    DocumentSnapshot doc = await _firestore.collection('loans').doc(loanId).get();
    if (doc.exists) {
      return LoanModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Stream<List<LoanModel>> getUserLoansStream(String userId) {
    return _firestore
        .collection('loans')
        .where('userId', isEqualTo: userId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LoanModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Payment Operations
  Future<void> createPayment(PaymentModel payment) async {
    await _firestore.collection('payments').doc(payment.id).set(payment.toJson());
  }

  Future<List<PaymentModel>> getLoanPayments(String loanId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('payments')
        .where('loanId', isEqualTo: loanId)
        .orderBy('paymentDate', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PaymentModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<PaymentModel>> getUserPayments(String userId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('paymentDate', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PaymentModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }
}