import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SeenNotificationIdsNotifier extends StateNotifier<Set<String>> {
  SeenNotificationIdsNotifier() : super({});

  static const _key = 'seen_notifications';

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

  void ensureSeeded(Iterable<String> ids) {
    final current = state;
    if (current.isEmpty && ids.isNotEmpty) {
      state = ids.toSet();
      _persist();
    }
  }
}

final seenNotificationIdsProvider =
    StateNotifierProvider<SeenNotificationIdsNotifier, Set<String>>((ref) {
  final notifier = SeenNotificationIdsNotifier();
  notifier.load();
  return notifier;
});
