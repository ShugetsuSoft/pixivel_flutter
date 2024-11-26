class IllustStatistics {
  final int bookmarks;
  final int likes;
  final int comments;
  final int views;

  IllustStatistics({
    required this.bookmarks,
    required this.likes,
    required this.comments,
    required this.views,
  });

  factory IllustStatistics.fromJson(Map<String, dynamic> json) {
    return IllustStatistics(
      bookmarks: json['bookmarks'] as int,
      likes: json['likes'] as int,
      comments: json['comments'] as int,
      views: json['views'] as int,
    );
  }
}
