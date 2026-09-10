import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../app_info.dart';

const String _releasesApiUrl =
    'https://api.github.com/repos/warning18/NarrativeApp/releases/latest';

class UpdateInfo {
  const UpdateInfo({required this.version, required this.downloadUrl});

  final String version;
  final String downloadUrl;
}

/// Compares two dot-separated version strings (ignoring any leading 'v' or
/// build-number suffix after '+'). Returns true if [remote] is newer than
/// [local].
bool isNewerVersion(String remote, String local) {
  List<int> parts(String v) {
    final clean = v.startsWith('v') ? v.substring(1) : v;
    return clean.split('+').first.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  }

  final r = parts(remote);
  final l = parts(local);
  for (var i = 0; i < r.length || i < l.length; i++) {
    final rv = i < r.length ? r[i] : 0;
    final lv = i < l.length ? l[i] : 0;
    if (rv != lv) return rv > lv;
  }
  return false;
}

/// Queries the repository's latest GitHub Release. Returns null if the
/// current app is already up to date, the release has no APK asset, or the
/// request fails (treated as "no update available" rather than an error the
/// user needs to see).
Future<UpdateInfo?> checkForUpdate() async {
  final response = await http
      .get(Uri.parse(_releasesApiUrl), headers: {'Accept': 'application/vnd.github+json'})
      .timeout(const Duration(seconds: 15));
  if (response.statusCode != 200) return null;

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final tagName = json['tag_name']?.toString() ?? '';
  if (tagName.isEmpty || !isNewerVersion(tagName, AppInfo.version)) return null;

  final assets = (json['assets'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  final apkAsset = assets.where((a) => (a['name']?.toString() ?? '').endsWith('.apk'));
  if (apkAsset.isEmpty) return null;

  final downloadUrl = apkAsset.first['browser_download_url']?.toString();
  if (downloadUrl == null || downloadUrl.isEmpty) return null;

  return UpdateInfo(
    version: tagName.startsWith('v') ? tagName.substring(1) : tagName,
    downloadUrl: downloadUrl,
  );
}

/// Downloads the APK at [url] into the app's temp directory, reporting
/// 0.0-1.0 progress via [onProgress] when the response declares its length.
Future<String> downloadApk(String url, {void Function(double)? onProgress}) async {
  final request = http.Request('GET', Uri.parse(url));
  final response = await http.Client().send(request);
  if (response.statusCode != 200) {
    throw Exception('Download failed with status ${response.statusCode}');
  }

  final total = response.contentLength ?? 0;
  var received = 0;
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/narrative_app_update.apk');
  final sink = file.openWrite();

  await response.stream.map((chunk) {
    received += chunk.length;
    if (total > 0) onProgress?.call(received / total);
    return chunk;
  }).pipe(sink);
  await sink.close();

  return file.path;
}

/// Hands the downloaded APK to the system installer.
Future<void> installApk(String filePath) async {
  await OpenFilex.open(filePath);
}
