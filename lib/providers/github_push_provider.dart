import 'dart:convert';

import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../gamedata/db_schema.dart';
import '../gamedata/game_config_schema.dart';

const String _githubTokenPrefsKey = 'github_pat';
const String _owner = 'warning18';
const String _repo = 'NarrativeApp';
const String _baseBranch = 'main';
const String _storyOverridePrefsKey = 'story_nodes_override';
const String _storyAssetPath = 'assets/Cleaned_Narrative_DAG.json';

/// Stores the user's GitHub Personal Access Token — same pattern and trust
/// level as [ApiKeyNotifier] for the Gemini key: local device storage only.
class GithubTokenNotifier extends StateNotifier<String?> {
  GithubTokenNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_githubTokenPrefsKey);
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_githubTokenPrefsKey, token);
    state = token;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_githubTokenPrefsKey);
    state = null;
  }
}

final githubTokenProvider = StateNotifierProvider<GithubTokenNotifier, String?>(
    (ref) => GithubTokenNotifier());

/// One repo file to create/update, with its final pretty-printed content.
class GitFileChange {
  const GitFileChange({required this.path, required this.content});

  final String path;
  final String content;
}

class GitPushResult {
  const GitPushResult({required this.branchName, required this.compareUrl});

  final String branchName;
  final String compareUrl;
}

const JsonEncoder _prettyJson = JsonEncoder.withIndent('  ');

/// Scans every editable game-data source (the Data tab's schemas, New Game
/// Defaults, and the story graph) for a local SharedPreferences override —
/// the app's existing signal that a record was edited on-device and hasn't
/// been reset to the bundled default — and returns each one as a file ready
/// to push. Sources with no override are left out entirely.
Future<List<GitFileChange>> collectLocalDataEdits() async {
  final prefs = await SharedPreferences.getInstance();
  final changes = <GitFileChange>[];

  for (final schema in gameDbSchemas) {
    final raw = prefs.getString('gamedb_${schema.id}');
    if (raw == null) continue;
    final decoded = json.decode(raw);
    changes.add(GitFileChange(
        path: schema.assetPath, content: _prettyJson.convert(decoded)));
  }

  final configRaw = prefs.getString(gameConfigPrefsKey);
  if (configRaw != null) {
    changes.add(
      GitFileChange(
          path: gameConfigAssetPath,
          content: _prettyJson.convert(json.decode(configRaw))),
    );
  }

  final storyRaw = prefs.getString(_storyOverridePrefsKey);
  if (storyRaw != null) {
    changes.add(
      GitFileChange(
          path: _storyAssetPath,
          content: _prettyJson.convert(json.decode(storyRaw))),
    );
  }

  return changes;
}

Map<String, String> _headers(String token) => {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github+json',
    };

/// Pushes [changes] to a new branch [branchName] created off [_baseBranch],
/// one commit per file via the Contents API. Throws a descriptive
/// [Exception] on the first failure (bad token, branch name taken, no
/// write access, etc.) — the caller shows it directly to the user.
Future<GitPushResult> pushEditsToGitHub({
  required String token,
  required String branchName,
  required List<GitFileChange> changes,
}) async {
  if (changes.isEmpty) {
    throw Exception('No local edits to push.');
  }

  final baseRefResponse = await http.get(
    Uri.parse(
        'https://api.github.com/repos/$_owner/$_repo/git/ref/heads/$_baseBranch'),
    headers: _headers(token),
  );
  if (baseRefResponse.statusCode != 200) {
    throw Exception(
      'Could not read the base branch (status ${baseRefResponse.statusCode}). '
      'Check that your token is valid and has access to this repository.',
    );
  }
  final baseSha = (json.decode(baseRefResponse.body)
      as Map<String, dynamic>)['object']['sha'] as String;

  final createRefResponse = await http.post(
    Uri.parse('https://api.github.com/repos/$_owner/$_repo/git/refs'),
    headers: _headers(token),
    body: json.encode({'ref': 'refs/heads/$branchName', 'sha': baseSha}),
  );
  if (createRefResponse.statusCode == 422) {
    throw Exception(
        'A branch named "$branchName" already exists. Choose a different name.');
  }
  if (createRefResponse.statusCode != 201) {
    throw Exception(
        'Could not create branch "$branchName" (status ${createRefResponse.statusCode}).');
  }

  for (final change in changes) {
    String? existingSha;
    final existingResponse = await http.get(
      Uri.parse(
        'https://api.github.com/repos/$_owner/$_repo/contents/${change.path}?ref=$branchName',
      ),
      headers: _headers(token),
    );
    if (existingResponse.statusCode == 200) {
      existingSha = (json.decode(existingResponse.body)
          as Map<String, dynamic>)['sha'] as String?;
    }

    final putResponse = await http.put(
      Uri.parse(
          'https://api.github.com/repos/$_owner/$_repo/contents/${change.path}'),
      headers: _headers(token),
      body: json.encode({
        'message': 'Update ${change.path} from in-app editor',
        'content': base64Encode(utf8.encode(change.content)),
        'branch': branchName,
        if (existingSha != null) 'sha': existingSha,
      }),
    );
    if (putResponse.statusCode != 200 && putResponse.statusCode != 201) {
      throw Exception(
        'Failed to push ${change.path} (status ${putResponse.statusCode}). '
        'Branch "$branchName" was created, with any earlier files in this batch already pushed to it.',
      );
    }
  }

  return GitPushResult(
    branchName: branchName,
    compareUrl:
        'https://github.com/$_owner/$_repo/compare/$_baseBranch...$branchName?expand=1',
  );
}

