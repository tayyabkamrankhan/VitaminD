import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FriendProgress {
  final String uid;
  final String name;
  final String email;
  final int skinTone;
  final double todaySynthesized;
  final double dailyTarget;

  FriendProgress({
    required this.uid,
    required this.name,
    required this.email,
    required this.skinTone,
    required this.todaySynthesized,
    required this.dailyTarget,
  });
}

class SocialProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<FriendProgress> _friends = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _loading = false;
  bool _searching = false;
  String? _error;

  List<FriendProgress> get friends => _friends;
  List<Map<String, dynamic>> get searchResults => _searchResults;
  bool get loading => _loading;
  bool get searching => _searching;
  String? get error => _error;

  Future<void> searchUsers(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _searching = true;
    notifyListeners();

    try {
      final usersSnap = await _db.collection('users').get();
      final List<Map<String, dynamic>> results = [];
      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final name = (data['name'] as String? ?? '').toLowerCase();
        final email = (data['email'] as String? ?? '').toLowerCase();
        if (name.contains(q) || email.contains(q)) {
          results.add({
            'uid': data['uid'] ?? doc.id,
            'name': data['name'] ?? 'User',
            'email': data['email'] ?? '',
            'skinTone': data['skinTone'] ?? 5,
          });
        }
      }
      _searchResults = results;
    } catch (_) {} finally {
      _searching = false;
      notifyListeners();
    }
  }

  Future<void> loadFriends(String myUid) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final friendsSnap = await _db.collection('users').doc(myUid).collection('friends').get();
      final List<FriendProgress> loaded = [];
      
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      for (final doc in friendsSnap.docs) {
        final data = doc.data();
        final fUid = data['uid'] as String;
        final fName = data['name'] as String;
        final fEmail = data['email'] as String;
        final fSkinTone = data['skinTone'] as int? ?? 5;

        // Fetch their today's synthesized IU
        final uvReadingsSnap = await _db
            .collection('users')
            .doc(fUid)
            .collection('uv_readings')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .get();

        final todaySynthesized = uvReadingsSnap.docs.fold<double>(0.0, (acc, d) =>
            acc + ((d.data()['synthesizedIU'] ?? 0.0) as num).toDouble());

        // Target (WHO standard: average 600 IU)
        final dailyTarget = 600.0; 

        loaded.add(FriendProgress(
          uid: fUid,
          name: fName,
          email: fEmail,
          skinTone: fSkinTone,
          todaySynthesized: todaySynthesized,
          dailyTarget: dailyTarget,
        ));
      }
      _friends = loaded;
    } catch (e) {
      _error = 'Failed to load friends: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> addFriendByEmail(String myUid, String email) async {
    _error = null;
    notifyListeners();
    try {
      final cleanEmail = email.trim().toLowerCase();
      
      // 1. Search for user by email in the main users collection
      final userQuery = await _db
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        _error = 'No user found with this email.';
        notifyListeners();
        return false;
      }

      final friendDoc = userQuery.docs.first;
      final friendData = friendDoc.data();
      final friendUid = friendData['uid'] as String;

      if (friendUid == myUid) {
        _error = 'You cannot add yourself.';
        notifyListeners();
        return false;
      }

      // 2. Add to my friends subcollection
      await _db
          .collection('users')
          .doc(myUid)
          .collection('friends')
          .doc(friendUid)
          .set({
        'uid': friendUid,
        'name': friendData['name'] ?? 'Friend',
        'email': cleanEmail,
        'skinTone': friendData['skinTone'] ?? 5,
        'addedAt': FieldValue.serverTimestamp(),
      });

      await loadFriends(myUid);
      return true;
    } catch (e) {
      _error = 'Failed to add friend: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> removeFriend(String myUid, String friendUid) async {
    try {
      await _db
          .collection('users')
          .doc(myUid)
          .collection('friends')
          .doc(friendUid)
          .delete();
      _friends.removeWhere((f) => f.uid == friendUid);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove friend: $e';
      notifyListeners();
    }
  }

  List<FriendProgress> _allRegisteredUsers = [];
  bool _loadingAllUsers = false;

  List<FriendProgress> get allRegisteredUsers => _allRegisteredUsers;
  bool get loadingAllUsers => _loadingAllUsers;

  Future<void> loadAllAppUsers() async {
    _loadingAllUsers = true;
    notifyListeners();
    try {
      final usersSnap = await _db.collection('users').get();
      final List<FriendProgress> loaded = [];
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final uid = data['uid'] ?? doc.id;
        final name = data['name'] ?? 'User';
        final email = data['email'] ?? '';
        final skinTone = data['skinTone'] as int? ?? 5;
        
        final uvReadingsSnap = await _db
            .collection('users')
            .doc(uid)
            .collection('uv_readings')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .get();

        final todaySynthesized = uvReadingsSnap.docs.fold<double>(0.0, (acc, d) =>
            acc + ((d.data()['synthesizedIU'] ?? 0.0) as num).toDouble());

        loaded.add(FriendProgress(
          uid: uid,
          name: name,
          email: email,
          skinTone: skinTone,
          todaySynthesized: todaySynthesized,
          dailyTarget: 600.0,
        ));
      }
      _allRegisteredUsers = loaded;
    } catch (_) {} finally {
      _loadingAllUsers = false;
      notifyListeners();
    }
  }
}
