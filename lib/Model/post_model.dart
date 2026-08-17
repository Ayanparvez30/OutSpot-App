class PostModel {
  final String id;
  final String userName;
  final String userHandle;
  final String userAvatar;
  final String category; // e.g., "Morning Meals"
  final String postImage;
  final String caption;
  final String timeAgo;
  final int likes;
  final int comments;

  PostModel({
    required this.id,
    required this.userName,
    required this.userHandle,
    required this.userAvatar,
    required this.category,
    required this.postImage,
    required this.caption,
    required this.timeAgo,
    required this.likes,
    required this.comments,
  });
}