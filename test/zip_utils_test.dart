import 'package:flutter_test/flutter_test.dart';
import 'package:rzv/models/zip_entry_model.dart';
import 'package:rzv/services/network/github_zip_service.dart';
import 'package:rzv/services/filesystem/app_directories.dart';
import 'package:rzv/services/state/async_status.dart';

void main() {
  test('repo parsing rejects URLs and invalid input', () async {
    final svc = GitHubZipService.instance;
    expect(() => svc.downloadRepoZip('', token: null as dynamic), throwsA(isA<InvalidRepoError>()));
    expect(() => svc.downloadRepoZip('https://github.com/owner/repo', token: null as dynamic), throwsA(isA<InvalidRepoError>()));
    expect(() => svc.downloadRepoZip('owner', token: null as dynamic), throwsA(isA<InvalidRepoError>()));
  });

  test('extraction folder name derived correctly', () {
    final name = AppDirectories.extractionFolderNameForZip('owner_repo.zip');
    expect(name, 'owner_repo');
  });

  test('zip entry model basic', () {
    final e = ZipEntryModel(filename: 'a.zip', size: 100, modified: DateTime.fromMillisecondsSinceEpoch(0));
    expect(e.filename, 'a.zip');
    expect(e.size, 100);
  });
}
