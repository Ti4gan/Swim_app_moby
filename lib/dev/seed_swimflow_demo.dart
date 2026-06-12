import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../src/core/constants/firestore_collections.dart';
import '../src/swimflow/data/coach_exercise_catalog.dart';
import '../src/swimflow/models/app_user_role.dart';
import '../src/swimflow/models/coach_verification_status.dart';
import '../src/swimflow/models/swimflow_sport_rank.dart';

const kSeedPassword = '123456';

const kSeedAdminEmail = 'admin@mail.ru';
const kSeedCoachEmail = 'coach@mail.ru';

const _swimmers = [
  _SeedSwimmer('user1@mail.ru', 'Ян Кузьмичёв', SwimflowSportRank.firstYouth, 'sprint'),
  _SeedSwimmer('user2@mail.ru', 'Алина Морозова', SwimflowSportRank.secondYouth, 'distance'),
  _SeedSwimmer('user3@mail.ru', 'Максим Волков', SwimflowSportRank.thirdYouth, 'mixed'),
  _SeedSwimmer('user4@mail.ru', 'София Лебедева', SwimflowSportRank.thirdAdult, 'sprint'),
  _SeedSwimmer('user5@mail.ru', 'Дмитрий Козлов', SwimflowSportRank.secondAdult, 'distance'),
  _SeedSwimmer('user6@mail.ru', 'Полина Соколова', SwimflowSportRank.firstAdult, 'mixed'),
];

const _combos = [
  ['warm400', 'aerobic10x200', 'cool300'],
  ['warm400', 'kick8x50', 'pull6x100', 'cool300'],
  ['warm400', 'threshold8x150', 'cool300'],
  ['warm400', 'sprint12x25', 'kick8x50', 'cool300'],
  ['warm400', 'im400', 'aerobic10x200', 'cool300'],
  ['warm400', 'pull6x100', 'threshold8x150', 'cool300'],
];

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
      email: email,
      password: kSeedPassword,
    );
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      return FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: kSeedPassword,
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
  final interval = t.presetIntervalMeters <= 0 ? 0 : t.presetIntervalMeters;
  return reps * interval;
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
    case 'breast':
      return 'Брасс';
    case 'back':
      return 'На спине';
    case 'fly':
      return 'Баттерфляй';
    case 'im':
      return 'Комплекс';
    default:
      return 'Вольный стиль';
  }
}

String _intensityRu(int i) {
  const labels = ['Восстановление', 'Низкая', 'Средняя', 'Высокая'];
  return labels[i.clamp(0, 3)];
}

List<DateTime> _trainingDays() {
  final today = DateTime.now();
  final base = DateTime(today.year, today.month, today.day);
  final out = <DateTime>[];
  for (var offset = -14; offset <= 3; offset++) {
    final d = base.add(Duration(days: offset));
    final dow = d.weekday;
    if (dow == DateTime.sunday ||
        dow == DateTime.tuesday ||
        dow == DateTime.thursday ||
        dow == DateTime.saturday) {
      out.add(d);
    }
  }
  return out;
}

Future<void> _seedCatalog(FirebaseFirestore db) async {
  final batch = db.batch();
  for (final t in kCoachExerciseCatalog) {
    batch.set(
      db.collection(FirestoreCollections.catalogExercises).doc(t.id),
      t.toFirestore(),
    );
  }
  await batch.commit();
}

