import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../app_info.dart';

const String _owner = 'warning18';
const String _repo = 'NarrativeApp';
const String _releasesApiUrl =
    'https://api.github.com/repos/$_owner/$_repo/releases/latest';

Map<String, String> _authHeaders(String? githubToken,
    {String accept = 'application/vnd.github+json'}) {
  return {
    'Accept': accept,
    if (githubToken != null && githubToken.isNotEmpty)
      'Authorization': 'Bearer $githubToken',
  };
}

/// The kind of file a release carries for this device, which the app can
/// download and hand over to install: the APK on Android (the system
/// installer), the IPA on iPhone (the share sheet, to AltStore, SideStore
/// or Files: see docs/INSTALL_IPHONE.md). Null where the app doesn't
/// update itself.
String? get updateFileExtension => switch (defaultTargetPlatform) {
      TargetPlatform.android => '.apk',
      TargetPlatform.iOS => '.ipa',
      _ => null,
    };

/// The first of a release's [assets] (as the GitHub API lists them) whose
/// name ends with [extension], or null.
Map<String, dynamic>? pickUpdateAsset(
    List<Map<String, dynamic>> assets, String extension) {
  for (final asset in assets) {
    final name = asset['name']?.toString().toLowerCase() ?? '';
    if (name.endsWith(extension.toLowerCase())) return asset;
  }
  return null;
}

class UpdateInfo {
  const UpdateInfo(
      {required this.version,
      required this.downloadUrl,
      required this.assetId,
      this.fileName = 'narrative_app_update.apk'});

  final String version;

  /// The release asset's name (its extension says what it is).
  final String fileName;

  /// Only usable directly for a public repo; a private repo's release
  /// assets need the authenticated API download in [downloadUpdate] instead.
  final String downloadUrl;

  /// The release asset's id, used to download it through GitHub's API
  /// (required for a private repo — see [downloadUpdate]).
  final int assetId;
}

/// Compares two dot-separated version strings (ignoring any leading 'v' or
/// build-number suffix after '+'). Returns true if [remote] is newer than
/// [local].
bool isNewerVersion(String remote, String local) {
  List<int> parts(String v) {
    final clean = v.startsWith('v') ? v.substring(1) : v;
    return clean
        .split('+')
        .first
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
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
/// file ending with [fileExtension] (the APK by default; see
/// [updateFileExtension]). Throws if the request itself fails or the API responds with
/// anything other than 200 (e.g. rate limiting), so the caller can tell a
/// real check failure apart from "no update available".
///
/// [githubToken] is required for this to work at all against a private
/// repo (this one is) — without it, GitHub's API returns a 404 for an
/// anonymous request exactly as if the repo didn't exist, which otherwise
/// just looks like a generic "couldn't check for updates" failure.
Future<UpdateInfo?> checkForUpdate(
    {String? githubToken, String fileExtension = '.apk'}) async {
  final response = await http
      .get(Uri.parse(_releasesApiUrl), headers: _authHeaders(githubToken))
      .timeout(const Duration(seconds: 15));
  if (response.statusCode != 200) {
    throw Exception('Update check failed with status ${response.statusCode}');
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final tagName = json['tag_name']?.toString() ?? '';
  if (tagName.isEmpty || !isNewerVersion(tagName, AppInfo.version)) return null;

  final assets =
      (json['assets'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  final asset = pickUpdateAsset(assets, fileExtension);
  if (asset == null) return null;

  final downloadUrl = asset['browser_download_url']?.toString();
  final assetId = (asset['id'] as num?)?.toInt();
  if (downloadUrl == null || downloadUrl.isEmpty || assetId == null) {
    return null;
  }

  return UpdateInfo(
    version: tagName.startsWith('v') ? tagName.substring(1) : tagName,
    downloadUrl: downloadUrl,
    assetId: assetId,
    fileName: asset['name']?.toString() ?? 'narrative_app_update.apk',
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
Future<String> downloadUpdate(
  UpdateInfo info, {
  String? githubToken,
  void Function(double)? onProgress,
}) async {
  final uri = githubToken != null && githubToken.isNotEmpty
      ? Uri.parse(
          'https://api.github.com/repos/$_owner/$_repo/releases/assets/${info.assetId}')
      : Uri.parse(info.downloadUrl);
  final request = http.Request('GET', uri)
    ..headers
        .addAll(_authHeaders(githubToken, accept: 'application/octet-stream'));
  final response = await http.Client().send(request);
  if (response.statusCode != 200) {
    throw Exception('Download failed with status ${response.statusCode}');
  }

  final total = response.contentLength ?? 0;
  var received = 0;
  final dir = await getTemporaryDirectory();
  // Named as the release names it: on iPhone, that name is what the share
  // sheet and Files show.
  final file = File('${dir.path}/${info.fileName}');
  final sink = file.openWrite();

  await response.stream.map((chunk) {
    received += chunk.length;
    if (total > 0) onProgress?.call(received / total);
    return chunk;
  }).pipe(sink);
  await sink.close();

  return file.path;
}

/// Hands the downloaded file over: an APK to the system installer; on
/// iPhone, an IPA to the share sheet, to open in AltStore or SideStore
/// (which sign and install it) or save to Files. Returns true if that was
/// actually launched; false (with [errorMessage] set when available) for
/// anything else — most commonly the user not having granted this app
/// "install unknown apps" yet, which OpenFilex reports as a result rather
/// than throwing, so a caller that only wraps this in try/catch would
/// otherwise treat a failed install as a silent no-op.
Future<InstallResult> installUpdate(String filePath) async {
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
