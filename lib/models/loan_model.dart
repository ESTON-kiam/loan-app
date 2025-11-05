enum LoanStatus { pending, approved, rejected, disbursed, completed }

class LoanModel {
  final String id;
  final String userId;
  final double amount;
  final int durationMonths;
  final double interestRate;
  final String purpose;
  final LoanStatus status;
  final DateTime appliedAt;
  final DateTime? approvedAt;
  final double totalPayable;
  final double monthlyInstallment;

  LoanModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.durationMonths,
    this.interestRate = 15.0, // 15% annual interest
    required this.purpose,
    this.status = LoanStatus.pending,
    required this.appliedAt,
    this.approvedAt,
    required this.totalPayable,
    required this.monthlyInstallment,
  });

  factory LoanModel.fromJson(Map json) {
    return LoanModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      durationMonths: json['durationMonths'] ?? 0,
      interestRate: (json['interestRate'] ?? 15.0).toDouble(),
      purpose: json['purpose'] ?? '',
      status: LoanStatus.values.firstWhere(
        (e) => e.toString() == 'LoanStatus.${json['status']}',
        orElse: () => LoanStatus.pending,
      ),
      appliedAt: DateTime.parse(json['appliedAt'] ?? DateTime.now().toIso8601String()),
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      totalPayable: (json['totalPayable'] ?? 0).toDouble(),
      monthlyInstallment: (json['monthlyInstallment'] ?? 0).toDouble(),
    );
  }

  Map toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'durationMonths': durationMonths,
      'interestRate': interestRate,
      'purpose': purpose,
      'status': status.toString().split('.').last,
      'appliedAt': appliedAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'totalPayable': totalPayable,
      'monthlyInstallment': monthlyInstallment,
    };
  }

  static double calculateTotalPayable(double principal, double rate, int months) {
    return principal + (principal * rate / 100 * months / 12);
  }

  static double calculateMonthlyInstallment(double totalPayable, int months) {
    return totalPayable / months;
  }
}