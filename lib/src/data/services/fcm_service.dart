import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/constants/firestore_collections.dart';

class FcmService {
  FcmService(this._messaging, this._firestore);

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  Future<void> initForUser(String userId) async {
    await _messaging.requestPermission();
    final token = await _messaging.getToken();
    if (token != null) {
      await _firestore.collection(FirestoreCollections.users).doc(userId).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
  }
}
