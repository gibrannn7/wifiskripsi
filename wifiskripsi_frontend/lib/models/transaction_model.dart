class TransactionModel {
  final int id;
  final String orderId;
  final int packageId;
  final int grossAmount;
  final String status;
  final String paymentType;
  final String snapToken;
  final String createdAt;
  final String? packageName;

  TransactionModel({
    required this.id,
    required this.orderId,
    required this.packageId,
    required this.grossAmount,
    required this.status,
    required this.paymentType,
    required this.snapToken,
    required this.createdAt,
    this.packageName,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: double.tryParse(json['id']?.toString() ?? '0')?.toInt() ?? 0,
      orderId: json['order_id']?.toString() ?? '',
      packageId: double.tryParse(json['package_id']?.toString() ?? '0')?.toInt() ?? 0,
      grossAmount: double.tryParse(json['gross_amount']?.toString() ?? '0')?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'pending',
      paymentType: json['payment_type']?.toString() ?? '-',
      snapToken: json['snap_token']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      packageName: json['package'] != null ? json['package']['package_name']?.toString() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'package_id': packageId,
      'gross_amount': grossAmount,
      'status': status,
      'payment_type': paymentType,
      'snap_token': snapToken,
      'created_at': createdAt,
    };
  }
}
