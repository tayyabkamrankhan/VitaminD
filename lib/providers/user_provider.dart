import 'package:flutter/foundation.dart';
import '../data/models/models.dart';
import '../data/repositories/health_repository.dart';

class UserProvider extends ChangeNotifier {
  List<FamilyMember> _familyMembers = [];
  String? _activeMemberId; // null = main user

  List<FamilyMember> get familyMembers  => _familyMembers;
  String?            get activeMemberId => _activeMemberId;
  bool               get isViewingMain  => _activeMemberId == null;

  FamilyMember? get activeMember =>
      _familyMembers.where((m) => m.id == _activeMemberId).firstOrNull;

  void switchToMember(String? id) {
    _activeMemberId = id;
    notifyListeners();
  }

  Future<void> loadFamily(HealthRepository repo, String ownerId) async {
    _familyMembers = await repo.getFamilyMembers(ownerId);
    notifyListeners();
  }

  Future<void> addMember(HealthRepository repo, FamilyMember member) async {
    await repo.saveFamilyMember(member);
    _familyMembers.add(member);
    notifyListeners();
  }

  Future<void> removeMember(HealthRepository repo, String ownerId, String memberId) async {
    await repo.deleteFamilyMember(ownerId, memberId);
    _familyMembers.removeWhere((m) => m.id == memberId);
    if (_activeMemberId == memberId) _activeMemberId = null;
    notifyListeners();
  }
}
