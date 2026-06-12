import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'coach_seen_notification_ids';

final seenCoachNotificationIdsProvider =
    AsyncNotifierProvider<SeenCoachNotificationIdsNotifier, Set<String>>(
  SeenCoachNotificationIdsNotifier.new,
);

class SeenCoachNotificationIdsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return Set<String>.from(prefs.getStringList(_prefsKey) ?? const []);
  }

  Future<void> _persist(Set<String> ids) async {
    state = AsyncData(ids);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, ids.toList());
  }

  Future<void> markSeen(String id) async {
    final current = state.valueOrNull ?? await future;
    if (current.contains(id)) return;
    await _persist({...current, id});
  }

  Future<void> markAllSeen(Iterable<String> ids) async {
    final current = state.valueOrNull ?? await future;
    await _persist({...current, ...ids});
  }
}
