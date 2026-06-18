import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../src/core/constants/firestore_collections.dart';
import '../src/swimflow/data/belarus_localities.dart';
import '../src/swimflow/data/coach_exercise_catalog.dart';
import '../src/swimflow/models/app_user_role.dart';
import '../src/swimflow/models/coach_verification_status.dart';
import '../src/swimflow/models/swimflow_sport_rank.dart';

const _password = '123456';

const _adminEmail = 'admin@mail.ru';
const _coachEmail = 'coach@mail.ru';

final _cities = belarusLocalities;
final _rng = Random(42);

final _workoutDates = [1, 5, 9, 13, 17, 21, 25];
final _compDates = [3, 7, 10, 15, 20, 24, 28];

const _combos = [
  ['warm400', 'aerobic10x200', 'cool300'],
  ['warm400', 'kick8x50', 'pull6x100', 'cool300'],
  ['warm400', 'threshold8x150', 'cool300'],
  ['warm400', 'sprint12x25', 'kick8x50', 'cool300'],
  ['warm400', 'im400', 'aerobic10x200', 'cool300'],
  ['warm400', 'pull6x100', 'threshold8x150', 'cool300'],
  ['warm400', 'kick8x50', 'sprint12x25', 'im400', 'cool300'],
];

final _competitionNames = [
  'Чемпионат города Минска',
  'Кубок Беларуси',
  'Открытое первенство области',
  'Республиканские соревнования',
  'Международный турнир «Днепр»',
  'Чемпионат страны',
  'Кубок Федерации',
];

final _swimmers = [
  _SeedSwimmer('swimmer1@mail.ru', 'Анна Смирнова', SwimflowSportRank.firstYouth, 'sprint'),
  _SeedSwimmer('swimmer2@mail.ru', 'Максим Орлов', SwimflowSportRank.secondYouth, 'distance'),
  _SeedSwimmer('swimmer3@mail.ru', 'Дарья Попова', SwimflowSportRank.thirdYouth, 'mixed'),
  _SeedSwimmer('swimmer4@mail.ru', 'Сергей Ковалёв', SwimflowSportRank.firstAdult, 'sprint'),
  _SeedSwimmer('swimmer5@mail.ru', 'Ольга Новикова', SwimflowSportRank.secondAdult, 'distance'),
  _SeedSwimmer('swimmer6@mail.ru', 'Кирилл Зайцев', SwimflowSportRank.thirdAdult, 'mixed'),
  _SeedSwimmer('swimmer7@mail.ru', 'Екатерина Литвин', SwimflowSportRank.noRank, 'sprint'),
];

final _rankNorms = <String, Map<String, int>>{
  SwimflowSportRank.firstYouth: {
    'free_50': 3100, 'free_100': 6600, 'free_200': 14400,
    'back_50': 3500, 'back_100': 7500,
    'breast_50': 3600, 'breast_100': 8300,
    'fly_50': 3400, 'fly_100': 7300,
  },
  SwimflowSportRank.secondYouth: {
    'free_50': 3300, 'free_100': 7000, 'free_200': 15300,
    'back_50': 3700, 'back_100': 8000,
    'breast_50': 3900, 'breast_100': 8800,
    'fly_50': 3600, 'fly_100': 7800,
  },
  SwimflowSportRank.thirdYouth: {
    'free_50': 3500, 'free_100': 7400, 'free_200': 16200,
    'back_50': 3900, 'back_100': 8500,
    'breast_50': 4200, 'breast_100': 9400,
    'fly_50': 3800, 'fly_100': 8300,
  },
  SwimflowSportRank.firstAdult: {
    'free_50': 2550, 'free_100': 5500, 'free_200': 12000,
    'back_50': 2850, 'back_100': 6200, 'back_200': 13200,
    'breast_50': 3100, 'breast_100': 6900, 'breast_200': 14800,
    'fly_50': 2750, 'fly_100': 6000, 'fly_200': 12900,
    'im_100': 6300, 'im_200': 13500,
  },
  SwimflowSportRank.secondAdult: {
    'free_50': 2700, 'free_100': 5800, 'free_200': 12700,
    'back_50': 3000, 'back_100': 6600, 'back_200': 14200,
    'breast_50': 3300, 'breast_100': 7300, 'breast_200': 15800,
    'fly_50': 2900, 'fly_100': 6400, 'fly_200': 13800,
    'im_100': 6700, 'im_200': 14300,
  },
  SwimflowSportRank.thirdAdult: {
    'free_50': 2900, 'free_100': 6200, 'free_200': 13500,
    'back_50': 3200, 'back_100': 7000, 'back_200': 15200,
    'breast_50': 3500, 'breast_100': 7800, 'breast_200': 16800,
    'fly_50': 3100, 'fly_100': 6800, 'fly_200': 14800,
    'im_100': 7100, 'im_200': 15200,
  },
};

