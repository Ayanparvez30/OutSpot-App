class GlobalModel {
  final int chatId;
  final String name;
  final String city;
  final bool isLocked;
  final int memberCount;
  final String updatedAt;
  final MessageModel? latestMessage;

  GlobalModel({
    required this.chatId,
    required this.name,
    required this.city,
    required this.isLocked,
    required this.memberCount,
    required this.updatedAt,
    this.latestMessage,
  });

  factory GlobalModel.fromJson(Map<String, dynamic> json) {
    return GlobalModel(
      // 🛡️ Safe Integer Parsing for chatId
      chatId:
          json['chatId'] is int
              ? json['chatId']
              : int.tryParse('${json['chatId']}') ?? 0,

      name: json['name']?.toString() ?? 'Unknown Group',

      city: json['city']?.toString() ?? '',

      isLocked: json['isLocked'] == true,

      updatedAt: json['updatedAt']?.toString() ?? '',

      // 🛡️ Safe Integer Parsing for memberCount
      memberCount:
          json['memberCount'] is int
              ? json['memberCount']
              : int.tryParse('${json['memberCount']}') ?? 0,

      // 🛡️ Safe Parsing for latestMessage (Handle null)
      latestMessage:
          (json['latestMessage'] != null && json['latestMessage'] is Map)
              ? MessageModel.fromJson(json['latestMessage'])
              : null,
    );
  }
}

class MessageModel {
  final int id;
  final String content;
  final String? imageUrl; // Nullable
  final String createdAt;
  final Sender? sender;

  MessageModel({
    required this.id,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.sender,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      // 🛡️ Safe Parsing for Message ID
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,

      content: json['content']?.toString() ?? '',

      // 🛡️ ImageUrl can be null, so we keep it nullable
      imageUrl: json['imageUrl']?.toString(),

      createdAt: json['createdAt']?.toString() ?? '',

      sender:
          (json['sender'] != null && json['sender'] is Map)
              ? Sender.fromJson(json['sender'])
              : null,
    );
  }
}

class Sender {
  final int id;
  final String username;
  final String firstName;
  final String lastName;

  Sender({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
  });

  factory Sender.fromJson(Map<String, dynamic> json) {
    return Sender(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      username: json['username']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
    );
  }
}
