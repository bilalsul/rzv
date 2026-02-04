import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../filesystem/app_directories.dart';
import '../state/side_effect_handler.dart';
import '../state/async_status.dart';

typedef DownloadProgress = void Function(int downloadedBytes, int? totalBytes);

class GitHubZipService {
  GitHubZipService._();
  static final instance = GitHubZipService._();

  static final _candidateBranches = ['main', 'master'];

  /// Validate owner/repo input. Reject URLs.
  void _validateRepoId(String input) {
    if (input.trim().isEmpty) throw InvalidRepoError('Repository cannot be empty');
    if (input.contains('http://') || input.contains('https://') || input.contains('/www.')) {
      throw InvalidRepoError('Only owner/repo form is accepted, not URLs');
    }
    final parts = input.split('/');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      throw InvalidRepoError('Input must be in owner/repo format');
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
          throw NetworkError('Branch $branch not found (404)');
        }
        if (resp.statusCode >= 400) {
          throw NetworkError('HTTP ${resp.statusCode}');
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
          throw NetworkError('Network error: $e');
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

        // Move temp to final
        if (await outFile.exists()) await outFile.delete();
        await tempFile.rename(outFile.path);
        return outFile;
      } on OperationCanceledException {
        if (await tempFile.exists()) await tempFile.delete();
        rethrow;
      } finally {
        try {
          client.close(force: true);
        } catch (_) {}
      }
    }

    // Try known branches
    for (final b in branches) {
      try {
        return await _attemptDownload(b);
      } on NetworkError catch (e) {
        // 404 or branch not found -> continue
        if (e.message.contains('404')) continue;
        // otherwise retry once
        try {
          return await _attemptDownload(b);
        } catch (e) {
          // fallthrough
        }
      }
    }

    // Fallback: query repo metadata to get default branch
    try {
      final apiUrl = Uri.parse('https://api.github.com/repos/$owner/$repo');
      final client = HttpClient();
      final req = await client.getUrl(apiUrl);
      req.headers.set('User-Agent', 'rzv-app');
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
        throw InvalidRepoError('Repository not found');
      }
      throw NetworkError('Failed to determine default branch');
    } catch (e) {
      throw NetworkError('Download failed: $e');
    }
  }
}
