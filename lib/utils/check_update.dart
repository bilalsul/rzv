import 'package:rzv/providers/shared_preferences_provider.dart';
import 'package:rzv/l10n/generated/L10n.dart';
import 'package:rzv/main.dart';
import 'package:rzv/utils/app_version.dart';
import 'package:rzv/utils/env_var.dart';
import 'package:rzv/utils/get_current_language_code.dart';
import 'package:rzv/utils/log/common.dart';
import 'package:rzv/utils/toast/common.dart';
import 'package:rzv/widgets/markdown/styled_markdown.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> checkUpdate(bool manualCheck) async {
  if (!EnvVar.enableCheckUpdate) {
    return;
  }
  
  // Check if we already showed update today (unless manual check)
  if (!manualCheck &&
      DateTime.now().difference(Prefs().lastShowUpdate) <
          const Duration(days: 1)) {
    return;
  }
  Prefs().lastShowUpdate = DateTime.now();

  BuildContext context = navigatorKey.currentContext!;
  Response<String> response;
  try {
    // Fetch the changelog from GitHub raw URL
    response = await Dio().get<String>(
      'https://raw.githubusercontent.com/bilalsul/rzv/refs/heads/production/assets/changelog.md',
      options: Options(
        headers: {
          'Accept': 'text/markdown',
          'Cache-Control': 'no-cache',
        },
      ),
    );
  } catch (e) {
    if (manualCheck) {
      RZVToast.show(L10n.of(context).commonFailed);
    }
    RZVLog.severe('Update: Failed to fetch changelog: $e');
    return;
  }

  // Parse the changelog to get the latest version
  final changelog = response.data ?? '';
  final versionRegex = RegExp(r'##\s+(\d+\.\d+\.\d+)');
  final match = versionRegex.firstMatch(changelog);
  
  if (match == null) {
    if (manualCheck) {
      RZVToast.show('Failed to parse changelog version');
    }
    RZVLog.severe('Update: No version found in changelog');
    return;
  }

  String newVersion = match.group(1)!;
  String currentVersion = (await getAppVersion()).split('+').first;
  
  RZVLog.info('Update: Latest changelog version $newVersion, Current: $currentVersion');

  // Extract the changelog content for the latest version
  String? latestVersionChangelog;
  try {
    // Find the start of the latest version section
    final startIndex = changelog.indexOf(match.group(0)!);
    if (startIndex != -1) {
      // Find the next version section or end of file
      String remaining = changelog.substring(startIndex);
      final nextVersionMatch = versionRegex.firstMatch(remaining.substring(1));
      
      if (nextVersionMatch != null) {
        // Cut at the next version
        final nextVersionStart = remaining.indexOf(nextVersionMatch.group(0)!, 1);
        latestVersionChangelog = remaining.substring(0, nextVersionStart).trim();
      } else {
        // No next version, take everything to end
        latestVersionChangelog = remaining.trim();
      }
      
      // Remove the version header line (## 0.1.6)
      final lines = latestVersionChangelog.split('\n');
      if (lines.isNotEmpty && lines[0].contains(versionRegex)) {
        lines.removeAt(0);
        latestVersionChangelog = lines.join('\n').trim();
      }
    }
  } catch (e) {
    RZVLog.warning('Update: Failed to extract changelog content: $e');
    latestVersionChangelog = '';
  }

  // Process the changelog content to filter by language (same logic as ChangelogScreen)
  String processedChangelog = _processRemoteChangelogContent(latestVersionChangelog ?? '');

  // Compare versions
  List<String> newVersionList = newVersion.split('.');
  List<String> currentVersionList = currentVersion.split('.');
  
  // Ensure both versions have at least 3 parts (major.minor.patch)
  while (newVersionList.length < 3) newVersionList.add('0');
  while (currentVersionList.length < 3) currentVersionList.add('0');
  
  bool needUpdate = false;
  for (int i = 0; i < 3; i++) {
    int newVer = int.parse(newVersionList[i]);
    int curVer = int.parse(currentVersionList[i]);
    if (newVer > curVer) {
      needUpdate = true;
      break;
    } else if (newVer < curVer) {
      needUpdate = false;
      break;
    }
  }

  if (needUpdate) {
    if (manualCheck) {
      Navigator.of(context).pop();
    }
    SmartDialog.show(
      builder: (BuildContext context) {
        // Check if we have changelog content, otherwise show a default message
        String changelogBody = processedChangelog.isNotEmpty 
            ? processedChangelog 
            : _getDefaultChangelogByLanguage();
        
        return AlertDialog(
          title: Text(L10n.of(context).commonNewVersion,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              )),
          content: SingleChildScrollView(
            child: StyledMarkdown(
              data: '''### ${L10n.of(context).updateNewVersion} $newVersion\n
${L10n.of(context).updateCurrentVersion} $currentVersion\n
$changelogBody''',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                SmartDialog.dismiss();
              },
              child: Text(L10n.of(context).commonCancel),
            ),
            TextButton(
              onPressed: () {
                launchUrl(
                  Uri.parse('https://github.com/bilalsul/rzv/releases/latest'),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: Text(L10n.of(context).updateViaGithub),
            ),
            TextButton(
              onPressed: () {
                launchUrl(
                  Uri.parse('https://play.google.com/store/apps/details?id=com.bilalworku.gzip'),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: Text(L10n.of(context).updateViaPlayStore),
            ),
          ],
        );
      },
    );
  } else {
    if (manualCheck) {
      RZVToast.show(L10n.of(context).commonNoNewVersion);
    }
  }
}

// Helper function to process changelog content and filter by language
String _processRemoteChangelogContent(String content) {
  bool isChinese() => getCurrentLanguageCode().startsWith('zh');

  final lines = content.split('\n');
  var processedLines = <String>[];

  // First pass: collect all bullet points
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) {
      continue;
    }

    if (line.startsWith('- ') || line.startsWith('* ')) {
      processedLines.add(line);
      continue;
    }
  }

  // If we have bullet points, filter by language
  if (processedLines.isNotEmpty) {
    // Split English and Chinese bullet points
    // Assuming English comes first, then Chinese (same as in your assets)
    if (isChinese()) {
      // Take the Chinese bullet points (second half)
      processedLines = processedLines.sublist(processedLines.length ~/ 2);
    } else {
      // Take the English bullet points (first half)
      processedLines = processedLines.sublist(0, processedLines.length ~/ 2);
    }
  }

  return processedLines.join('\n');
}

// Helper function to get default changelog based on language
String _getDefaultChangelogByLanguage() {
  bool isChinese() => getCurrentLanguageCode().startsWith('zh');
  
  if (isChinese()) {
    return '''
- 修复已知问题
- 提升应用稳定性
- 改进用户体验
''';
  } else {
    return '''
- Fixed some bugs
- Improved app stability
- Enhanced user experience
''';
  }
}