import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'firebase_callable_client.dart';

class CoachDocumentStorageService {
  CoachDocumentStorageService({FirebaseCallableClient? callable})
      : _callable = callable ?? FirebaseCallableClient();

  final FirebaseCallableClient _callable;
  static const _maxUploadBytes = 10 * 1024 * 1024;

  static String displayNameForRef(String ref) {
    if (ref.startsWith('gdrive:')) {
      final rest = ref.substring('gdrive:'.length);
      final pipe = rest.indexOf('|');
      if (pipe > 0) return rest.substring(pipe + 1);
      return 'документ';
    }
    if (ref.startsWith('http://') || ref.startsWith('https://')) {
      final uri = Uri.tryParse(ref);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        final last = uri.pathSegments.last;
        if (last.isNotEmpty && last != 'o') return Uri.decodeComponent(last.split('?').first);
      }
      return 'документ';
    }
    final parts = ref.split('/');
    return parts.isNotEmpty ? parts.last : ref;
  }

  static bool isRemoteRef(String ref) =>
      ref.startsWith('http://') ||
      ref.startsWith('https://') ||
      ref.startsWith('coach_documents/') ||
      ref.startsWith('gdrive:');

  Future<List<int>> _readFileBytes(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes != null && bytes.isNotEmpty) return bytes;

    final path = file.path;
    if (path != null && path.isNotEmpty && !kIsWeb) {
      return File(path).readAsBytes();
    }

    throw StateError('file_read_failed');
  }

  String _contentTypeForFileName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'application/octet-stream';
  }

  Future<String> uploadPlatformFile({
    required String uid,
    required PlatformFile file,
  }) async {
    final raw = await _readFileBytes(file);
    if (raw.length > _maxUploadBytes) {
      throw StateError('file_too_large');
    }

    final res = await _callable.call('uploadCoachDocument', {
      'fileName': file.name,
      'contentType': _contentTypeForFileName(file.name),
      'dataBase64': base64Encode(raw),
    });

    final downloadUrl = res['downloadUrl'] as String?;
    if (downloadUrl != null && downloadUrl.isNotEmpty) return downloadUrl;

    final ref = res['ref'] as String?;
    if (ref == null || ref.isEmpty) {
      throw StateError('upload_ref_missing');
    }
    return ref;
  }

  Future<List<String>> uploadPlatformFiles({
    required String uid,
    required List<PlatformFile> files,
  }) async {
    final out = <String>[];
    for (final file in files) {
      out.add(await uploadPlatformFile(uid: uid, file: file));
    }
    return out;
  }

  Future<String?> resolveDownloadUrl(String ref) async {
    if (ref.startsWith('http://') || ref.startsWith('https://')) return ref;
    if (!ref.startsWith('coach_documents/') && !ref.startsWith('gdrive:')) return null;

    final res = await _callable.call('getCoachDocumentDownloadUrls', {
      'refs': [ref],
    });
    final urls = res['urls'];
    if (urls is Map) {
      final url = urls[ref];
      if (url is String && url.isNotEmpty) return url;
    }
    return null;
  }

  String? openUrlForRef(String ref) {
    if (ref.startsWith('http://') || ref.startsWith('https://')) return ref;
    return null;
  }

  String uploadErrorRu(Object error) {
    if (error is CallableFunctionsException) {
      return error.message ?? 'Ошибка загрузки: ${error.code}';
    }
    final text = '$error';
    if (text.contains('file_read_failed')) {
      return 'Не удалось прочитать выбранный файл.';
    }
    if (text.contains('file_too_large')) {
      return 'Файл больше 10 МБ. Выберите файл меньшего размера.';
    }
    if (text.contains('SocketException') || text.contains('Failed host lookup')) {
      return 'Нет подключения к интернету.';
    }
    if (text.contains('FormatException') || text.contains('<html>')) {
      return 'Не удалось получить ссылку на файл. Попробуйте позже.';
    }
    return text;
  }
}
