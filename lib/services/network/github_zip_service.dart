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

  static final _candidateBranches = ['main', 'master'];

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

    // Try candidate branches then fallback to API default by requesting /repos/{owner}/{repo}
    final branches = List<String>.from(_candidateBranches);

    // Helper to perform single attempt
    Future<File> _attemptDownload(String branch) async {
      final url = Uri.parse('https://github.com/$owner/$repo/archive/refs/heads/$branch.zip');
      final client = HttpClient();
      try {
        final req = await client.getUrl(url);
        final resp = await req.close();
        if (resp.statusCode == 404) {
          RZVLog.warning('Github - Branch $branch not found (404)');
        }
        if (resp.statusCode >= 400) {
          RZVLog.warning('Github - Download Attempt HTTP ${resp.statusCode}');
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

    for (final b in branches) {
      try {
        return await _attemptDownload(b);
      } on RZVLog catch (e) {
        if (RZVLog.warning('First Attempt to Download ${e.message.contains('404') ? 'Succeeded' : 'Failed'}')) continue;
        try {
          return await _attemptDownload(b);
        } catch (e) {
          RZVLog.warning('Second Attempt to Download Failed with $e');
        }
      }
    }

    // Fallback: query repo metadata to get default branch
    try {
      final apiUrl = Uri.parse('https://api.github.com/repos/$owner/$repo');
      final client = HttpClient();
      final req = await client.getUrl(apiUrl);
      req.headers.set('User-Agent', 'rzv');
      final resp = await req.close();
      if (resp.statusCode == 200) {
        final body = await resp.transform(const Utf8Decoder()).join();
        // crude default branch extraction
        final match = RegExp('"default_branch"\s*:\s*"([^"]+)"').firstMatch(body);
        final defaultBranch = match?.group(1);
        if (defaultBranch != null && defaultBranch.isNotEmpty) {
          return await _attemptDownload(defaultBranch);
        }
      } else if (resp.statusCode == 404) {
        throw RZVLog.warning('Github - Repository not found');
      }
      throw RZVLog.warning('Github - Failed to determine default branch');
    } catch (e) {
      throw RZVLog.warning('Github - Download failed: $e');
    }
  }
}
