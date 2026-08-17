class PointMultiplier {
  final String productId;
  final double factor;
  final int hours;
  final String priceUsd;
  final String? appleProductId;
  final String? googleProductId;

  PointMultiplier({
    required this.productId,
    required this.factor,
    required this.hours,
    required this.priceUsd,
    this.appleProductId,
    this.googleProductId,
  });

  factory PointMultiplier.fromJson(Map<String, dynamic> json) {
    return PointMultiplier(
      productId: json['productId'],
      factor: json['factor'].toDouble(),
      hours: json['hours'],
      priceUsd: json['priceUsd'],
      appleProductId: json['appleProductId'],
      googleProductId: json['googleProductId'],
    );
  }
}


