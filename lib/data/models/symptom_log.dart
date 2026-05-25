import 'package:cloud_firestore/cloud_firestore.dart';

class SymptomLog {
  final String id;
  final String userId;
  final DateTime date;
  final List<String> symptoms;
  final int severity; // 1–5
  final String? aiRecommendation;

  static const List<String> allSymptoms = [
    'Fatigue', 'Bone pain', 'Muscle weakness', 'Depression',
    'Hair loss', 'Frequent illness', 'Back pain', 'Brain fog',
  ];

  const SymptomLog({
    required this.id, required this.userId, required this.date,
    required this.symptoms, required this.severity, this.aiRecommendation,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'userId': userId, 'date': Timestamp.fromDate(date),
    'symptoms': symptoms, 'severity': severity,
    'aiRecommendation': aiRecommendation,
  };

  factory SymptomLog.fromMap(Map<String, dynamic> m) => SymptomLog(
    id: m['id'], userId: m['userId'],
    date: (m['date'] as Timestamp).toDate(),
    symptoms: List<String>.from(m['symptoms']),
    severity: m['severity'], aiRecommendation: m['aiRecommendation'],
  );
}
