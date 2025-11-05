enum PaymentStatus { pending, completed, failed }

class PaymentModel {
  final String id;
  final String loanId;
  final String userId;
  final double amount;
  final DateTime paymentDate;
  final PaymentStatus status;
  final String paymentMethod;
  final String? transactionId;

  PaymentModel({
    required this.id,
    required this.loanId,
    required this.userId,
    required this.amount,
    required this.paymentDate,
    this.status = PaymentStatus.pending,
    required this.paymentMethod,
    this.transactionId,
  });

  factory PaymentModel.fromJson(Map json) {
    return PaymentModel(
      id: json['id'] ?? '',
      loanId: json['loanId'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate'] ?? DateTime.now().toIso8601String()),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${json['status']}',
        orElse: () => PaymentStatus.pending,
      ),
      paymentMethod: json['paymentMethod'] ?? '',
      transactionId: json['transactionId'],
    );
  }

  Map toJson() {
    return {
      'id': id,
      'loanId': loanId,
      'userId': userId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
    };
  }
}