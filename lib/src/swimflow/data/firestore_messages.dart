import 'package:firebase_core/firebase_core.dart';

String swimFirestoreMessageRu(Object? error, {required bool saving}) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return saving
            ? 'Нет прав на запись. Опубликуйте правила Firestore и войдите в аккаунт.'
            : 'Нет доступа к списку. Опубликуйте правила Firestore и войдите в аккаунт.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Сервис временно недоступен. Попробуйте позже.';
      case 'unauthenticated':
        return 'Войдите в аккаунт, чтобы работать с заплывами.';
      default:
        break;
    }
  }
  if (error is FirebaseException && error.code == 'failed-precondition') {
    return 'Нужен индекс Firestore. Выполните: firebase deploy --only firestore:indexes';
  }
  if (error is StateError) {
    switch (error.message) {
      case 'workout_no_sets':
        return 'Добавьте хотя бы один сет';
      case 'workout_zero_distance':
        return 'Дистанция должна быть больше 0 м';
    }
  }
  return saving ? 'Не удалось сохранить. Попробуйте позже.' : 'Не удалось загрузить список. Проверьте правила Firestore и войдите снова.';
}
