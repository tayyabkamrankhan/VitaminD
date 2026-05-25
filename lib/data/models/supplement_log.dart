import 'package:cloud_firestore/cloud_firestore.dart';

class SupplementLog {
  final String id;
  final String userId;
  final DateTime date;
  final String type;    // 'supplement' | 'food'
  final String name;
  final double dosageIU;
  final String? notes;

  const SupplementLog({
    required this.id, required this.userId, required this.date,
    required this.type, required this.name, required this.dosageIU,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'userId': userId, 'date': Timestamp.fromDate(date),
    'type': type, 'name': name, 'dosageIU': dosageIU, 'notes': notes,
  };

  factory SupplementLog.fromMap(Map<String, dynamic> m) => SupplementLog(
    id: m['id'], userId: m['userId'],
    date: (m['date'] as Timestamp).toDate(),
    type: m['type'], name: m['name'],
    dosageIU: (m['dosageIU'] as num).toDouble(), notes: m['notes'],
  );
}
