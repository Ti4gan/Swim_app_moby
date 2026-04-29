import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_collections.dart';

class CompleteDemoSeedService {
  CompleteDemoSeedService(this._firestore);

  final FirebaseFirestore _firestore;

  /// Seeds the database with comprehensive test data for all collections.
  /// Returns a map with IDs of created entities for reference.
  Future<Map<String, dynamic>> seedAll() async {
    final random = Random();
    final now = FieldValue.serverTimestamp();

    // 1. Create users (authentication entries) - in real app these come from Firebase Auth,
    //    but we can create placeholder documents in 'users' collection.
    final adminUser = _firestore
        .collection(FirestoreCollections.users)
        .doc('admin_uid');
    final coachUser = _firestore
        .collection(FirestoreCollections.users)
        .doc('coach_uid');
    final athleteUser = _firestore
        .collection(FirestoreCollections.users)
        .doc('athlete_uid');

    await adminUser.set({
      'email': 'admin@example.com',
      'role': 'admin',
      'createdAt': now,
    });
    await coachUser.set({
      'email': 'coach@example.com',
      'role': 'coach',
      'createdAt': now,
    });
    await athleteUser.set({
      'email': 'athlete@example.com',
      'role': 'athlete',
      'createdAt': now,
    });

    // 2. Coach profile
    final coachDoc = _firestore
        .collection(FirestoreCollections.coaches)
        .doc('coach_uid');
    await coachDoc.set({
      'userId': 'coach_uid',
      'fullName': 'Иван Петрович тренер',
      'phone': '+375 (29) 123-45-67',
      'approved': true,
      'createdAt': now,
    });

    // 3. Athlete profile
    final athleteDoc = _firestore
        .collection(FirestoreCollections.athletes)
        .doc();
    final entryCode = 'ATH-${100000 + random.nextInt(900000)}';
    await athleteDoc.set({
      'coachId': 'coach_uid',
      'userId': 'athlete_uid',
      'fullName': 'Алексей Сергеев спортсмен',
      'entryCode': entryCode,
      'phone': '+375 (33) 987-65-43',
      'dateOfBirth': Timestamp.fromDate(DateTime(2000, 5, 15)),
      'createdAt': now,
    });

    // 4. Exercises (reference list)
    final exercises = [
      {'name': 'Кроль на груди', 'description': 'Плавание брассом на груди'},
      {'name': 'Брасс', 'description': 'Плавание брассом'},
      {'name': 'Батерфляй', 'description': 'Плавание батерфляем'},
      {'name': 'На спине', 'description': 'Плавание на спине'},
      {'name': 'Поворот', 'description': 'Техника поворота у бортика'},
      {'name': 'Start', 'description': 'Start с тумбочки'},
    ];
    final exerciseDocs = <String, DocumentReference>{};
    for (final ex in exercises) {
      final docRef = _firestore
          .collection(FirestoreCollections.exercises)
          .doc();
      await docRef.set({...ex, 'createdAt': now});
      exerciseDocs[ex['name']!] = docRef;
    }

    // 5. Training plans
    final plans = [
      {
        'title': 'Спринт 50 м',
        'distanceMeters': 50.0,
        'targetTime': '00:28',
        'description': 'Короткая дистанция на скорость',
      },
      {
        'title': 'Кроль 200 м',
        'distanceMeters': 200.0,
        'targetTime': '02:25',
        'description': 'Средняя дистанция кролем',
      },
      {
        'title': 'Выносливость 800 м',
        'distanceMeters': 800.0,
        'targetTime': '10:30',
        'description': 'Длинная дистанция для выносливости',
      },
      {
        'title': 'Техника поворотов',
        'distanceMeters': 0.0,
        'targetTime': null,
        'description': 'Упражнения на отработку поворотов',
      },
    ];
    final planDocs = <String, DocumentReference>{};
    final planDistanceMeters = <String, double>{};
    for (final plan in plans) {
      final docRef = _firestore
          .collection(FirestoreCollections.trainingPlans)
          .doc();
      await docRef.set({
        'coachId': 'coach_uid',
        'athleteId': athleteDoc.id,
        ...plan,
        'createdAt': now,
      });
      final title = plan['title'] as String;
      planDocs[title] = docRef;
      planDistanceMeters[title] = plan['distanceMeters'] as double;
    }

    // 6. Trainings (instances of plans for specific dates)
    final trainings = <String, DocumentReference>{};
    final startDate = DateTime.now().subtract(const Duration(days: 30));
    for (var i = 0; i < 10; i++) {
      final planKey = plans[i % plans.length]['title']!;
      final planRef = planDocs[planKey]!;
      final trainingDate = startDate.add(Duration(days: i * 3));
      final docRef = _firestore
          .collection(FirestoreCollections.trainings)
          .doc();
      await docRef.set({
        'planId': planRef.id,
        'athleteId': athleteDoc.id,
        'date': Timestamp.fromDate(trainingDate),
        'completed': i % 3 != 0, // some completed, some not
        'createdAt': now,
      });
      trainings['training_$i'] = docRef;
    }

    // 7. TrainingTasks (specific tasks within a training)
    for (final trainingEntry in trainings.entries) {
      final trainingRef = trainingEntry.value;
      // Assign 2-4 random tasks per training
      final taskCount = 2 + random.nextInt(3);
      final selectedExercises = exercises.take(taskCount).toList();
      for (var j = 0; j < taskCount; j++) {
        final ex = selectedExercises[j];
        final docRef = _firestore
            .collection(FirestoreCollections.trainingTasks)
            .doc();
        await docRef.set({
          'trainingId': trainingRef.id,
          'exerciseId': exerciseDocs[ex['name']!]!.id,
          'sets': 3 + random.nextInt(3), // 3-5 sets
          'repsPerSet': ex['name'] == 'Поворот' || ex['name'] == 'Start'
              ? null
              : 25 + random.nextInt(26), // 25-50 meters or laps
          'distanceMeters': ex['name'] == 'Поворот' || ex['name'] == 'Start'
              ? null
              : 25.0,
          'targetTimePerSet': ex['name'] == 'Кроль на груди' ? '00:30' : null,
          'notes': 'Задание $j для тренировки',
          'completed': random.nextBool(),
          'createdAt': now,
        });
      }
    }

    // 8. Diary entries
    for (var i = 0; i < 15; i++) {
      final diaryDate = startDate.add(Duration(days: i * 2));
      final docRef = _firestore.collection(FirestoreCollections.diary).doc();
      await docRef.set({
        'athleteId': athleteDoc.id,
        'date': Timestamp.fromDate(diaryDate),
        'mood': [
          'Отлично',
          'Хорошо',
          'Нормально',
          'Усталость',
        ][random.nextInt(4)],
        'sleepHours': 6 + random.nextInt(4), // 6-9 hours
        'notes':
            'Запись дневника за ${diaryDate.day}.${diaryDate.month}.${diaryDate.year}. Самочувствие: ...',
        'createdAt': now,
      });
    }

    // 9. Results (swimming times)
    for (var i = 0; i < 20; i++) {
      final planKey = plans[i % plans.length]['title']!;
      final planRef = planDocs[planKey]!;
      final distanceMeters = planDistanceMeters[planKey]!;
      final resultDate = startDate.add(Duration(days: i * 2));
      final baseSeconds = distanceMeters == 50
          ? 28.0
          : distanceMeters == 200
          ? 145.0
          : distanceMeters == 800
          ? 630.0
          : 0.0;
      final variance = (random.nextDouble() - 0.5) * 10; // +/-5 seconds
      final totalSeconds = baseSeconds + variance;
      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;
      final timeString =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toStringAsFixed(2).padLeft(5, '0')}';
      final docRef = _firestore.collection(FirestoreCollections.results).doc();
      await docRef.set({
        'athleteId': athleteDoc.id,
        'trainingPlanId': planRef.id,
        'date': Timestamp.fromDate(resultDate),
        'time': timeString,
        'distanceMeters': distanceMeters,
        'isPersonalBest': i < 3, // first three are bests
        'createdAt': now,
      });
    }

    // 10. Reports (coach/athlete reports)
    final reportTypes = ['Еженедельный', 'Месячный', 'После соревнований'];
    for (var i = 0; i < 6; i++) {
      final docRef = _firestore.collection(FirestoreCollections.reports).doc();
      await docRef.set({
        'coachId': 'coach_uid',
        'athleteId': athleteDoc.id,
        'type': reportTypes[i % reportTypes.length],
        'periodStart': Timestamp.fromDate(
          startDate.subtract(Duration(days: 30)),
        ),
        'periodEnd': Timestamp.fromDate(startDate),
        'summary':
            'Отчет за период: улучшение техники, стабильные времена. Рекомендации: увеличить объем.',
        'createdAt': now,
      });
    }

    return {
      'adminUserId': adminUser.id,
      'coachUserId': coachUser.id,
      'athleteUserId': athleteUser.id,
      'coachId': coachDoc.id,
      'athleteId': athleteDoc.id,
      'entryCode': entryCode,
      'exerciseIds': exerciseDocs.values.map((e) => e.id).toList(),
      'planIds': planDocs.values.map((e) => e.id).toList(),
      'trainingIds': trainings.values.map((e) => e.id).toList(),
    };
  }
}
