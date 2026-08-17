class BundleModel {
  final String productId;
  final int points;
  final String priceUsd;
  final String? appleProductId;
  final String? googleProductId;

  BundleModel({
    required this.productId,
    required this.points,
    required this.priceUsd,
    this.appleProductId,
    this.googleProductId,
  });

  factory BundleModel.fromJson(Map<String, dynamic> json) {
    return BundleModel(
      productId: json['productId'] ?? '',
      points: json['points'] ?? 0,
      priceUsd: json['priceUsd'] ?? '',
      appleProductId: json['appleProductId'],
      googleProductId: json['googleProductId'],
    );
  }
}
