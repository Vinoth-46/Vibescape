import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_filex/open_filex.dart';

/// Model for a GitHub release
class AppRelease {
  final String version;
  final String tagName;
  final String? body; // Release notes
  final String? apkDownloadUrl;
  final String? apkFileName;
  final int? apkSize;
  final DateTime publishedAt;

  AppRelease({
    required this.version,
    required this.tagName,
    this.body,
    this.apkDownloadUrl,
    this.apkFileName,
    this.apkSize,
    required this.publishedAt,
  });
}

/// Service for checking and downloading app updates from GitHub Releases.
///
/// To set up:
/// 1. Create a GitHub repository for your app
/// 2. Set [githubOwner] and [githubRepo] below
/// 3. Create releases with APK files attached as assets
/// 4. Tag releases with semantic versions (e.g., v1.0.1, v2.0.0)
class AppUpdateService {
  // ⚡ Configure these with your GitHub repository details
  static const String githubOwner = 'Vinoth-46'; // Your GitHub username
  static const String githubRepo = 'Vibescape'; // Your repo name

  static String get _apiUrl =>
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  /// Check for updates by comparing current version with latest GitHub release
  static Future<AppRelease?> checkForUpdate() async {
    try {
      debugPrint('AppUpdateService: Checking for updates...');

      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        debugPrint('AppUpdateService: No releases found');
        return null;
      }

      if (response.statusCode != 200) {
        debugPrint('AppUpdateService: API error ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final releaseVersion = tagName.replaceAll(RegExp(r'^v'), '');
      final body = data['body'] as String?;
      final publishedAt = DateTime.parse(data['published_at'] as String);

      // Find APK asset
      String? apkUrl;
      String? apkFileName;
      int? apkSize;

      final assets = data['assets'] as List<dynamic>? ?? [];
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          apkFileName = name;
          apkSize = asset['size'] as int?;
          break;
        }
      }

      final release = AppRelease(
        version: releaseVersion,
        tagName: tagName,
        body: body,
        apkDownloadUrl: apkUrl,
        apkFileName: apkFileName,
        apkSize: apkSize,
        publishedAt: publishedAt,
      );

      // Compare versions
      final currentVersion = await _getCurrentVersion();
      if (_isNewerVersion(releaseVersion, currentVersion)) {
        debugPrint('AppUpdateService: Update available! $currentVersion → $releaseVersion');
        return release;
      }

      debugPrint('AppUpdateService: App is up to date ($currentVersion)');
      return null;
    } catch (e) {
      debugPrint('AppUpdateService: Error checking for updates: $e');
      return null;
    }
  }

  /// Download APK to temp directory with progress callback
  static Future<String?> downloadUpdate(
    String downloadUrl, {
    Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('AppUpdateService: Downloading update from $downloadUrl');

      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        debugPrint('AppUpdateService: Download failed with ${response.statusCode}');
        return null;
      }

      final contentLength = response.contentLength ?? 0;
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      }
      dir ??= await getTemporaryDirectory();
      
      final filePath = '${dir.path}/app_update.apk';
      final file = File(filePath);
      final sink = file.openWrite();

      var downloaded = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (onProgress != null && contentLength > 0) {
          onProgress(downloaded / contentLength);
        }
      }

      await sink.flush();
      await sink.close();

      debugPrint('AppUpdateService: Downloaded ${(downloaded / 1024 / 1024).toStringAsFixed(1)} MB to $filePath');
      return filePath;
    } catch (e) {
      debugPrint('AppUpdateService: Download error: $e');
      return null;
    }
  }

  /// Install APK using Android's package installer via open_filex
  static Future<bool> installApk(String filePath) async {
    try {
      debugPrint('AppUpdateService: Opening APK for install: $filePath');
      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );
      debugPrint('AppUpdateService: Install result: ${result.type} - ${result.message}');
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('AppUpdateService: Install error: $e');
      return false;
    }
  }

  /// Get current app version from pubspec
  static Future<String> _getCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final buildNum = info.buildNumber;
      if (buildNum.isNotEmpty) {
        return '${info.version}+$buildNum';
      }
      return info.version;
    } catch (e) {
      debugPrint('AppUpdateService: Error getting version: $e');
      return '1.0.0';
    }
  }

  /// Get current app version (public API)
  static Future<String> getCurrentVersion() async {
    return _getCurrentVersion();
  }

  /// Compare semantic versions: returns true if remote > current
  static bool _isNewerVersion(String remote, String current) {
    try {
      final remoteBase = remote.split('+')[0];
      final currentBase = current.split('+')[0];

      final remoteParts = remoteBase.split('.').map(int.parse).toList();
      final currentParts = currentBase.split('.').map(int.parse).toList();

      // Pad to 3 parts
      while (remoteParts.length < 3) remoteParts.add(0);
      while (currentParts.length < 3) currentParts.add(0);

      for (var i = 0; i < 3; i++) {
        if (remoteParts[i] > currentParts[i]) return true;
        if (remoteParts[i] < currentParts[i]) return false;
      }
      
      // Compare build numbers if semver matches perfectly
      int remoteBuild = 0;
      if (remote.contains('+')) {
         remoteBuild = int.tryParse(remote.split('+')[1]) ?? 0;
      }
      int currentBuild = 0;
      if (current.contains('+')) {
         currentBuild = int.tryParse(current.split('+')[1]) ?? 0;
      }
      
      return remoteBuild > currentBuild;
    } catch (e) {
      debugPrint('AppUpdateService: Version comparison error: $e');
      return false;
    }
  }

  /// Format bytes to human-readable string
  static String formatSize(int? bytes) {
    if (bytes == null || bytes == 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  /// Global generic dialog that can be called from anywhere
  static void showUpdateDialog(BuildContext context, AppRelease release) {
    bool downloading = false;
    double downloadProgress = 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1C2E)
                : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF007AFF), Color(0xFF00D4FF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.system_update_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text("Update Available",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "v${release.version}",
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF007AFF)),
                ),
                if (release.apkSize != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      AppUpdateService.formatSize(release.apkSize),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 12),
                if (release.body != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Text(
                        release.body!,
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ),
                  ),
                if (downloading) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: downloadProgress,
                      backgroundColor: const Color(0xFF007AFF).withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF007AFF)),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(downloadProgress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (!downloading) {
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("Later", style: TextStyle(color: Colors.grey)),
              ),
              if (release.apkDownloadUrl != null && !downloading)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    setDialogState(() => downloading = true);
                    final filePath = await AppUpdateService.downloadUpdate(
                      release.apkDownloadUrl!,
                      onProgress: (p) {
                        setDialogState(() => downloadProgress = p);
                      },
                    );
                    setDialogState(() => downloading = false);
                    if (filePath != null && context.mounted) {
                      Navigator.pop(ctx);
                      await AppUpdateService.installApk(filePath);
                    }
                  },
                  child: const Text("Download & Install", style: TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
          );
        },
      ),
    );
  }
}
