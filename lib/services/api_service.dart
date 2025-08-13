import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/illust.dart';
import '../models/ugoira.dart';
import '../models/api_response.dart';

class ApiService {
  static const String _baseUrl = 'https://api.pixivel.art:443/v3';
  static const String _sanityState = 'Normal';
  
  static const Map<String, String> _commonHeaders = {
    'accept': 'application/json',
    'origin': 'https://pixivel.art',
    'referer': 'https://pixivel.art/',
    'pixivel-sanity': _sanityState,
  };
  
  static const Map<String, String> _extendedHeaders = {
    'accept': 'application/json, text/plain, */*',
    'origin': 'https://pixivel.art',
    'referer': 'https://pixivel.art/',
    'pixivel-sanity': _sanityState,
  };

  static const Map<String, List<String>> convertList = {
    'original': ['img-original/img/', ''],
    'regular': ['img-master/img/', '_master1200'],
    'small': ['c/540x540_70/img-master/img/', '_master1200'],
    'thumb_mini': ['c/128x128/img-master/img/', '_square1200'],
  };

  static const List<String> proxyList = [
    'https://proxy.pixivel.art:443/',
  ];

  static const Map<String, List<String>> rankModes = {
    'all': [
      'daily',
      'weekly',
      'monthly',
      'rookie',
      'original',
      'male',
      'female'
    ],
    'illust': ['daily', 'weekly', 'monthly', 'rookie'],
    'manga': ['daily', 'weekly', 'monthly', 'rookie'],
    'ugoira': ['daily', 'weekly'],
  };

  static const int pageLimit = 30;

  String _loadBalance(int id, {int page = -1}) {
    // Simple load balancing using modulo
    final hash = id % proxyList.length;
    return proxyList[hash];
  }

  String getImageUrl(String image, int id,
      {bool isThumb = false, bool isOriginal = false, int page = 0}) {
    final Y = image.substring(0, 4);
    final M = image.substring(4, 6);
    final D = image.substring(6, 8);
    final h = image.substring(8, 10);
    final m = image.substring(10, 12);
    final s = image.substring(12, 14);

    final reso = isOriginal
        ? 'original'
        : isThumb
            ? 'small'
            : 'regular';
    var url = _loadBalance(id, page: page);
    url += convertList[reso]![0];
    url += '$Y/$M/$D/$h/$m/$s';

    if (page == -1) {
      url += '/$id';
    } else {
      url += '/${id}_p$page';
    }

    url += convertList[reso]![1];
    if (reso != 'original') {
      url += '.jpg';
    }

    return url;
  }

  String getUserImageUrl(String url, int userId) {
    return url.replaceAll("https://i.pximg.net/", _loadBalance(userId));
  }

  Future<BackendResponse<IllustsResponse>> getRankings({
    required String mode,
    required String date,
    String content = 'illust',
    int page = 0,
  }) async {
    if (!rankModes.containsKey(content) ||
        !rankModes[content]!.contains(mode)) {
      return const BackendResponse(status: -1, message: Errors.InvalidRequest);
    }

    // Convert date from yyyy-MM-dd to yyyyMMdd format
    final dateFormatted = date.replaceAll('-', '');
    if (dateFormatted.length != 8) {
      return const BackendResponse(status: -1, message: Errors.InvalidRequest);
    }

    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/rank?mode=$mode&date=$dateFormatted&content=$content&page=$page'),
        headers: _commonHeaders,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        return BackendResponse.fromJson(
          json,
          (data) => IllustsResponse.fromJson(data as Map<String, dynamic>),
        );
      }

