import 'package:cloud_firestore/cloud_firestore.dart';

class UVSession {
  final String id;
  final String userId;
  final DateTime date;
  final double uvIndex;
  final double durationMinutes;
  final double synthesizedIU;
  final double bodyExposure;
  final int spf;
  final double cloudCover;
  final double temperatureC;
  final int skinToneUsed;

  const UVSession({
    required this.id, required this.userId, required this.date,
    required this.uvIndex, required this.durationMinutes,
    required this.synthesizedIU, required this.bodyExposure,
    this.spf = 0, this.cloudCover = 0, this.temperatureC = 30,
    required this.skinToneUsed,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'userId': userId, 'date': Timestamp.fromDate(date),
    'uvIndex': uvIndex, 'durationMinutes': durationMinutes,
    'synthesizedIU': synthesizedIU, 'bodyExposure': bodyExposure,
    'spf': spf, 'cloudCover': cloudCover, 'temperatureC': temperatureC,
    'skinToneUsed': skinToneUsed,
  };

  factory UVSession.fromMap(Map<String, dynamic> m) => UVSession(
    id: m['id'], userId: m['userId'],
    date: (m['date'] as Timestamp).toDate(),
    uvIndex: (m['uvIndex'] as num).toDouble(),
    durationMinutes: (m['durationMinutes'] as num).toDouble(),
    synthesizedIU: (m['synthesizedIU'] as num).toDouble(),
    bodyExposure: (m['bodyExposure'] as num).toDouble(),
    spf: m['spf'] ?? 0,
    cloudCover: (m['cloudCover'] as num?)?.toDouble() ?? 0,
    temperatureC: (m['temperatureC'] as num?)?.toDouble() ?? 30,
    skinToneUsed: m['skinToneUsed'] ?? 5,
  );
}
