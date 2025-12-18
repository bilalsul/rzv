import 'package:git_explorer_mob/providers/shared_preferences_provider.dart';
import 'package:git_explorer_mob/l10n/generated/L10n.dart';
import 'package:git_explorer_mob/main.dart';
import 'package:git_explorer_mob/utils/app_version.dart';
import 'package:git_explorer_mob/utils/env_var.dart';
import 'package:git_explorer_mob/utils/log/common.dart';
import 'package:git_explorer_mob/utils/toast/common.dart';
import 'package:git_explorer_mob/widgets/markdown/styled_markdown.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> checkUpdate(bool manualCheck) async {
  if (!EnvVar.enableCheckUpdate) {
    return;
  }
  // if is today
  if (!manualCheck &&
      DateTime.now().difference(Prefs().lastShowUpdate) <
          const Duration(days: 1)) {
    return;
  }
  Prefs().lastShowUpdate = DateTime.now();

  BuildContext context = navigatorKey.currentContext!;
  Response response;
  try {
    // eg. https://api.gzip.bilalworku.com/api/info/latest
    // https://raw.githubusercontent.com/Anxcye/anx-reader/develop/assets/CHANGELOG.md
    response = await Dio().get('');
  } catch (e) {
    if (manualCheck) {
      GzipToast.show(L10n.of(context).commonFailed);
    }
    GitExpLog.severe('Update: Failed to check for updates $e');
    return;
  }
  String newVersion = response.data['version'].toString().substring(1);
  String currentVersion = (await getAppVersion()).split('+').first;
  GitExpLog.info('Update: new version $newVersion');

  List<String> newVersionList = newVersion.split('.');
  List<String> currentVersionList = currentVersion.split('.');
  GitExpLog.info(
      'Current version: $currentVersionList, New version: $newVersionList');
  bool needUpdate = false;
  for (int i = 0; i < newVersionList.length; i++) {
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
        final body =
            response.data['body'].toString().split('\n').skip(1).join('\n');
        return AlertDialog(
          title: Text(L10n.of(context).commonNewVersion,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              )),
          content: SingleChildScrollView(
            child: StyledMarkdown(
                data: '''### ${L10n.of(context).updateNewVersion} $newVersion\n
${L10n.of(context).updateCurrentVersion} $currentVersion\n
$body'''),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                SmartDialog.dismiss();
              },
              child: Text(L10n.of(context).commonCancel),
            ),
            // TextButton(
            //   onPressed: () {
            //     launchUrl(
            //         Uri.parse(
            //             'https://github.com/uncrr/git-explorer/releases/latest'),
            //         mode: LaunchMode.externalApplication);
            //   },
            //   child: Text(L10n.of(context).updateViaGithub),
            // ),
            TextButton(
              onPressed: () {
                launchUrl(Uri.parse('https:play.google.com/store/apps/details?id=com.bilalworku.gzip'),
                    mode: LaunchMode.externalApplication);
              },
              child: Text(L10n.of(context).updateViaPlayStore),
            ),
          ],
        );
      },
    );
  } else {
    if (manualCheck) {
      GzipToast.show(L10n.of(context).commonNoNewVersion);
    }
  }
}