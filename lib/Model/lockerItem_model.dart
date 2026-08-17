class LockerItem {
  final int id;
  final String avatarUrl;
  final String selfieUrl;
  final String createdAt;

  LockerItem({
    required this.id,
    required this.avatarUrl,
    required this.selfieUrl,
    required this.createdAt,
  });

  factory LockerItem.fromJson(Map<String, dynamic> json) {
    return LockerItem(
      id: json['id'] ?? 0,
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      selfieUrl: json['selfieUrl']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}