final _noRankBase = <String, int>{
  'free_50': 3800, 'free_100': 8000, 'free_200': 17000,
  'back_50': 4200, 'back_100': 9000,
  'breast_50': 4500, 'breast_100': 10000,
};

class _SeedSwimmer {
  const _SeedSwimmer(this.email, this.name, this.rank, this.group);
  final String email;
  final String name;
  final String rank;
  final String group;
}

class _BuiltSets {
  const _BuiltSets(this.sets, this.totalMeters, this.strokeKeys);
  final List<Map<String, dynamic>> sets;
  final double totalMeters;
  final Set<String> strokeKeys;
}

Future<UserCredential> _authCreate(String email) async {
  try {
    return await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email, password: _password,
    );
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      return FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, password: _password,
      );
    }
    rethrow;
  }
}

Map<String, CoachCatalogExercise> _catalogMap() {
  return {for (final t in kCoachExerciseCatalog) t.id: t};
}

int _setMeters(CoachCatalogExercise t) {
  final reps = t.presetReps <= 0 ? 1 : t.presetReps;
  return reps * (t.presetIntervalMeters <= 0 ? 0 : t.presetIntervalMeters);
}

_BuiltSets _buildSets(List<String> comboIds, Map<String, CoachCatalogExercise> cat) {
  final sets = <Map<String, dynamic>>[];
  var total = 0.0;
  final strokes = <String>{};
  for (final id in comboIds) {
    final t = cat[id];
    if (t == null) continue;
    final meters = _setMeters(t);
    total += meters;
    strokes.add(t.strokeKey);
    final reps = t.presetReps <= 0 ? 1 : t.presetReps;
    final interval = t.presetIntervalMeters <= 0 ? 0 : t.presetIntervalMeters;
    sets.add({
      'title': reps > 1 ? '$reps × $interval м' : '$interval м',
      'subtitle': _strokeRu(t.strokeKey),
      'meters': meters,
      'strokeKey': t.strokeKey,
      'intensityIndex': t.defaultIntensityTier,
      'intensityLabel': _intensityRu(t.defaultIntensityTier),
    });
  }
  return _BuiltSets(sets, total, strokes);
}

String _strokeRu(String key) {
  switch (key) {
    case 'breast': return 'Брасс';
    case 'back': return 'На спине';
    case 'fly': return 'Баттерфляй';
    case 'im': return 'Комплекс';
    default: return 'Вольный стиль';
  }
}

String _intensityRu(int i) {
  const labels = ['Восстановление', 'Низкая', 'Средняя', 'Высокая'];
  return labels[i.clamp(0, 3)];
}

String _pickCity() => _cities[_rng.nextInt(_cities.length)];

DateTime _juneDate(int day, {int hour = 10}) {
  return DateTime(2026, 6, day, hour, _rng.nextInt(60));
}

int _compTimeCs(String rankKey, String strokeKey, int distanceMeters) {
  if (rankKey == SwimflowSportRank.noRank) {
    final norm = _noRankBase['${strokeKey}_$distanceMeters'] ?? 8000;
    return norm - _rng.nextInt(300) - 50;
  }
  final norms = _rankNorms[rankKey];
  final norm = norms?['${strokeKey}_$distanceMeters'];
  if (norm == null) return 8000;
  return norm - _rng.nextInt(400) - 100;
}

int _goalTimeCs(String rankKey, String strokeKey, int distanceMeters) {
  if (rankKey == SwimflowSportRank.noRank) return 8000;
  final norms = _rankNorms[rankKey];
  final norm = norms?['${strokeKey}_$distanceMeters'];
  if (norm == null) return 8000;
  return norm;
}

List<String> _pickDisciplines(String rankKey, int count) {
  final all = <String>[];
  final norms = _rankNorms[rankKey];
  if (norms == null) {
    for (var i = 0; i < count; i++) {
      all.add('free_100');
    }
    return all;
  }
  all.addAll(norms.keys);
  all.shuffle(_rng);
  return all.take(count).toList();
}

