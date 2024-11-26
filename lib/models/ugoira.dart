class UgoiraFrame {
  final String file;
  final int delay;

  UgoiraFrame({
    required this.file,
    required this.delay,
  });

  factory UgoiraFrame.fromJson(Map<String, dynamic> json) {
    return UgoiraFrame(
      file: json['file'] as String,
      delay: json['delay'] as int,
    );
  }
}

class Ugoira {
  final int id;
  final String image;
  final String mimeType;
  final List<UgoiraFrame> frames;

  Ugoira({
    required this.id,
    required this.image,
    required this.mimeType,
    required this.frames,
  });

  factory Ugoira.fromJson(Map<String, dynamic> json) {
    return Ugoira(
      id: json['id'] as int,
      image: json['image'] as String,
      mimeType: json['mimeType'] as String,
      frames: (json['frames'] as List<dynamic>)
          .map((e) => UgoiraFrame.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
