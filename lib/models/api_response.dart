import 'illust.dart';
import 'user.dart';

class Errors {
  static const String InvalidRequest = 'Invalid request';
  static const String TryInFewMinutes = 'Try again in a few minutes';
  static const String Banned = 'Content is banned';
}

class IllustsResponse {
  final List<Illust> illusts;
  final bool hasNext;

  IllustsResponse({
    required this.illusts,
    required this.hasNext,
  });

  factory IllustsResponse.fromJson(Map<String, dynamic> json) {
    return IllustsResponse(
      illusts: (json['illusts'] as List<dynamic>)
          .map((e) => Illust.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasNext: json['hasNext'] as bool,
    );
  }
}

class UserIllustsResponse {
  final List<Illust> illusts;
  final User user;
  final bool hasNext;

  UserIllustsResponse({
    required this.illusts,
    required this.user,
    required this.hasNext,
  });

  factory UserIllustsResponse.fromJson(Map<String, dynamic> json) {
    return UserIllustsResponse(
      illusts: (json['illusts'] as List<dynamic>)
          .map((e) => Illust.fromJson(e as Map<String, dynamic>))
          .toList(),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      hasNext: json['hasNext'] as bool,
    );
  }
}

class UsersResponse {
  final List<User> users;
  final bool hasNext;

  UsersResponse({
    required this.users,
    required this.hasNext,
  });

  factory UsersResponse.fromJson(Map<String, dynamic> json) {
    return UsersResponse(
      users: (json['users'] as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasNext: json['hasNext'] as bool,
    );
  }
}

class BackendResponse<T> {
  final int status;
  final String? message;
  final T? data;

  const BackendResponse({
    required this.status,
    this.message,
    this.data,
  });

  factory BackendResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson,
  ) {
    return BackendResponse(
      status: json['status'] as int,
      message: json['message'] as String?,
      data: json['data'] != null ? fromJson(json['data']) : null,
    );
  }

  bool get isSuccess => status == 0;
  bool get isBanned => message == Errors.Banned;
  bool get shouldRetry => message == Errors.TryInFewMinutes;
}