Future<String> runSwimflowDemoSeed() async {
  final db = FirebaseFirestore.instance;
  final cat = _catalogMap();
  final days = _trainingDays();

  await _seedCatalog(db);

  final adminCred = await _authCreate(kSeedAdminEmail);
  final adminUid = adminCred.user!.uid;
  await FirestoreCollections.userRef(db, adminUid).set({
    'email': kSeedAdminEmail,
    'displayName': 'Админ Системы',
    'sportRank': '',
    'role': AppUserRole.admin,
    'city': 'Минск',
    'avatarUrl': '',
    'avatarPreset': '',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  await FirebaseAuth.instance.signOut();

  final coachCred = await _authCreate(kSeedCoachEmail);
  final coachUid = coachCred.user!.uid;
  await FirestoreCollections.userRef(db, coachUid).set({
    'email': kSeedCoachEmail,
    'displayName': 'Игорь Тренеров',
    'sportRank': '',
    'role': AppUserRole.coach,
    'city': 'Минск',
    'avatarUrl': '',
    'avatarPreset': '',
    'totalWorkouts': 0,
    'totalDistanceMeters': 0,
    'workoutsThisMonth': 0,
    'coachVerificationStatus': CoachVerificationStatus.approved,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  await db.collection(FirestoreCollections.coachRegistrationRequests).doc(coachUid).set({
    'uid': coachUid,
    'email': kSeedCoachEmail,
    'displayName': 'Игорь Тренеров',
    'status': CoachVerificationStatus.approved,
    'certificateUrls': ['https://example.invalid/coach-cert.pdf'],
    'reviewedAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  await FirebaseAuth.instance.signOut();

  final swimmerUids = <String>[];
  for (var si = 0; si < _swimmers.length; si++) {
    final s = _swimmers[si];
    final cred = await _authCreate(s.email);
    final uid = cred.user!.uid;
    swimmerUids.add(uid);

    await FirestoreCollections.userRef(db, uid).set({
      'email': s.email,
      'displayName': s.name,
      'sportRank': s.rank,
      'role': AppUserRole.swimmer,
      'city': 'Минск',
      'coachId': coachUid,
      'trainingGroup': s.group,
      'avatarUrl': '',
      'avatarPreset': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await FirebaseAuth.instance.signOut();
  }

  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: kSeedCoachEmail,
    password: kSeedPassword,
  );

  for (var si = 0; si < _swimmers.length; si++) {
    final s = _swimmers[si];
    final uid = swimmerUids[si];
    final goalCs = 6200 + si * 80;

    await FirestoreCollections.coachAthleteDossiers(db, coachUid).doc(uid).set({
      'fullName': s.name,
      'birthYear': 2008 + (si % 5),
      'phone': '+37529${(1000000 + si * 11111).toString().substring(0, 7)}',
      'city': 'Минск',
      'notes': 'Тестовый пловец',
      'medicalNotes': '',
      'parentContact': '',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await FirestoreCollections.userPerformanceGoalDoc(db, uid, 'free_100_25').set({
      'strokeKey': 'free',
      'distanceMeters': 100,
      'poolLengthMeters': 25,
      'targetTimeCentiseconds': goalCs,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await FirestoreCollections.userPerformanceGoalDoc(db, uid, 'back_200_25').set({
      'strokeKey': 'back',
      'distanceMeters': 200,
      'poolLengthMeters': 25,
      'targetTimeCentiseconds': goalCs + 2800,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final compTimes = [
      (120, goalCs + 450 + si * 10),
      (60, goalCs + 220),
      (20, goalCs - 80 - si * 5),
    ];
    for (var ci = 0; ci < compTimes.length; ci++) {
      final ev = DateTime.now().subtract(Duration(days: compTimes[ci].$1));
      await FirestoreCollections.userCompetitionSwims(db, uid).doc('cs100_$ci').set({
        'eventDate': Timestamp.fromDate(ev),
        'distanceMeters': 100,
        'strokeKey': 'free',
        'timeCentiseconds': compTimes[ci].$2,
        'poolLengthMeters': 25,
        'city': 'Минск',
        'competitionName': 'Кубок города #${ci + 1}',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    if (si < 4) {
      final fifty = [(90, 3200 + si * 40), (30, 3050 + si * 25)];
      for (var fi = 0; fi < fifty.length; fi++) {
        final ev = DateTime.now().subtract(Duration(days: fifty[fi].$1));
        await FirestoreCollections.userCompetitionSwims(db, uid).doc('cs50_$fi').set({
          'eventDate': Timestamp.fromDate(ev),
          'distanceMeters': 50,
          'strokeKey': 'free',
          'timeCentiseconds': fifty[fi].$2,
          'poolLengthMeters': 25,
          'city': 'Минск',
          'competitionName': 'Спринт ${fi + 1}',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    final batch = db.batch();
    var wi = 0;
    for (final day in days) {
      final combo = _combos[wi % _combos.length];
      wi++;
      final built = _buildSets(combo, cat);
      final scheduledAt = DateTime(day.year, day.month, day.day, 17, 30);
      final isPast = scheduledAt.isBefore(DateTime.now());
      final durationSeconds = (built.totalMeters * 1.35).round().clamp(1800, 10800);
      final mood = '${2 + (wi % 3)}';
      final fatigue = 4 + (wi % 5);
      final recordMeta = <String, dynamic>{'sets': built.sets};
      if (isPast) {
        recordMeta['mood'] = mood;
        recordMeta['fatigue'] = fatigue;
        recordMeta['physicalState'] = wi % 3 == 0 ? 'energy' : 'normal';
        recordMeta['wellbeingSaved'] = true;
        recordMeta['wellbeingSavedAt'] = Timestamp.fromDate(scheduledAt);
      }
      final title = combo.map((id) => cat[id]?.title).whereType<String>().join(' · ');
      batch.set(FirestoreCollections.userWorkouts(db, uid).doc('w_$wi'), {
        'title': title.length > 80 ? title.substring(0, 80) : title,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'distanceMeters': built.totalMeters,
        'durationSeconds': durationSeconds,
        'poolName': '25 м',
        'coachId': coachUid,
        'recordMeta': recordMeta,
      });
    }
    await batch.commit();
  }

  await FirebaseAuth.instance.signOut();

  return 'OK admin=$kSeedAdminEmail coach=$kSeedCoachEmail swimmers=${_swimmers.length} '
      'password=$kSeedPassword workoutsPerSwimmer=${days.length}';
}
