import 'package:hive_flutter/hive_flutter.dart';
import '../../models/uv_reading.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';

/// Offline cache for UV sessions (30 days max), using Hive.
/// Syncs to Firestore when connection is restored.
class HiveDatasource {
  static Box? _uvBox;
  static Box? _settingsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _uvBox       = await Hive.openBox(AppConstants.hiveBoxUV);
    _settingsBox = await Hive.openBox(AppConstants.hiveBoxProfiles);
  }

  // ── UV Sessions ───────────────────────────────────────────────────────────

  Future<void> cacheUVSession(UVSession session) async {
    await _uvBox?.put(session.id, _sessionToMap(session));
    await _pruneOldSessions();
  }

  List<UVSession> getCachedSessions() {
    if (_uvBox == null) return [];
    return _uvBox!.values
        .map((v) => _sessionFromMap(Map<String, dynamic>.from(v as Map)))
        .toList();
  }

  Future<void> clearCachedSessions() => _uvBox?.clear() ?? Future.value();

  Future<void> _pruneOldSessions() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final toDelete = <String>[];
    _uvBox?.toMap().forEach((k, v) {
      final map = Map<String, dynamic>.from(v as Map);
      final date = DateTime.parse(map['date'] as String);
      if (date.isBefore(cutoff)) toDelete.add(k as String);
    });
    for (final k in toDelete) await _uvBox?.delete(k);
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<void> saveSetting(String key, dynamic value) =>
      _settingsBox?.put(key, value) ?? Future.value();

  dynamic getSetting(String key, {dynamic defaultValue}) =>
      _settingsBox?.get(key, defaultValue: defaultValue);

  // ── Serialisation helpers ─────────────────────────────────────────────────

  Map<String, dynamic> _sessionToMap(UVSession s) => {
    'id': s.id, 'userId': s.userId, 'date': s.date.toIso8601String(),
    'uvIndex': s.uvIndex, 'durationMinutes': s.durationMinutes,
    'synthesizedIU': s.synthesizedIU, 'bodyExposure': s.bodyExposure,
    'spf': s.spf, 'cloudCover': s.cloudCover,
    'temperatureC': s.temperatureC, 'skinToneUsed': s.skinToneUsed,
  };

  UVSession _sessionFromMap(Map<String, dynamic> m) => UVSession(
    id: m['id'], userId: m['userId'],
    date: DateTime.parse(m['date'] as String),
    uvIndex: (m['uvIndex'] as num).toDouble(),
    durationMinutes: (m['durationMinutes'] as num).toDouble(),
    synthesizedIU: (m['synthesizedIU'] as num).toDouble(),
    bodyExposure: (m['bodyExposure'] as num).toDouble(),
    spf: m['spf'] ?? 0, cloudCover: (m['cloudCover'] as num?)?.toDouble() ?? 0,
    temperatureC: (m['temperatureC'] as num?)?.toDouble() ?? 30,
    skinToneUsed: m['skinToneUsed'] ?? 5,
  );
}
