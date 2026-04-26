import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snap) => snap.exists ? UserModel.fromMap(snap.data()!) : null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final userDoc = await _firestore.collection('users').doc(cred.user!.uid).get();
    if (!userDoc.exists) throw Exception('User not found');

    await _updateOnlineStatus(cred.user!.uid, true);
    return UserModel.fromMap(userDoc.data()!);
  }

  Future<UserModel> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await cred.user!.updateDisplayName(name);

    final user = UserModel(
      uid: cred.user!.uid,
      name: name,
      email: email,
      isOnline: true,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(user.toMap());
    return user;
  }

  Future<void> signOut() async {
    if (currentUserId != null) {
      await _updateOnlineStatus(currentUserId!, false);
    }
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateProfile({
    String? name,
    String? photoUrl,
    String? bio,
  }) async {
    if (currentUserId == null) return;

    final updates = <String, dynamic>{};
    if (name != null) {
      updates['name'] = name;
      await _auth.currentUser!.updateDisplayName(name);
    }
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (bio != null) updates['bio'] = bio;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(currentUserId!).update(updates);
    }
  }

  Future<void> _updateOnlineStatus(String uid, bool isOnline) async {
    await _firestore.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFcmToken(String token) async {
    if (currentUserId == null) return;
    await _firestore.collection('users').doc(currentUserId!).update({
      'fcmToken': token,
    });
  }

  Stream<List<UserModel>> searchUsers(String query) {
    return _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: '${query}z')
        .where('uid', isNotEqualTo: currentUserId)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserModel.fromMap(d.data())).toList());
  }
}
