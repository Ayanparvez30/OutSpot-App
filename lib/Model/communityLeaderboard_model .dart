// class CommunityLeaderboard {
//   final int communityId;
//   final String name;
//   final String imageUrl;
//   final int points;
//   final int membersCount;
//   final int rank;
//   final String prize;

//   CommunityLeaderboard({
//     required this.communityId,
//     required this.name,
//     required this.imageUrl,
//     required this.points,
//     required this.membersCount,
//     required this.rank,
//     required this.prize,
//   });

//   factory CommunityLeaderboard.fromMap(Map<String, dynamic> m) {
//     int _toInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

//     return CommunityLeaderboard(
//       communityId: _toInt(m['communityId']),
//       name: (m['name'] ?? '').toString(),
//       imageUrl: (m['imageUrl'] ?? '').toString(),
//       points: _toInt(m['points']),
//       membersCount: _toInt(m['membersCount']),
//       rank: _toInt(m['rank']),
//       prize: (m['prize'] ?? '').toString(),
//     );
//   }

//   Map<String, dynamic> toMap() => {
//     'communityId': communityId,
//     'name': name,
//     'imageUrl': imageUrl,
//     'points': points,
//     'membersCount': membersCount,
//     'rank': rank,
//     'prize': prize,
//   };

//   @override
//   String toString() {
//     return '[$rank] $name — $points pts, $membersCount members — $prize';
//   }
// }
