import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:rzv/utils/log/common.dart';
import '../filesystem/app_directories.dart';
import '../state/side_effect_handler.dart';

typedef DownloadProgress = void Function(int downloadedBytes, int? totalBytes);

class GitLabZipService {
  GitLabZipService._();
  static final instance = GitLabZipService._();

  Future<String> _getDefaultBranch(String owner, String repo) async {
    final apiUrl = Uri.parse('https://gitlab.com/api/v4/projects/${Uri.encodeComponent('$owner/$repo')}');
    final client = HttpClient();
    try {
      final req = await client.getUrl(apiUrl);
      final resp = await req.close();
      if (resp.statusCode == 200) {
        final body = await resp.transform(const Utf8Decoder()).join();
        final match = RegExp(r'"default_branch"\s*:\s*"([^"]+)"').firstMatch(body);
        final defaultBranch = match?.group(1);
        if (defaultBranch != null && defaultBranch.isNotEmpty) {
          return defaultBranch;
        }
      } else if (resp.statusCode == 404) {
        throw RZVLog.warning('Gitlab - Repository not found');
      }
      throw RZVLog.warning('Gitlab - Failed to determine default branch');
    } finally {
      try {
        client.close(force: true);
      } catch (_) {}
    }
  }

  void _validateRepoId(String input) {
    if (input.trim().isEmpty) throw RZVLog.warning('Gitlab - Repository cannot be empty');
    if (input.contains('http://') || input.contains('https://') || input.contains('/www.')) {
      RZVLog.warning('Gitlab - Only owner/repo form is accepted, not URLs');
    }
    final parts = input.split('/');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
       RZVLog.warning('Gitlab - Input must be in owner/repo format');
    }
  }

  Future<File> downloadRepoZip(
    String repoId, {
    required CancellationToken token,
    DownloadProgress? onProgress,
    String? branch,
  }) async {
    _validateRepoId(repoId);
    final parts = repoId.split('/');
    final owner = parts[0];
    final repo = parts[1];

    final branchToUse = branch?.trim().isNotEmpty == true
        ? branch!.trim()
        : await _getDefaultBranch(owner, repo);

    final zipsDir = await AppDirectories.zipsDirectory();
    final filename = '${owner}_${repo}_$branchToUse.zip';
    final tempFile = File(p.join(zipsDir.path, filename + '.part'));
    final outFile = File(p.join(zipsDir.path, filename));

    Future<File> _attemptDownload(String branch) async {
      // GitLab archive URL pattern
      final url = Uri.parse('https://gitlab.com/$owner/$repo/-/archive/$branch/$repo-$branch.zip');
      final client = HttpClient();
      try {
        final req = await client.getUrl(url);
        final resp = await req.close();
        if (resp.statusCode == 404) throw RZVLog.warning('Branch $branch not found (404)');
        if (resp.statusCode >= 400) throw RZVLog.warning('HTTP ${resp.statusCode}');

        final contentLength = resp.contentLength == -1 ? null : resp.contentLength;
        if (await tempFile.exists()) await tempFile.delete();
        final sink = tempFile.openWrite();
        int downloaded = 0;

        final subscription = resp.listen((data) async {
          token.throwIfCanceled();
          downloaded += data.length;
          sink.add(data);
          if (onProgress != null) onProgress(downloaded, contentLength);
        }, onDone: () async {
          await sink.flush();
          await sink.close();
        }, onError: (e) async {
          await sink.close();
          throw RZVLog.warning('Gitlab - Network error: $e');
        }, cancelOnError: true);

        final cancelSub = token.onCancel.listen((_) async {
          await subscription.cancel();
          try {
            client.close(force: true);
          } catch (_) {}
        });

        await subscription.asFuture();
        await cancelSub.cancel();

        if (await outFile.exists()) await outFile.delete();
        await tempFile.rename(outFile.path);
        return outFile;
      } on RZVLog {
        if (await tempFile.exists()) await tempFile.delete();
        rethrow;
      } finally {
        try {
          client.close(force: true);
        } catch (_) {}
      }
    }

    return await _attemptDownload(branchToUse);
  }
}
