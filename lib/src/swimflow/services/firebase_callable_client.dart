import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

class CallableFunctionsException implements Exception {
  CallableFunctionsException({required this.code, this.message});

  final String code;
  final String? message;

  @override
  String toString() => message ?? code;
}

/// HTTP-клиент для Firebase Callable Functions (без cloud_functions-плагина).
class FirebaseCallableClient {
  FirebaseCallableClient({
    FirebaseAuth? auth,
    String? projectId,
    this.region = 'us-central1',
    http.Client? httpClient,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _projectId = projectId ?? Firebase.app().options.projectId,
        _http = httpClient ?? http.Client();

  final FirebaseAuth _auth;
  final String? _projectId;
  final String region;
  final http.Client _http;

  Uri _uri(String name) {
    final pid = _projectId;
    if (pid == null || pid.isEmpty) {
      throw StateError('Firebase projectId missing');
    }
    return Uri.parse('https://$region-$pid.cloudfunctions.net/$name');
  }

  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> data, {
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final user = _auth.currentUser;
    if (user != null) {
      headers['Authorization'] = 'Bearer ${await user.getIdToken()}';
    }

    final resp = await _http
        .post(
          _uri(name),
          headers: headers,
          body: jsonEncode({'data': data}),
        )
        .timeout(timeout);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw CallableFunctionsException(
        code: 'internal',
        message: 'Ошибка сервера (${resp.statusCode})',
      );
    }

    final body = resp.body.trim();
    if (!body.startsWith('{')) {
      throw CallableFunctionsException(
        code: 'internal',
        message: 'Сервер вернул неожиданный ответ',
      );
    }

    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(body) as Map<String, dynamic>;
    } on FormatException {
      throw CallableFunctionsException(
        code: 'internal',
        message: 'Сервер вернул неожиданный ответ',
      );
    }

    final err = decoded['error'];
    if (err is Map<String, dynamic>) {
      final status = (err['status'] as String?)?.toLowerCase().replaceAll('_', '-') ?? 'unknown';
      throw CallableFunctionsException(
        code: status,
        message: err['message'] as String?,
      );
    }

    final result = decoded['result'];
    if (result is Map<String, dynamic>) return result;
    if (result == null) return {};
    return {'value': result};
  }
}
