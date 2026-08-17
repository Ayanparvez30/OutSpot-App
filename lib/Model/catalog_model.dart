// Catalog API Response Models
// Endpoint: GET /api/shop/catalog

class CatalogResponse {
  final bool success;
  final CatalogData data;

  CatalogResponse({
    required this.success,
    required this.data,
  });

  factory CatalogResponse.fromJson(Map<String, dynamic> json) {
    return CatalogResponse(
      success: json['success'] ?? false,
      data: CatalogData.fromJson(json['data'] ?? {}),
    );
  }
}

class CatalogData {
  final int total;
  final List<CatalogItem> items;
  final Map<String, List<CatalogItem>> grouped;

  CatalogData({
    required this.total,
    required this.items,
    required this.grouped,
  });

  factory CatalogData.fromJson(Map<String, dynamic> json) {
    return CatalogData(
      total: json['total'] ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CatalogItem.fromJson(e))
              .toList() ??
          [],
      grouped: (json['grouped'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              (value as List<dynamic>)
                  .map((e) => CatalogItem.fromJson(e))
                  .toList(),
            ),
          ) ??
          {},
    );
  }
}

class CatalogItem {
  final int id;
  final String slot;
  final String name;
  final String brand;
  final String imageUrl;
  final String priceUsd;
  final Map<String, dynamic> payload;
  final bool isFeatured;
  final String? appleProductId;
  final String? googleProductId;

  CatalogItem({
    required this.id,
    required this.slot,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.priceUsd,
    required this.payload,
    required this.isFeatured,
    this.appleProductId,
    this.googleProductId,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: json['id'] ?? 0,
      slot: json['slot'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      priceUsd: json['priceUsd'] ?? '0',
      payload: json['payload'] ?? {},
      isFeatured: json['isFeatured'] ?? false,
      appleProductId: json['appleProductId'],
      googleProductId: json['googleProductId'],
    );
  }
}
