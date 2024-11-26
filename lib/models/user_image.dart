class UserImage {
  final String url;
  final String bigUrl;
  final String? background;

  UserImage({
    required this.url,
    required this.bigUrl,
    this.background,
  });

  factory UserImage.fromJson(Map<String, dynamic> json) {
    return UserImage(
      url: json['url'] as String,
      bigUrl: json['bigUrl'] as String,
      background: json['background'] as String?,
    );
  }
}
