import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../controllers/auth_controller.dart';
import 'firebase_providers.dart';

final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(ref.watch(authServiceProvider));
});

final authSessionProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).observeSession();
});

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
