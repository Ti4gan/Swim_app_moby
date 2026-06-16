import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../data/swimflow_repository.dart';
import '../router/stitch_router.dart';
import '../services/push_notification_service.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService(FirebaseMessaging.instance);
  ref.onDispose(() => unawaited(service.unbind()));
  return service;
});

final pushNotificationsBindingProvider = Provider<void>((ref) {
  Future<void> sync(User? user) async {
    print('[PUSH] sync() called, user=${user?.uid ?? 'null'}');
    final service = ref.read(pushNotificationServiceProvider);
    if (user == null) {
      print('[PUSH] user null, unbinding');
      await service.unbind();
      return;
    }
    final repo = SwimflowRepository(FirebaseFirestore.instance, user.uid);
    print('[PUSH] repo created');
    final router = ref.read(stitchRouterProvider);
    print('[PUSH] calling bind()');
    await service.bind(
      repository: repo,
      userId: user.uid,
      onDeepLink: (location) {
        final loc = router.state.matchedLocation;
        if (loc == '/login' || loc == '/register' || loc == '/session-loading') return;
        router.push(location);
      },
    );
    print('[PUSH] bind() completed');
  }

  ref.listen(
    authStateProvider,
    (previous, next) {
      print('[PUSH] authState changed: prev=${previous?.valueOrNull?.uid ?? 'null'}, next=${next.valueOrNull?.uid ?? 'null'}');
      unawaited(sync(next.valueOrNull));
    },
    fireImmediately: true,
  );
});
