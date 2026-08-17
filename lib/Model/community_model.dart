import 'package:outspot/Model/story_model.dart';

class CommunityModel {
  final int id;
  final String name;
  final String? imageUrl;
  final String? bio;
  final int membersCount;
  final bool isCreator;
  final bool isMember;
  final String? joinedAt;

  CommunityModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.bio,
    required this.membersCount,
    required this.isCreator,
    required this.isMember,
    this.joinedAt,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'],
      name: json['name'] ?? "",
      imageUrl: json['imageUrl'],
      bio: json['bio'],
      membersCount: json['membersCount'] ?? 0,
      isCreator: json['isCreator'] ?? false,
      isMember: json['isMember'] ?? false,
      joinedAt: json['joinedAt'],
    );
  }
}

class CommunityGroupModel {
  final CommunityModel community;
  final List<StoryModel> stories;

  // Per-community pagination (horizontal load-more).
  int page;
  bool hasMore;
  int totalCount;
  bool loading;

  CommunityGroupModel({
    required this.community,
    required this.stories,
    this.page = 1,
    this.hasMore = false,
    this.totalCount = 0,
    this.loading = false,
  });

  factory CommunityGroupModel.fromJson(Map<String, dynamic> j) {
    final community = CommunityModel.fromJson(
      (j['community'] as Map).cast<String, dynamic>(),
    );
    final storiesJson = (j['stories'] as List?) ?? const [];
    final stories =
        storiesJson
            .map((e) => StoryModel.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
    return CommunityGroupModel(
      community: community,
      stories: stories,
      page: (j['page'] is int) ? j['page'] : int.tryParse('${j['page']}') ?? 1,
      hasMore: j['hasMore'] == true,
      totalCount:
          (j['totalCount'] is int)
              ? j['totalCount']
              : int.tryParse('${j['totalCount']}') ?? 0,
    );
  }
}
