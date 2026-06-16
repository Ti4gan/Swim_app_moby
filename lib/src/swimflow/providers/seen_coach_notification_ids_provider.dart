import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SeenCoachNotificationIdsNotifier extends StateNotifier<Set<String>> {
  SeenCoachNotificationIdsNotifier() : super({});

  static const _key = 'seen_coach_notifications';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw != null && raw.isNotEmpty) {
      state = raw.toSet();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.toList());
  }

  void markSeen(String id) {
    state = {...state, id};
    _persist();
  }

  void markAllSeen(Iterable<String> ids) {
    state = {...state, ...ids};
    _persist();
  }
}

final seenCoachNotificationIdsProvider =
    StateNotifierProvider<SeenCoachNotificationIdsNotifier, Set<String>>((ref) {
  final notifier = SeenCoachNotificationIdsNotifier();
  notifier.load();
  return notifier;
});
