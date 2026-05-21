class PackageModel {
  final int id;
  final String packageName;
  final int speedMbps;
  final int price;
  final int durationDays;
  final bool isPromoted;

  PackageModel({
    required this.id,
    required this.packageName,
    required this.speedMbps,
    required this.price,
    required this.durationDays,
    required this.isPromoted,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: double.tryParse(json['id']?.toString() ?? '0')?.toInt() ?? 0,
      packageName: json['package_name']?.toString() ?? '',
      speedMbps: double.tryParse(json['speed_mbps']?.toString() ?? '0')?.toInt() ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0')?.toInt() ?? 0,
      durationDays: double.tryParse(json['duration_days']?.toString() ?? '0')?.toInt() ?? 0,
      isPromoted: json['is_promoted'] == true || json['is_promoted'] == 1 || json['is_promoted'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'package_name': packageName,
      'speed_mbps': speedMbps,
      'price': price,
      'duration_days': durationDays,
      'is_promoted': isPromoted,
    };
  }
}
