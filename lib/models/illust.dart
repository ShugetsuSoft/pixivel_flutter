import 'illust_tag.dart';
import 'illust_statistics.dart';

class Illust {
  final int id;
  final String title;
  final String altTitle;
  final String description;
  final int type;
  final String createDate;
  final String uploadDate;
  final int sanity;
  final int width;
  final int height;
  final int pageCount;
  final List<IllustTag> tags;
  final IllustStatistics statistic;
  final int user;
  final String image;
  final int aiType;

  Illust({
    required this.id,
    required this.title,
    required this.altTitle,
    required this.description,
    required this.type,
    required this.createDate,
    required this.uploadDate,
    required this.sanity,
    required this.width,
    required this.height,
    required this.pageCount,
    required this.tags,
    required this.statistic,
    required this.user,
    required this.image,
    required this.aiType,
  });

  factory Illust.fromJson(Map<String, dynamic> json) {
    return Illust(
      id: json['id'] as int,
      title: json['title'] as String,
      altTitle: json['altTitle'] as String,
      description: json['description'] as String,
      type: json['type'] as int,
      createDate: json['createDate'] as String,
      uploadDate: json['uploadDate'] as String,
      sanity: json['sanity'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
      pageCount: json['pageCount'] as int,
      tags: (json['tags'] as List<dynamic>)
          .map((e) => IllustTag.fromJson(e as Map<String, dynamic>))
          .toList(),
      statistic: IllustStatistics.fromJson(json['statistic'] as Map<String, dynamic>),
      user: json['user'] as int,
      image: json['image'] as String,
      aiType: json['aiType'] as int,
    );
  }
}
