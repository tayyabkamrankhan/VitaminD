import 'package:cloud_firestore/cloud_firestore.dart';

/// Low-level Firestore access. Repositories call this; nothing else should.
class FirestoreDatasource {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Generic helpers ───────────────────────────────────────────────────────

  Future<DocumentSnapshot> getDoc(String path) => _db.doc(path).get();

  Future<void> setDoc(String path, Map<String, dynamic> data) =>
      _db.doc(path).set(data);

  Future<void> updateDoc(String path, Map<String, dynamic> data) =>
      _db.doc(path).update(data);

  Future<void> deleteDoc(String path) => _db.doc(path).delete();

  Future<QuerySnapshot> queryCollection(
    String path, {
    String? orderBy,
    bool descending = false,
    Object? whereField,
    Object? isGreaterThanOrEqualTo,
    int? limit,
  }) {
    Query q = _db.collection(path);
    if (whereField != null && isGreaterThanOrEqualTo != null) {
      q = q.where(whereField as String,
          isGreaterThanOrEqualTo: isGreaterThanOrEqualTo);
    }
    if (orderBy != null) q = q.orderBy(orderBy, descending: descending);
    if (limit != null) q = q.limit(limit);
    return q.get();
  }

  Stream<DocumentSnapshot> docStream(String path) => _db.doc(path).snapshots();

  CollectionReference collection(String path) => _db.collection(path);
}
