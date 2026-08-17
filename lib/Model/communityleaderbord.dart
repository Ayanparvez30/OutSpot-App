import 'dart:convert';

class CommunityLeaderboard {
  final int communityId;
  final String name;
  final String imageUrl;
  final int points;
  final int membersCount;
  final int rank;
  final String prize;

  CommunityLeaderboard({
    required this.communityId,
    required this.name,
    required this.imageUrl,
    required this.points,
    required this.membersCount,
    required this.rank,
    required this.prize,
  });

  factory CommunityLeaderboard.fromMap(Map<String, dynamic> m) {
    int _toInt(dynamic v) {
      if (v is int) {
        return v;
      } else if (v is String) {
        return int.tryParse(v) ?? 0;
      }
      return 0;
    }

    return CommunityLeaderboard(
      communityId: _toInt(m['communityId']),
      name: (m['name'] ?? '').toString(),
      imageUrl: (m['imageUrl'] ?? '').toString(),
      points: _toInt(m['points']),
      membersCount: _toInt(m['membersCount']),
      rank: _toInt(m['rank']),
      prize: (m['prize'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'communityId': communityId,
      'name': name,
      'imageUrl': imageUrl,
      'points': points,
      'membersCount': membersCount,
      'rank': rank,
      'prize': prize,
    };
  }

  String toJson() => json.encode(toMap());

  factory CommunityLeaderboard.fromJson(String source) =>
      CommunityLeaderboard.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return '[$rank] $name — $points pts, $membersCount members — $prize';
  }
}

class MyTopCreatedCommunity {
  final int communityId;
  final String name;
  final String imageUrl;
  final int creatorId;
  final int points;
  final int membersCount;
  final int rank;
  final String prize;

  MyTopCreatedCommunity({
    required this.communityId,
    required this.name,
    required this.imageUrl,
    required this.creatorId,
    required this.points,
    required this.membersCount,
    required this.rank,
    required this.prize,
  });

  factory MyTopCreatedCommunity.fromMap(Map<String, dynamic> map) {
    int _toInt(dynamic v) {
      if (v is int) {
        return v;
      } else if (v is String) {
        return int.tryParse(v) ?? 0;
      }
      return 0;
    }

    return MyTopCreatedCommunity(
      communityId: _toInt(map['communityId']),
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      creatorId: _toInt(map['creatorId']),
      points: _toInt(map['points']),
      membersCount: _toInt(map['membersCount']),
      rank: _toInt(map['rank']),
      prize: map['prize'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'communityId': communityId,
      'name': name,
      'imageUrl': imageUrl,
      'creatorId': creatorId,
      'points': points,
      'membersCount': membersCount,
      'rank': rank,
      'prize': prize,
    };
  }
}

class CommunityData {
  final List<CommunityLeaderboard> leaderboard;
  final MyTopCreatedCommunity? myTopCreatedCommunity;
  final List<MyTopCreatedCommunity> myCreatedCommunities;

  CommunityData({
    required this.leaderboard,
    this.myTopCreatedCommunity,
    required this.myCreatedCommunities,
  });

  factory CommunityData.fromMap(Map<String, dynamic> map) {
    return CommunityData(
      leaderboard: List<CommunityLeaderboard>.from(
        (map['leaderboard'] ?? []).map((x) => CommunityLeaderboard.fromMap(x)),
      ),
      myTopCreatedCommunity:
          map['myTopCreatedCommunity'] != null
              ? MyTopCreatedCommunity.fromMap(map['myTopCreatedCommunity'])
              : null,
      myCreatedCommunities: List<MyTopCreatedCommunity>.from(
        (map['myCreatedCommunities'] ?? []).map(
          (x) => MyTopCreatedCommunity.fromMap(x),
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'leaderboard': leaderboard.map((x) => x.toMap()).toList(),
      'myTopCreatedCommunity': myTopCreatedCommunity?.toMap(),
      'myCreatedCommunities':
          myCreatedCommunities.map((x) => x.toMap()).toList(),
    };
  }
}
