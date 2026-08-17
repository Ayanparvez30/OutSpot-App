class GroupMember {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String name;
  final String? avatar;
  final int points;
  final int thisWeekPoints;
  final String? profileUrl;
  final String role;
  final DateTime joinedAt;

  GroupMember({
    required this.id,
    required this.username,
    required this.name,
    required this.firstName,
    required this.lastName,
    this.avatar,
    required this.points,
    required this.thisWeekPoints,
    this.profileUrl,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final first = (json['firstName'] ?? '').toString().trim();
    final last = (json['lastName'] ?? '').toString().trim();
    final fullName = [first, last].where((s) => s.isNotEmpty).join(' ');

    return GroupMember(
      firstName: first,
      lastName: last,
      id: json['id'],
      username: json['username'] ?? 'Unknown',

      name: fullName.isNotEmpty ? fullName : json['username'] ?? 'Unknown',
      avatar: json['avatarUrl'],
      points: json['totalPoints'] ?? 0,
      thisWeekPoints: json['thisWeekPoints'] ?? 0,
      profileUrl: json['profileUrl'],
      role: json['role'] ?? 'MEMBER',
      joinedAt: DateTime.tryParse(json['joinedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class Group {
  final int groupId;
  final String groupName;
  final String? groupImage;
  final int createdById;
  final bool isLocked;
  final bool isMuted;
  final List<GroupMember> members;

  Group({
    required this.groupId,
    required this.groupName,
    required this.isMuted,
    this.groupImage,
    required this.createdById,
    required this.isLocked,
    required this.members,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    final membersJson = json['members'] as List? ?? [];
    final members =
        membersJson
            .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
            .toList();

    return Group(
      groupId: json['groupId'],
      groupName: json['groupName'] ?? 'Unknown Group',
      groupImage: json['groupImage'],
      createdById: json['createdById'],
      isMuted: json['isMuted'] ?? false,
      isLocked: json['isLocked'] ?? false,
      members: members,
    );
  }
}
