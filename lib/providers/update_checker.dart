import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../app_info.dart';

const String _owner = 'warning18';
const String _repo = 'NarrativeApp';
const String _releasesApiUrl = 'https://api.github.com/repos/$_owner/$_repo/releases/latest';

Map<String, String> _authHeaders(String? githubToken, {String accept = 'application/vnd.github+json'}) {
  return {
    'Accept': accept,
    if (githubToken != null && githubToken.isNotEmpty) 'Authorization': 'Bearer $githubToken',
  };
}

class UpdateInfo {
  const UpdateInfo({required this.version, required this.downloadUrl, required this.assetId});

  final String version;

  /// Only usable directly for a public repo; a private repo's release
  /// assets need the authenticated API download in [downloadApk] instead.
  final String downloadUrl;

  /// The release asset's id, used to download it through GitHub's API
  /// (required for a private repo — see [downloadApk]).
  final int assetId;
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

/// Queries the repository's latest GitHub Release. Returns null only when
/// the current app is genuinely already up to date, or the release has no
/// APK asset. Throws if the request itself fails or the API responds with
/// anything other than 200 (e.g. rate limiting), so the caller can tell a
/// real check failure apart from "no update available".
///
/// [githubToken] is required for this to work at all against a private
/// repo (this one is) — without it, GitHub's API returns a 404 for an
/// anonymous request exactly as if the repo didn't exist, which otherwise
/// just looks like a generic "couldn't check for updates" failure.
Future<UpdateInfo?> checkForUpdate({String? githubToken}) async {
  final response = await http
      .get(Uri.parse(_releasesApiUrl), headers: _authHeaders(githubToken))
      .timeout(const Duration(seconds: 15));
  if (response.statusCode != 200) {
    throw Exception('Update check failed with status ${response.statusCode}');
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final tagName = json['tag_name']?.toString() ?? '';
  if (tagName.isEmpty || !isNewerVersion(tagName, AppInfo.version)) return null;

  final assets = (json['assets'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  final apkAsset = assets.where((a) => (a['name']?.toString() ?? '').endsWith('.apk'));
  if (apkAsset.isEmpty) return null;

  final downloadUrl = apkAsset.first['browser_download_url']?.toString();
  final assetId = (apkAsset.first['id'] as num?)?.toInt();
  if (downloadUrl == null || downloadUrl.isEmpty || assetId == null) return null;

  return UpdateInfo(
    version: tagName.startsWith('v') ? tagName.substring(1) : tagName,
    downloadUrl: downloadUrl,
    assetId: assetId,
  );
}

/// Downloads a release asset into the app's temp directory, reporting
/// 0.0-1.0 progress via [onProgress] when the response declares its length.
///
/// Goes through GitHub's authenticated asset-download API (rather than
/// hitting [UpdateInfo.downloadUrl] directly) whenever [githubToken] is
/// available, since that's the only reliable way to fetch a release asset
/// from a private repo — the plain browser_download_url just redirects to
/// a GitHub sign-in page for an unauthenticated request.
Future<String> downloadApk(
  UpdateInfo info, {
  String? githubToken,
  void Function(double)? onProgress,
}) async {
  final uri = githubToken != null && githubToken.isNotEmpty
      ? Uri.parse('https://api.github.com/repos/$_owner/$_repo/releases/assets/${info.assetId}')
      : Uri.parse(info.downloadUrl);
  final request = http.Request('GET', uri)
    ..headers.addAll(_authHeaders(githubToken, accept: 'application/octet-stream'));
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

/// Hands the downloaded APK to the system installer. Returns true if the
/// installer intent was actually launched; false (with [errorMessage] set
/// when available) for anything else — most commonly the user not having
/// granted this app "install unknown apps" yet, which OpenFilex reports as
/// a result rather than throwing, so a caller that only wraps this in
/// try/catch would otherwise treat a failed install as a silent no-op.
Future<InstallResult> installApk(String filePath) async {
  final result = await OpenFilex.open(filePath);
  return InstallResult(
    launched: result.type == ResultType.done,
    errorMessage: result.type == ResultType.done ? null : result.message,
  );
}

class InstallResult {
  const InstallResult({required this.launched, this.errorMessage});

  final bool launched;
  final String? errorMessage;
}
