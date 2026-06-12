import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../router/stitch_router.dart';
import '../services/push_notification_service.dart';
import 'swimflow_providers.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService(FirebaseMessaging.instance);
  ref.onDispose(() => unawaited(service.unbind()));
  return service;
});

final pushNotificationsBindingProvider = Provider<void>((ref) {
  Future<void> sync() async {
    final user = ref.read(authStateProvider).valueOrNull;
    final service = ref.read(pushNotificationServiceProvider);
    if (user == null) {
      await service.unbind();
      return;
    }
    final repo = ref.read(swimflowRepositoryProvider);
    if (repo == null) return;
    final router = ref.read(stitchRouterProvider);
    await service.bind(
      repository: repo,
      onDeepLink: (location) {
        final loc = router.state.matchedLocation;
        if (loc == '/login' || loc == '/register' || loc == '/session-loading') return;
        router.push(location);
      },
    );
  }

  ref.listen(
    authStateProvider,
    (previous, next) => unawaited(sync()),
    fireImmediately: true,
  );
});
