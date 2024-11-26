import 'user_image.dart';

class User {
  final int id;
  final String name;
  final String bio;
  final UserImage image;

  User({
    required this.id,
    required this.name,
    required this.bio,
    required this.image,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      bio: json['bio'] as String,
      image: UserImage.fromJson(json['image'] as Map<String, dynamic>),
    );
  }
}
