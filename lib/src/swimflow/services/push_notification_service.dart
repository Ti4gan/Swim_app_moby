import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../data/swimflow_repository.dart';

typedef NotificationDeepLinkHandler = void Function(String location);

class PushNotificationService {
  PushNotificationService(this._messaging);

  final FirebaseMessaging _messaging;
  StreamSubscription<String>? _tokenRefreshSub;
  SwimflowRepository? _repository;
  NotificationDeepLinkHandler? _onDeepLink;

  Future<void> bind({
    required SwimflowRepository repository,
    NotificationDeepLinkHandler? onDeepLink,
  }) async {
    _repository = repository;
    _onDeepLink = onDeepLink;

    await _messaging.setAutoInitEnabled(true);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    await _persistToken();
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen(_saveToken);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleOpenedMessage(initial);
    }
  }

  Future<void> unbind() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _repository = null;
    _onDeepLink = null;
  }

  Future<void> _persistToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveToken(token);
      }
    } catch (e, st) {
      debugPrint('FCM getToken failed: $e\n$st');
    }
  }

  Future<void> _saveToken(String token) async {
    final repo = _repository;
    if (repo == null) return;
    try {
      await repo.saveFcmToken(token);
    } catch (e, st) {
      debugPrint('FCM saveToken failed: $e\n$st');
    }
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final workoutId = message.data['workoutId'];
    if (workoutId == null || workoutId.isEmpty) return;
    _onDeepLink?.call('/workout/$workoutId');
  }
}
