

class GroupItem {
  final String groupName;
  final String groupIcon;
  final List<PersonStat> stats;

  GroupItem({
    required this.groupName,
    required this.groupIcon,
    required this.stats,
  });
}

class PersonStat {
  final String personImage;
  final int count;

  PersonStat({
    required this.personImage,
    required this.count,
  });
}