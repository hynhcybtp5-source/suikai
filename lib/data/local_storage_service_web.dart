import 'repositories.dart';

/// Web Admin does not upload media. Existing browser-safe URLs remain usable.
class LocalStorageService implements StorageService {
  @override
  Future<String> persistImage(String sourcePath, String extension) async =>
      sourcePath;
}
