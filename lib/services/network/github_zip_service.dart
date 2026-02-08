import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:rzv/utils/log/common.dart';
import '../filesystem/app_directories.dart';
import '../state/side_effect_handler.dart';
// import '../state/async_status.dart';

typedef DownloadProgress = void Function(int downloadedBytes, int? totalBytes);

class GitHubZipService {
  GitHubZipService._();
  static final instance = GitHubZipService._();

  /// Validate owner/repo input. Reject URLs.
  void _validateRepoId(String input) {
    if (input.trim().isEmpty) RZVLog.warning('Github - Repository cannot be empty');
    if (input.contains('http://') || input.contains('https://') || input.contains('/www.')) {
      RZVLog.warning('Github - Only owner/repo form is accepted, not URLs');
    }
    final parts = input.split('/');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      RZVLog.warning('Github - Input must be in owner/repo format');
    }
  }

  Future<String> _getDefaultBranch(String owner, String repo) async {
    final apiUrl = Uri.parse('https://api.github.com/repos/$owner/$repo');
    final client = HttpClient();
    try {
      final req = await client.getUrl(apiUrl);
      req.headers.set('User-Agent', 'rzv');
      final resp = await req.close();
      if (resp.statusCode == 200) {
        final body = await resp.transform(const Utf8Decoder()).join();
        final match = RegExp(r'"default_branch"\s*:\s*"([^"]+)"').firstMatch(body);
        final defaultBranch = match?.group(1);
        if (defaultBranch != null && defaultBranch.isNotEmpty) {
          return defaultBranch;
        }
      } else if (resp.statusCode == 404) {
        throw RZVLog.warning('Github - Repository not found');
      }
      throw RZVLog.warning('Github - Failed to determine default branch');
    } finally {
      try {
        client.close(force: true);
      } catch (_) {}
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

    Future<File> _attemptDownload(String branchName) async {
      final url = Uri.parse('https://github.com/$owner/$repo/archive/refs/heads/$branchName.zip');
      final client = HttpClient();
      try {
        final req = await client.getUrl(url);
        final resp = await req.close();
        if (resp.statusCode == 404) {
          throw RZVLog.warning('Github - Branch $branchName not found (404)');
        }
        if (resp.statusCode >= 400) {
          throw RZVLog.warning('Github - Download HTTP ${resp.statusCode}');
        }

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
          throw RZVLog.warning('Github - Network error: $e');
        }, cancelOnError: true);

        // If token triggers, close client and subscription
        final cancelSub = token.onCancel.listen((_) async {
          await subscription.cancel();
          try {
            client.close(force: true);
          } catch (_) {}
        });

        // Wait until done or cancelled
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
