import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/demo_seed_service.dart';
import 'auth_providers.dart';
import 'firebase_providers.dart';

final demoSeedServiceProvider = Provider<DemoSeedService>((ref) {
  return DemoSeedService(ref.watch(firestoreProvider));
});

final demoSeedControllerProvider = Provider<DemoSeedController>((ref) {
  return DemoSeedController(ref.watch(demoSeedServiceProvider));
});

class DemoSeedController {
  DemoSeedController(this._service);

  final DemoSeedService _service;

  Future<String> seedCoachDemo(WidgetRef ref) async {
    final user = ref.read(authSessionProvider).valueOrNull;
    if (user == null) {
      throw Exception('Нет сессии');
    }
    return _service.seedForCoach(coachId: user.id);
  }
}
