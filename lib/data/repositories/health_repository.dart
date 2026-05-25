import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class HealthRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ── UV Sessions ─────────────────────────────────────────────────────────

  Future<void> saveUVSession(UVSession session) async {
    await _db
        .collection(AppConstants.colUsers)
        .doc(session.userId)
        .collection(AppConstants.colUVReadings)
        .doc(session.id)
        .set(session.toMap());
  }

  Future<List<UVSession>> getUVSessions(String userId, {int days = 7}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final snap = await _db
        .collection(AppConstants.colUsers)
        .doc(userId)
        .collection(AppConstants.colUVReadings)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((d) => UVSession.fromMap(d.data())).toList();
  }

  Future<double> getTodaySynthesized(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final snap = await _db
        .collection(AppConstants.colUsers)
        .doc(userId)
        .collection(AppConstants.colUVReadings)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();
    return snap.docs.fold<double>(0.0, (acc, d) =>
      acc + (d.data()['synthesizedIU'] as num).toDouble());
  }

  // ── Supplements & Diet ──────────────────────────────────────────────────

  Future<void> logSupplement(SupplementLog log) async {
    await _db
        .collection(AppConstants.colUsers)
        .doc(log.userId)
        .collection(AppConstants.colSupplements)
        .doc(log.id)
        .set(log.toMap());
  }

  Future<void> deleteSupplement(String userId, String supplementId) async {
    await _db
        .collection(AppConstants.colUsers)
        .doc(userId)
        .collection(AppConstants.colSupplements)
        .doc(supplementId)
        .delete();
  }

  Future<List<SupplementLog>> getTodaySupplements(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final snap = await _db
        .collection(AppConstants.colUsers)
        .doc(userId)
        .collection(AppConstants.colSupplements)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();
    return snap.docs.map((d) => SupplementLog.fromMap(d.data())).toList();
  }

  SupplementLog makeSupplementLog({
    required String userId,
    required String type,
    required String name,
    required double dosageIU,
    String? notes,
  }) => SupplementLog(
    id: _uuid.v4(), userId: userId, date: DateTime.now(),
    type: type, name: name, dosageIU: dosageIU, notes: notes,
  );

  // ── Symptoms ────────────────────────────────────────────────────────────

  Future<void> logSymptoms(SymptomLog log) async {
    await _db
        .collection(AppConstants.colUsers)
        .doc(log.userId)
        .collection(AppConstants.colSymptoms)
        .doc(log.id)
        .set(log.toMap());
  }

  Future<List<SymptomLog>> getRecentSymptoms(String userId, {int days = 30}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final snap = await _db
        .collection(AppConstants.colUsers)
        .doc(userId)
        .collection(AppConstants.colSymptoms)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((d) => SymptomLog.fromMap(d.data())).toList();
  }

  SymptomLog makeSymptomLog({
    required String userId,
    required List<String> symptoms,
    required int severity,
    String? aiRecommendation,
  }) => SymptomLog(
    id: _uuid.v4(), userId: userId, date: DateTime.now(),
    symptoms: symptoms, severity: severity,
    aiRecommendation: aiRecommendation,
  );

  // ── Family Members ──────────────────────────────────────────────────────

  Future<void> saveFamilyMember(FamilyMember member) async {
    await _db
        .collection(AppConstants.colUsers)
        .doc(member.ownerId)
        .collection(AppConstants.colFamily)
        .doc(member.id)
        .set(member.toMap());
  }

  Future<List<FamilyMember>> getFamilyMembers(String ownerId) async {
    final snap = await _db
        .collection(AppConstants.colUsers)
        .doc(ownerId)
        .collection(AppConstants.colFamily)
        .get();
    return snap.docs.map((d) => FamilyMember.fromMap(d.data())).toList();
  }

  Future<void> deleteFamilyMember(String ownerId, String memberId) async {
    await _db
        .collection(AppConstants.colUsers)
        .doc(ownerId)
        .collection(AppConstants.colFamily)
        .doc(memberId)
        .delete();
  }

  UVSession makeUVSession({
    required String userId,
    required double uvIndex,
    required double durationMinutes,
    required double synthesizedIU,
    required double bodyExposure,
    required int skinToneUsed,
    int spf = 0,
    double cloudCover = 0,
    double temperatureC = 30,
  }) => UVSession(
    id: _uuid.v4(), userId: userId, date: DateTime.now(),
    uvIndex: uvIndex, durationMinutes: durationMinutes,
    synthesizedIU: synthesizedIU, bodyExposure: bodyExposure,
    skinToneUsed: skinToneUsed, spf: spf,
    cloudCover: cloudCover, temperatureC: temperatureC,
  );
}
