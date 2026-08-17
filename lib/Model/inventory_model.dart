// 1. Root Response Model
class InventoryResponse {
  final bool success;
  final InventoryData data;

  InventoryResponse({
    required this.success,
    required this.data,
  });

  factory InventoryResponse.fromJson(Map<String, dynamic> json) {
    return InventoryResponse(
      success: json['success'] ?? false,
      data: InventoryData.fromJson(json['data'] ?? {}),
    );
  }
}

// 2. Data Wrapper (Holds grouped and flat lists)
class InventoryData {
  final int totalOwned;
  final Map<String, List<InventoryModel>> grouped;
  final List<InventoryModel> flat;
  final Map<String, InventoryModel> equippedBySlot;

  InventoryData({
    required this.totalOwned,
    required this.grouped,
    required this.flat,
    required this.equippedBySlot,
  });

  factory InventoryData.fromJson(Map<String, dynamic> json) {
    return InventoryData(
      totalOwned: json['totalOwned'] ?? 0,
      // Grouped Data parsing (Map<String, List>)
      grouped: (json['grouped'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              (value as List<dynamic>)
                  .map((e) => InventoryModel.fromJson(e))
                  .toList(),
            ),
          ) ??
          {},
      // Flat Data parsing (List)
      flat: (json['flat'] as List<dynamic>?)
              ?.map((e) => InventoryModel.fromJson(e))
              .toList() ??
          [],
      // Equipped items by slot
      equippedBySlot: (json['equippedBySlot'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              InventoryModel.fromJson(value),
            ),
          ) ??
          {},
    );
  }
}

// 3. Inventory Model (Single Item Wrapper)
class InventoryModel {
  final int id;
  final int userId;
  final int itemId;
  final bool equipped;
  final String acquiredAt;
  final ItemDetail item;

  InventoryModel({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.equipped,
    required this.acquiredAt,
    required this.item,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: json['id'] ?? 0,
      // Grouped ডাটাতে অনেক সময় userId/itemId থাকে না, তাই 0 ডিফল্ট রাখা নিরাপদ
      userId: json['userId'] ?? 0,
      itemId: json['itemId'] ?? 0,
      equipped: json['equipped'] ?? false,
      acquiredAt: json['acquiredAt'] ?? '',
      item: ItemDetail.fromJson(json['item'] ?? {}),
    );
  }
}

// 4. Item Detail (Specific Product Info)
class ItemDetail {
  final int id;
  final String slot;
  final String name;
  final String brand;
  final String imageUrl;
  final String priceUsd;
  final Map<String, dynamic> payload;
  final bool isFeatured;
  final String createdAt;
  final String updatedAt;

  ItemDetail({
    required this.id,
    required this.slot,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.priceUsd,
    required this.payload,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItemDetail.fromJson(Map<String, dynamic> json) {
    return ItemDetail(
      id: json['id'] ?? 0,
      slot: json['slot'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      priceUsd: json['priceUsd'] ?? '0',
      payload: json['payload'] ?? {},
      isFeatured: json['isFeatured'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}