import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'repositories.dart';

class LocalStorageService implements StorageService {
  @override
  Future<String> persistImage(String sourcePath, String extension) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/suikai_media');
    await dir.create(recursive: true);
    final target = '${dir.path}/${const Uuid().v4()}.$extension';
    await File(sourcePath).copy(target);
    return target;
  }
}
