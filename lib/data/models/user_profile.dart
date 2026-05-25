import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final int age;
  final String gender;
  final int skinTone;
  final double weightKg;
  final String city;
  final List<String> healthConditions;
  final bool darkMode;
  final bool notificationsEnabled;
  final DateTime createdAt;

  const UserProfile({
    required this.uid, required this.name, required this.email,
    required this.age, required this.gender, required this.skinTone,
    required this.weightKg, required this.city,
    this.healthConditions = const [],
    this.darkMode = true, this.notificationsEnabled = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid, 'name': name, 'email': email, 'age': age,
    'gender': gender, 'skinTone': skinTone, 'weightKg': weightKg,
    'city': city, 'healthConditions': healthConditions,
    'darkMode': darkMode, 'notificationsEnabled': notificationsEnabled,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    uid: m['uid'], name: m['name'], email: m['email'],
    age: m['age'], gender: m['gender'], skinTone: m['skinTone'],
    weightKg: (m['weightKg'] as num).toDouble(), city: m['city'],
    healthConditions: List<String>.from(m['healthConditions'] ?? []),
    darkMode: m['darkMode'] ?? true,
    notificationsEnabled: m['notificationsEnabled'] ?? true,
    createdAt: (m['createdAt'] as Timestamp).toDate(),
  );

  UserProfile copyWith({
    String? name, int? age, String? gender, int? skinTone,
    double? weightKg, String? city, List<String>? healthConditions,
    bool? darkMode, bool? notificationsEnabled,
  }) => UserProfile(
    uid: uid, email: email, createdAt: createdAt,
    name: name ?? this.name, age: age ?? this.age,
    gender: gender ?? this.gender, skinTone: skinTone ?? this.skinTone,
    weightKg: weightKg ?? this.weightKg, city: city ?? this.city,
    healthConditions: healthConditions ?? this.healthConditions,
    darkMode: darkMode ?? this.darkMode,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
  );
}
