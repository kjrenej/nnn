import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';

/// Helpers for uploading/deleting files in Supabase Storage.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  SupabaseClient get _client => Supabase.instance.client;
  static const _uuid = Uuid();

  /// Uploads a single file and returns its public URL.
  Future<String> uploadFile({
    required String bucketName,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final ext = fileName.split('.').last;
    final path = '${_uuid.v4()}.$ext';
    final mime = lookupMimeType(fileName) ?? 'application/octet-stream';

    await _client.storage
        .from(bucketName)
        .uploadBinary(
          path,
          fileBytes,
          fileOptions: FileOptions(contentType: mime),
        );

    return _client.storage.from(bucketName).getPublicUrl(path);
  }

  /// Uploads multiple files and returns their public URLs.
  Future<List<String>> uploadFiles({
    required String bucketName,
    required List<MapEntry<String, Uint8List>> files,
  }) async {
    final urls = <String>[];
    for (final entry in files) {
      final url = await uploadFile(
        bucketName: bucketName,
        fileBytes: entry.value,
        fileName: entry.key,
      );
      urls.add(url);
    }
    return urls;
  }

  /// Deletes a file given its full public URL.
  Future<void> deleteFileFromUrl(String publicUrl, String bucketName) async {
    final uri = Uri.parse(publicUrl);
    // Path after /storage/v1/object/public/<bucket>/
    final segments = uri.pathSegments;
    final bucketIndex = segments.indexOf(bucketName);
    if (bucketIndex == -1) return;
    final filePath = segments.sublist(bucketIndex + 1).join('/');
    await _client.storage.from(bucketName).remove([filePath]);
  }
}
