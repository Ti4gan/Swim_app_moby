import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/swimflow_repository.dart';

typedef NotificationDeepLinkHandler = void Function(String location);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

Future<void> initLocalNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  await _localNotifications.initialize(
    const InitializationSettings(android: androidSettings, iOS: iosSettings),
  );
  const channel = AndroidNotificationChannel(
    'coach_workouts',
    'Тренировки тренера',
    description: 'Уведомления о тренировках и целях от тренера',
    importance: Importance.high,
  );
  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[FCM Bg] background message: type=${message.data['type']}');
}

class PushNotificationService {
  PushNotificationService(this._messaging);

  final FirebaseMessaging _messaging;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  SwimflowRepository? _repository;
  NotificationDeepLinkHandler? _onDeepLink;
  String? _previousUserId;

  Future<void> bind({
    required SwimflowRepository repository,
    required String userId,
    NotificationDeepLinkHandler? onDeepLink,
  }) async {
    print('[FCM] bind() called userId=$userId');
    _repository = repository;
    _onDeepLink = onDeepLink;

    if (_previousUserId != null && _previousUserId != userId) {
      try {
        await FirebaseFunctions.instance
            .httpsCallable('clearFcmToken')
            .call({'userId': _previousUserId});
        print('[FCM] cleared token for previous user $_previousUserId');
      } catch (e, st) {
        print('[FCM] failed to clear previous user token: $e');
      }
    }
    _previousUserId = userId;

    await _messaging.setAutoInitEnabled(true);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('[FCM] permission status: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    try {
      await initLocalNotifications();
      print('[FCM] local notifications initialised');
    } catch (e, st) {
      print('[FCM] initLocalNotifications failed: $e');
    }

    await _persistToken(repository);
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen(_saveToken);

    _onMessageSub = FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      print('[FCM] tapped notification while app was closed');
      _handleOpenedMessage(initial);
    }
    print('[FCM] bind() done');
  }

  Future<void> unbind() async {
    print('[FCM] unbind() called');
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    await _onMessageSub?.cancel();
    _onMessageSub = null;
    _repository = null;
    _onDeepLink = null;
  }

  Future<void> _persistToken([SwimflowRepository? repo]) async {
    try {
      final token = await _messaging.getToken();
      print('[FCM] getToken() returned: ${token != null ? token.length.toString() + " chars" : "null"}');
      if (token != null && token.isNotEmpty) {
        await _saveToken(token, repo);
      }
    } catch (e, st) {
      print('[FCM] getToken() threw: $e');
    }
  }

  Future<void> _saveToken(String token, [SwimflowRepository? repo]) async {
    repo ??= _repository;
    if (repo == null) {
      print('[FCM] _saveToken: repo is null');
      return;
    }
    try {
      await repo.saveFcmToken(token);
      print('[FCM] token saved to Firestore');
    } catch (e, st) {
      print('[FCM] saveToken failed: $e');
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    print('[FCM] foreground message: type=${message.data['type']}');
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'coach_workouts',
          'Тренировки тренера',
          channelDescription: 'Уведомления о тренировках и целях от тренера',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final workoutId = message.data['workoutId'];
    if (workoutId == null || workoutId.isEmpty) return;
    _onDeepLink?.call('/workout/$workoutId');
  }
}
