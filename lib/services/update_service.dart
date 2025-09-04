import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String changelog;
  final bool isForced;
  final int versionCode;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.changelog,
    required this.isForced,
    required this.versionCode,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
      changelog: json['changelog'] ?? '',
      isForced: json['isForced'] ?? false,
      versionCode: json['versionCode'] ?? 0,
    );
  }
}

class UpdateService {
  static const String _updateApiUrl = 'https://api.pixivel.art/v3/app/update';
  static const String _lastCheckKey = 'last_update_check';
  static const String _skipVersionKey = 'skip_version';
  
  // Check for updates every 24 hours
  static const Duration _checkInterval = Duration(hours: 24);

  Future<UpdateInfo?> checkForUpdates({bool forceCheck = false}) async {
    try {
      // Skip update check for web platform
      if (UniversalPlatform.isWeb) {
        return null;
      }

      // Get current app info
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      // Check if we should skip this check
      if (!forceCheck && !await _shouldCheckForUpdates()) {
        return null;
      }

      // Get platform information
      final platform = _getCurrentPlatform();

      // Make API request with platform information
      final response = await http.get(
        Uri.parse('$_updateApiUrl?platform=$platform'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Pixivel/$currentVersion ($platform)',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (data['status'] == 0 && data['data'] != null) {
          final updateInfo = UpdateInfo.fromJson(data['data']);
          
          // Check if update is available
          if (_isUpdateAvailable(currentBuildNumber, updateInfo.versionCode)) {
            // Save last check time
            await _saveLastCheckTime();
            return updateInfo;
          }
        }
      }

      // Save last check time even if no update
      await _saveLastCheckTime();
      return null;
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return null;
    }
  }

  Future<bool> _shouldCheckForUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    return (now - lastCheck) > _checkInterval.inMilliseconds;
  }

  Future<void> _saveLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
  }

  bool _isUpdateAvailable(int currentBuildNumber, int latestBuildNumber) {
    return latestBuildNumber > currentBuildNumber;
  }

  String _getCurrentPlatform() {
    if (UniversalPlatform.isAndroid) {
      return 'android';
    } else if (UniversalPlatform.isIOS) {
      return 'ios';
    } else if (UniversalPlatform.isWindows) {
      return 'windows';
    } else if (UniversalPlatform.isMacOS) {
      return 'macos';
    } else if (UniversalPlatform.isLinux) {
      return 'linux';
    } else {
      return 'unknown';
    }
  }

  Future<void> skipVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skipVersionKey, version);
  }

  Future<bool> isVersionSkipped(String version) async {
    final prefs = await SharedPreferences.getInstance();
    final skippedVersion = prefs.getString(_skipVersionKey);
    return skippedVersion == version;
  }

  Future<void> clearSkippedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_skipVersionKey);
  }

  Future<void> openDownloadPage(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch update URL');
    }
  }

  // Platform-specific update methods
  Future<void> downloadAndInstallUpdate(String downloadUrl) async {
    // This would implement platform-specific update installation
    // For now, just open the download URL
    await openDownloadPage(downloadUrl);
  }
}