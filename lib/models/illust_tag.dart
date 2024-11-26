class IllustTag {
  final String name;
  final String translation;

  IllustTag({
    required this.name,
    this.translation = '',
  });

  factory IllustTag.fromJson(Map<String, dynamic> json) {
    return IllustTag(
      name: json['name'] as String,
      translation: json['translation'] as String? ?? '',
    );
  }
}
