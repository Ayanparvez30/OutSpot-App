class ActiveMultiplier {
  final int id;
  final int userId;
  final double factor;
  final DateTime startedAt;
  final DateTime endsAt;
  final String source;
  final String productId;
  final String receiptTxId;

  ActiveMultiplier({
    required this.id,
    required this.userId,
    required this.factor,
    required this.startedAt,
    required this.endsAt,
    required this.source,
    required this.productId,
    required this.receiptTxId,
  });

  factory ActiveMultiplier.fromJson(Map<String, dynamic> json) {
    return ActiveMultiplier(
      id: json['id'],
      userId: json['userId'],
      factor: json['factor'].toDouble(),
      startedAt: DateTime.parse(json['startedAt']),
      endsAt: DateTime.parse(json['endsAt']),
      source: json['source'],
      productId: json['productId'],
      receiptTxId: json['receiptTxId'],
    );
  }
}