      if (response.statusCode == 500) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        return BackendResponse(
          status: response.statusCode,
          message: json['message'] as String? ?? Errors.TryInFewMinutes,
        );
      }

      return BackendResponse(status: response.statusCode);
    } catch (e) {
      debugPrint('Error fetching rankings: $e');
      return BackendResponse(status: -1, message: e.toString());
    }
  }

  Future<BackendResponse<Illust>> getIllustDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/illust/$id'),
        headers: _commonHeaders,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        return BackendResponse.fromJson(
          json,
          (data) => Illust.fromJson(data as Map<String, dynamic>),
        );
      }
      return BackendResponse(status: response.statusCode);
    } catch (e) {
      debugPrint('Error fetching illust detail: $e');
      return BackendResponse(status: -1, message: e.toString());
    }
  }

  Future<BackendResponse<UserIllustsResponse>> getUserIllusts(int userId,
      {int page = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/illustrator/$userId/illusts?page=$page'),
        headers: _extendedHeaders,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        return BackendResponse.fromJson(
          json,
          (data) => UserIllustsResponse.fromJson(data as Map<String, dynamic>),
        );
      }

      if (response.statusCode == 500) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        return BackendResponse(
          status: json['status'] as int,
          message: json['message'] as String?,
        );
      }

      return const BackendResponse(
        status: -1,
        message: Errors.TryInFewMinutes,
      );
    } catch (e) {
      debugPrint('Error fetching user illusts: $e');
      return const BackendResponse(
        status: -1,
        message: Errors.TryInFewMinutes,
      );
    }
  }

  Future<BackendResponse<Ugoira>> getUgoira(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ugoira/$id'),
        headers: _commonHeaders,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        return BackendResponse.fromJson(
          json,
          (data) => Ugoira.fromJson(data as Map<String, dynamic>),
        );
      }
      return BackendResponse(status: response.statusCode);
    } catch (e) {
      debugPrint('Error fetching ugoira: $e');
      return BackendResponse(status: -1, message: e.toString());
    }
  }

  Future<BackendResponse<IllustsResponse>> getRankIllusts(
      String mode, String type, int page) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/rank/$mode/$type?page=$page'),
      headers: {
        'Accept': 'application/json',
        'Referer': 'https://pixivel.art/',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'pixivel-sanity': _sanityState,
      },
    );

    if (response.statusCode == 200) {
      return BackendResponse<IllustsResponse>.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
        (json) => IllustsResponse.fromJson(json as Map<String, dynamic>),
      );
    } else {
      throw Exception('Failed to load rank illusts');
    }
  }

  Future<BackendResponse<IllustsResponse>> getRecommendIllusts(
      int illustId, int page) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/illust/$illustId/recommend?page=$page'),
      headers: {
        'Accept': 'application/json',
        'Referer': 'https://pixivel.art/',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'pixivel-sanity': _sanityState,
      },
    );

    if (response.statusCode == 200) {
      return BackendResponse<IllustsResponse>.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
        (json) => IllustsResponse.fromJson(json as Map<String, dynamic>),
      );
    } else {
      throw Exception('Failed to load recommend illusts');
    }
  }

  Future<BackendResponse<IllustsResponse>> searchIllusts(String query,
      {int page = 0, String sort = 'relevant'}) async {
    final encodedQuery = Uri.encodeComponent(query);
    final response = await http.get(
      Uri.parse('$_baseUrl/search/illust/$encodedQuery?page=$page&sort=$sort'),
      headers: {
        'accept': 'application/json',
        'accept-language': 'zh-CN,zh;q=0.9',
        'referer': 'https://pixivel.art/',
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
      },
    );

    if (response.statusCode == 200) {
      return BackendResponse<IllustsResponse>.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
        (json) => IllustsResponse.fromJson(json as Map<String, dynamic>),
      );
    } else {
      throw Exception('Failed to search illusts');
    }
  }

  Future<BackendResponse<UsersResponse>> searchIllustrators(String query,
      {int page = 0}) async {
    final encodedQuery = Uri.encodeComponent(query);
    final response = await http.get(
      Uri.parse('$_baseUrl/search/illustrator/$encodedQuery?page=$page'),
      headers: {
        'accept': 'application/json',
        'accept-language': 'zh-CN,zh;q=0.9',
        'referer': 'https://pixivel.art/',
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
      },
    );

    if (response.statusCode == 200) {
      return BackendResponse<UsersResponse>.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
        (json) => UsersResponse.fromJson(json as Map<String, dynamic>),
      );
    } else {
      throw Exception('Failed to search illustrators');
    }
  }

  Future<bool> reportContent(String type, String id) async {
    assert(type == 'illust' || type == 'user', 'Type must be either "illust" or "user"');
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/report/$type/$id'),
        headers: {
          'Content-Type': 'application/json',
          'pixivel-sanity': _sanityState,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to report content: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error reporting content: $e');
      rethrow;
    }
  }
}