/// One recording to add to the repository at [path] (see
/// `bundledNarrationPath`).
class GitBinaryFile {
  const GitBinaryFile({required this.path, required this.read});

  final String path;

  /// The file's bytes, read only when it is pushed.
  final Future<List<int>> Function() read;
}

/// Every path under [prefix] on [_baseBranch], so what the repository
/// already holds is not pushed again.
Future<Set<String>> repositoryPathsUnder(
    {required String token, required String prefix}) async {
  final commitSha = await _baseCommitSha(token);
  final commit = await _getJson(token,
      'https://api.github.com/repos/$_owner/$_repo/git/commits/$commitSha');
  final treeSha = (commit['tree'] as Map<String, dynamic>)['sha'] as String;
  final tree = await _getJson(token,
      'https://api.github.com/repos/$_owner/$_repo/git/trees/$treeSha?recursive=1');
  return {
    for (final entry in (tree['tree'] as List? ?? const []))
      if (entry is Map &&
          entry['type'] == 'blob' &&
          (entry['path'] as String? ?? '').startsWith(prefix))
        entry['path'] as String,
  };
}

/// Pushes [files] to a new branch [branchName] off [_baseBranch] as one
/// commit (Git Data API: a blob per file, one tree, one commit), reporting
/// `(done, total)` as each file is uploaded. Throws a descriptive
/// [Exception] on the first failure; nothing reaches the repository
/// unless every file uploaded.
Future<GitPushResult> pushFilesToGitHub({
  required String token,
  required String branchName,
  required String message,
  required List<GitBinaryFile> files,
  void Function(int done, int total)? onProgress,
}) async {
  if (files.isEmpty) throw Exception('Nothing to push.');
  final baseSha = await _baseCommitSha(token);
  final baseCommit = await _getJson(token,
      'https://api.github.com/repos/$_owner/$_repo/git/commits/$baseSha');
  final baseTree = (baseCommit['tree'] as Map<String, dynamic>)['sha'];

  final entries = <Map<String, String>>[];
  for (var i = 0; i < files.length; i++) {
    final file = files[i];
    final blob = await _postJson(
      token,
      'https://api.github.com/repos/$_owner/$_repo/git/blobs',
      {'content': base64Encode(await file.read()), 'encoding': 'base64'},
      what: 'upload ${file.path}',
    );
    entries.add({
      'path': file.path,
      'mode': '100644',
      'type': 'blob',
      'sha': blob['sha'] as String,
    });
    onProgress?.call(i + 1, files.length);
  }

  final tree = await _postJson(
    token,
    'https://api.github.com/repos/$_owner/$_repo/git/trees',
    {'base_tree': baseTree, 'tree': entries},
    what: 'build the commit',
  );
  final commit = await _postJson(
    token,
    'https://api.github.com/repos/$_owner/$_repo/git/commits',
    {
      'message': message,
      'tree': tree['sha'],
      'parents': [baseSha],
    },
    what: 'create the commit',
  );
  final refResponse = await http.post(
    Uri.parse('https://api.github.com/repos/$_owner/$_repo/git/refs'),
    headers: _headers(token),
    body: json.encode(
        {'ref': 'refs/heads/$branchName', 'sha': commit['sha'] as String}),
  );
  if (refResponse.statusCode == 422) {
    throw Exception(
        'A branch named "$branchName" already exists. Choose a different name.');
  }
  if (refResponse.statusCode != 201) {
    throw Exception(
        'Could not create branch "$branchName" (status ${refResponse.statusCode}).');
  }
  return GitPushResult(
    branchName: branchName,
    compareUrl:
        'https://github.com/$_owner/$_repo/compare/$_baseBranch...$branchName?expand=1',
  );
}

Future<String> _baseCommitSha(String token) async {
  final ref = await _getJson(token,
      'https://api.github.com/repos/$_owner/$_repo/git/ref/heads/$_baseBranch',
      what: 'read the base branch. Check that your token is valid and has '
          'access to this repository');
  return (ref['object'] as Map<String, dynamic>)['sha'] as String;
}

Future<Map<String, dynamic>> _getJson(String token, String url,
    {String? what}) async {
  final response = await http.get(Uri.parse(url), headers: _headers(token));
  if (response.statusCode != 200) {
    throw Exception(
        'Could not ${what ?? 'read the repository'} (status ${response.statusCode}).');
  }
  return json.decode(response.body) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> _postJson(
    String token, String url, Map<String, Object?> body,
    {required String what}) async {
  final response = await http.post(Uri.parse(url),
      headers: _headers(token), body: json.encode(body));
  if (response.statusCode != 201) {
    throw Exception('Could not $what (status ${response.statusCode}).');
  }
  return json.decode(response.body) as Map<String, dynamic>;
}
