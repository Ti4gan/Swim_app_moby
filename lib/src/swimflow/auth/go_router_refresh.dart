import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_collections.dart';

final routerRefreshListenableProvider = Provider<GoRouterAuthProfileRefresh>((ref) {
  final refresh = GoRouterAuthProfileRefresh();
  ref.onDispose(refresh.dispose);
  return refresh;
});

class GoRouterAuthProfileRefresh extends ChangeNotifier {
  GoRouterAuthProfileRefresh() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuth);
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profSub;
  bool _disposed = false;

  void _onAuth(User? user) {
    _profSub?.cancel();
    _profSub = null;
    if (user != null) {
      final docRef = FirestoreCollections.userRef(FirebaseFirestore.instance, user.uid);
      _profSub = docRef.snapshots().listen((_) => _scheduleNotify());
    }
    _scheduleNotify();
  }

  void notifyRouter() {
    _scheduleNotify();
  }

  void _scheduleNotify() {
    if (_disposed) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _profSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
