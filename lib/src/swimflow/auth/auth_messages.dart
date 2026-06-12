import 'package:firebase_auth/firebase_auth.dart';

String authErrorMessageRu(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'Некорректный адрес почты';
    case 'user-disabled':
      return 'Аккаунт отключён';
    case 'email-already-in-use':
      return 'Этот адрес уже зарегистрирован — войдите с паролем';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Неверная почта или пароль';
    case 'operation-not-allowed':
      return 'Регистрация по почте отключена в Firebase Console';
    case 'network-request-failed':
      return 'Нет сети. Проверьте интернет.';
    case 'too-many-requests':
      return 'Слишком много попыток. Подождите немного.';
    default:
      return e.message ?? e.code;
  }
}

String firestoreErrorMessageRu(FirebaseException e) {
  final msg = e.message ?? '';
  if (msg.contains('does not exist for project') ||
      msg.contains('add a Cloud Datastore or Cloud Firestore')) {
    return 'В проекте Firebase нет базы Firestore. Консоль Firebase → Firestore Database → создать базу (Native mode), регион по желанию, затем снова регистрация.';
  }
  switch (e.code) {
    case 'permission-denied':
      return 'Нет доступа к базе. Опубликуйте правила: firebase deploy --only firestore:rules';
    case 'unavailable':
      return 'Сервис временно недоступен. Проверьте интернет и повторите.';
    default:
      return '${e.code}: $msg';
  }
}
