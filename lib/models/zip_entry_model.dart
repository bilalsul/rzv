class ZipEntryModel {
  final String filename;
  final int size;
  final DateTime modified;

  ZipEntryModel({required this.filename, required this.size, required this.modified});
}
