import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyMember {
  final String id;
  final String ownerId;
  final String name;
  final int age;
  final String gender;
  final int skinTone;
  final String relation; // 'child' | 'parent' | 'spouse' | 'other'

  const FamilyMember({
    required this.id, required this.ownerId, required this.name,
    required this.age, required this.gender, required this.skinTone,
    required this.relation,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'ownerId': ownerId, 'name': name,
    'age': age, 'gender': gender, 'skinTone': skinTone, 'relation': relation,
  };

  factory FamilyMember.fromMap(Map<String, dynamic> m) => FamilyMember(
    id: m['id'], ownerId: m['ownerId'], name: m['name'],
    age: m['age'], gender: m['gender'], skinTone: m['skinTone'],
    relation: m['relation'],
  );
}
