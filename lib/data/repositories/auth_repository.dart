import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserProfile?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, password: password,
    );
    final user = cred.user!;
    await user.updateDisplayName(name);

    // Create a minimal profile — full setup happens in onboarding
    final profile = UserProfile(
      uid: user.uid, name: name, email: email,
      age: 25, gender: 'male', skinTone: 5,
      weightKg: 70, city: 'Lahore',
      createdAt: DateTime.now(),
    );

    await _db
        .collection(AppConstants.colUsers)
        .doc(user.uid)
        .set(profile.toMap());

    await _db.collection(AppConstants.colUsers).doc(user.uid).update({
      'lastActive': FieldValue.serverTimestamp(),
    }).catchError((_) {});

    return profile;
  }

  Future<UserProfile?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email, password: password,
    );
    final user = cred.user!;
    await _db.collection(AppConstants.colUsers).doc(user.uid).update({
      'lastActive': FieldValue.serverTimestamp(),
    }).catchError((_) {});

    return _fetchProfile(user.uid);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<UserProfile?> _fetchProfile(String uid) async {
    final doc = await _db.collection(AppConstants.colUsers).doc(uid).get();
    if (!doc.exists) return null;
    
    // Update lastActive timestamp asynchronously
    _db.collection(AppConstants.colUsers).doc(uid).update({
      'lastActive': FieldValue.serverTimestamp(),
    }).catchError((_) {});

    return UserProfile.fromMap(doc.data()!);
  }

  Future<UserProfile?> getProfile(String uid) => _fetchProfile(uid);

  Future<void> updateProfile(UserProfile profile) async {
    await _db
        .collection(AppConstants.colUsers)
        .doc(profile.uid)
        .update(profile.toMap());
  }
}
