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

  static final _candidateBranches = ['main', 'master'];

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
  }) async {
    _validateRepoId(repoId);
    final parts = repoId.split('/');
    final owner = parts[0];
    final repo = parts[1];

    final zipsDir = await AppDirectories.zipsDirectory();
    final filename = '${owner}_${repo}.zip';
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

    for (final b in _candidateBranches) {
      try {
        return await _attemptDownload(b);
      } on RZVLog catch (e) {
        if (e.message.contains('404')) continue;
        try {
          return await _attemptDownload(b);
        } catch (_) {}
      }
    }

    // Fallback: try to get default branch via GitLab API
    try {
      final apiUrl = Uri.parse('https://gitlab.com/api/v4/projects/${Uri.encodeComponent('$owner/$repo')}');
      final client = HttpClient();
      final req = await client.getUrl(apiUrl);
      final resp = await req.close();
      if (resp.statusCode == 200) {
        final body = await resp.transform(const Utf8Decoder()).join();
        final match = RegExp('"default_branch"\s*:\s*"([^"]+)"').firstMatch(body);
        final defaultBranch = match?.group(1);
        if (defaultBranch != null && defaultBranch.isNotEmpty) {
          return await _attemptDownload(defaultBranch);
        }
      } else if (resp.statusCode == 404) {
        throw RZVLog.warning('Gitlab - Repository not found');
      }
      throw RZVLog.warning('Gitlab - Failed to determine default branch');
    } catch (e) {
      throw RZVLog.warning('Gitlab - Download failed: $e');
    }
  }
}
