import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;
  UserProfile? _profile;
  bool _loading = false;
  String? _error;

  AuthProvider(this._repo) {
    _repo.authStateChanges.listen((user) async {
      if (user != null) {
        _profile = await _repo.getProfile(user.uid);
        if (_profile != null) {
          FirebaseAnalytics.instance.setUserId(id: _profile!.uid).catchError((_) {});
        }
      } else {
        _profile = null;
      }
      notifyListeners();
    });
  }

  UserProfile? get profile  => _profile;
  bool get isLoggedIn       => _profile != null;
  bool get loading          => _loading;
  String? get error         => _error;

  Future<bool> signUp(String email, String password, String name) async {
    _loading = true; _error = null; notifyListeners();
    try {
      _profile = await _repo.signUpWithEmail(email: email, password: password, name: name);
      if (_profile != null) {
        FirebaseAnalytics.instance.logSignUp(signUpMethod: 'email').catchError((_) {});
        FirebaseAnalytics.instance.setUserId(id: _profile!.uid).catchError((_) {});
        FirebaseAnalytics.instance.setUserProperty(name: 'city', value: _profile!.city).catchError((_) {});
      }
      return true;
    } catch (e) {
      _error = _friendlyError(e.toString()); return false;
    } finally { _loading = false; notifyListeners(); }
  }

  Future<bool> signIn(String email, String password) async {
    _loading = true; _error = null; notifyListeners();
    try {
      _profile = await _repo.signInWithEmail(email: email, password: password);
      if (_profile != null) {
        FirebaseAnalytics.instance.logLogin(loginMethod: 'email').catchError((_) {});
        FirebaseAnalytics.instance.setUserId(id: _profile!.uid).catchError((_) {});
      }
      return true;
    } catch (e) {
      _error = _friendlyError(e.toString()); return false;
    } finally { _loading = false; notifyListeners(); }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _profile = null;
    FirebaseAnalytics.instance.setUserId(id: null).catchError((_) {});
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile updated) async {
    await _repo.updateProfile(updated); _profile = updated; notifyListeners();
  }

  Future<void> sendPasswordReset(String email) => _repo.sendPasswordReset(email);

  String _friendlyError(String raw) {
    print('Auth Error: $raw'); // added print for debugging
    if (raw.contains('email-already-in-use'))  return 'Email already registered.';
    if (raw.contains('wrong-password'))         return 'Incorrect password.';
    if (raw.contains('user-not-found'))         return 'No account with this email.';
    if (raw.contains('weak-password'))          return 'Password too weak (min 6 chars).';
    if (raw.contains('network-request-failed')) return 'No internet connection.';
    return raw; // Return the raw error to see what's actually failing
  }
}