Future<String> runFullResetSeed() async {
  final db = FirebaseFirestore.instance;
  final cat = _catalogMap();
  final out = <String>[];

  out.add('=== ПОЛНАЯ ПЕРЕЗАГРУЗКА БАЗЫ ДАННЫХ ===\n');

  // ========== 1. Admin ==========
  out.add('[1/7] Создаю администратора…');
  final adminCred = await _authCreate(_adminEmail);
  final adminUid = adminCred.user!.uid;
  // NOTE: Firestore rules prevent creating role='admin' from client SDK.
  // Creating with role='swimmer'; change to 'admin' manually in Firebase Console.
  await FirestoreCollections.userRef(db, adminUid).set({
    'email': _adminEmail,
    'displayName': 'Админ Системы',
    'sportRank': '',
    'role': AppUserRole.swimmer,
    'city': 'Минск',
    'avatarUrl': '',
    'avatarPreset': '',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  out.add('  ✓ $_adminEmail / $_password');
  out.add('  ⚠️  В Firebase Console смени роль пользователю на admin');
  await FirebaseAuth.instance.signOut();

  // ========== 2. Coach ==========
  out.add('[2/7] Создаю тренера…');
  final coachCred = await _authCreate(_coachEmail);
  final coachUid = coachCred.user!.uid;
  final coachCity = _pickCity();
  await FirestoreCollections.userRef(db, coachUid).set({
    'email': _coachEmail,
    'displayName': 'Игорь Тренеров',
    'sportRank': '',
    'role': AppUserRole.coach,
    'city': coachCity,
    'avatarUrl': '',
    'avatarPreset': '',
    'profileComplete': true,
    'coachVerificationStatus': CoachVerificationStatus.approved,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  await db.collection(FirestoreCollections.coachRegistrationRequests).doc(coachUid).set({
    'uid': coachUid,
    'email': _coachEmail,
    'displayName': 'Игорь Тренеров',
    'status': CoachVerificationStatus.approved,
    'certificateUrls': ['https://example.invalid/coach-cert.pdf'],
    'reviewedAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  const inviteCode = 'COACH1';
  await db.collection(FirestoreCollections.coachInvites).doc(inviteCode).set({
    'coachId': coachUid,
    'createdAt': FieldValue.serverTimestamp(),
  });
  out.add('  ✓ $_coachEmail / $_password');
  out.add('  Город: $coachCity, Инвайт-код: $inviteCode');
  await FirebaseAuth.instance.signOut();

  // ========== 3. Create swimmer auth accounts ==========
  out.add('[3/7] Создаю аккаунты пловцов…');
  final swimmerUids = <String>[];
  for (final s in _swimmers) {
    final cred = await _authCreate(s.email);
    swimmerUids.add(cred.user!.uid);
    await FirebaseAuth.instance.signOut();
  }

  // ========== 4. Create swimmer Firestore docs (signing in as each) ==========
  out.add('[4/7] Создаю документы пловцов…');
  for (var si = 0; si < _swimmers.length; si++) {
    final s = _swimmers[si];
    final uid = swimmerUids[si];
    final city = _pickCity();

    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: s.email, password: _password,
    );
    await FirestoreCollections.userRef(db, uid).set({
      'email': s.email,
      'displayName': s.name,
      'sportRank': s.rank,
      'role': AppUserRole.swimmer,
      'city': city,
      'coachId': coachUid,
      'trainingGroup': s.group,
      'avatarUrl': '',
      'avatarPreset': '',
      'coachInviteLabel': 'Приглашён тренером',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await FirebaseAuth.instance.signOut();
    out.add('  ✓ ${s.name} — ${SwimflowSportRank.labelShortRu(s.rank)}, $city');
  }

  // ========== 5. Coach data: dossiers, goals, workouts ==========
  out.add('[5/7] Тренер создаёт досье, цели и тренировки…');
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: _coachEmail, password: _password,
  );

  for (var si = 0; si < _swimmers.length; si++) {
    final s = _swimmers[si];
    final uid = swimmerUids[si];
    final city = _pickCity();

    // Athlete dossier
    await FirestoreCollections.coachAthleteDossiers(db, coachUid).doc(uid).set({
      'fullName': s.name,
      'birthYear': 2006 + (si % 6),
      'phone': '+37529${(1000000 + si * 11111).toString().substring(0, 7)}',
      'city': city,
      'notes': 'Перспективный спортсмен, группа ${s.group}',
      'medicalNotes': si % 3 == 0 ? 'Аллергия на хлор (использовать очки)' : '',
      'parentContact': si % 2 == 0 ? '+37529${(2000000 + si * 22222).toString().substring(0, 7)}' : '',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Performance goals (2-3)
    if (s.rank != SwimflowSportRank.noRank) {
      final goals = <List<String>>[];
      goals.add(['free', '100', '25']);
      goals.add(['free', '200', '25']);
      if (s.rank == SwimflowSportRank.firstAdult || s.rank == SwimflowSportRank.secondAdult || s.rank == SwimflowSportRank.thirdAdult) {
        goals.add(['im', '200', '25']);
      } else {
        goals.add(['back', '100', '25']);
      }

      for (final g in goals) {
        final strokeKey = g[0];
        final dist = int.parse(g[1]);
        final pl = int.parse(g[2]);
        final docId = '${strokeKey}_${dist}_$pl';
        final target = _goalTimeCs(s.rank, strokeKey, dist);
        await FirestoreCollections.userPerformanceGoalDoc(db, uid, docId).set({
          'strokeKey': strokeKey,
          'distanceMeters': dist,
          'poolLengthMeters': pl,
          'targetTimeCentiseconds': target,
          'coachId': coachUid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // Workouts from coach (5 per swimmer)
    for (var wi = 0; wi < _workoutDates.length; wi++) {
      final day = _workoutDates[wi];
      final combo = _combos[wi % _combos.length];
      final built = _buildSets(combo, cat);
      final scheduledAt = _juneDate(day, hour: 17);
      final isPast = scheduledAt.isBefore(DateTime.now());
      final durationSeconds = (built.totalMeters * 1.35).round().clamp(1800, 10800);

      final recordMeta = <String, dynamic>{
        'sets': built.sets,
        'enteredByCoach': true,
      };
      if (isPast) {
        recordMeta['mood'] = '${3 + (wi % 5)}';
        recordMeta['fatigue'] = (4 + (wi % 6)).clamp(1, 10);
        recordMeta['physicalState'] = wi % 3 == 0 ? 'energy' : wi % 3 == 1 ? 'normal' : 'tired';
        recordMeta['wellbeingSaved'] = true;
        recordMeta['wellbeingSavedAt'] = Timestamp.fromDate(scheduledAt);
      }

      final rawTitle = combo.map((id) => cat[id]?.title).whereType<String>().join(' · ');
      final title = rawTitle.length > 80 ? rawTitle.substring(0, 80) : rawTitle;

      await FirestoreCollections.userWorkouts(db, uid).add({
        'title': title,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'distanceMeters': built.totalMeters,
        'durationSeconds': durationSeconds,
        'poolName': '25 м',
        'coachId': coachUid,
        'recordMeta': recordMeta,
      });
    }
  }

  await FirebaseAuth.instance.signOut();

  // ========== 6. Competition swims (as each swimmer) ==========
  out.add('[6/7] Пловцы добавляют соревнования…');
  for (var si = 0; si < _swimmers.length; si++) {
    final s = _swimmers[si];
    final uid = swimmerUids[si];

    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: s.email, password: _password,
    );

    final compCount = 4 + (si % 4); // 4-7 competitions
    final discs = _pickDisciplines(s.rank, compCount);

    for (var ci = 0; ci < compCount && ci < discs.length && ci < _compDates.length; ci++) {
      final disc = discs[ci];
      final parts = disc.split('_');
      final strokeKey = parts[0];
      final distanceMeters = int.parse(parts[1]);
      final day = _compDates[ci];
      final eventDate = _juneDate(day);
      final timeCs = _compTimeCs(s.rank, strokeKey, distanceMeters);

      await FirestoreCollections.userCompetitionSwims(db, uid).add({
        'eventDate': Timestamp.fromDate(eventDate),
        'distanceMeters': distanceMeters,
        'strokeKey': strokeKey,
        'timeCentiseconds': timeCs,
        'poolLengthMeters': 25,
        'city': _pickCity(),
        'competitionName': _competitionNames[ci % _competitionNames.length],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await FirebaseAuth.instance.signOut();
  }

  // ========== 7. Cleanup coach_invites + registration_requests ==========
  out.add('[7/7] Очистка мусора…');
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _coachEmail, password: _password,
    );
    final invitesSnap = await db.collection(FirestoreCollections.coachInvites)
        .where('coachId', isEqualTo: coachUid).get();
    for (final doc in invitesSnap.docs) {
      if (doc.id != inviteCode) {
        await doc.reference.delete();
      }
    }
    await FirebaseAuth.instance.signOut();
  } catch (_) {}

  out.add('\n=== ГОТОВО ===');
  out.add('━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  out.add('📧 Администратор: $_adminEmail / $_password');
  out.add('📧 Тренер:          $_coachEmail / $_password');
  out.add('🔑 Инвайт-код:     $inviteCode');
  out.add('👥 Пловцов:        ${_swimmers.length}');
  out.add('━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  out.add('');
  out.add('⚠️  ВАЖНО:');
  out.add('1. Админ создан с ролью swimmer (правила Firestore не');
  out.add('   позволяют создать admin из клиента). Открой Firebase');
  out.add('   Console → Firestore → users/{adminUid} → role: "admin"');
  out.add('2. Если нужна чистая БД — отключи правила временно:');
  out.add('   Firebase Console → Firestore → Rules →');
  out.add('   allow read, write: if true; → Опубликовать');
  out.add('   После сида верни исходные правила.');
  out.add('');
  out.add('📅 Данные: 1–29 июня 2026');
  out.add('📊 У каждого пловца: 5 тренировок от тренера,');
  out.add('    4-7 соревнований, 2-3 цели, досье.');

  return out.join('\n');
}
