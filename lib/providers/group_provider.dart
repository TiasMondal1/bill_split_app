import 'package:flutter/foundation.dart';
import '../models/group.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import 'premium_provider.dart';

class GroupProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final PremiumProvider _premiumProvider;

  List<Group> _groups = [];
  bool _isLoading = false;

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;

  GroupProvider(this._premiumProvider) {
    loadGroups();
  }

  Future<void> loadGroups() async {
    _isLoading = true;
    notifyListeners();

    try {
      _groups = await _db.getAllGroups();
    } catch (e) {
      debugPrint('Error loading groups: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGroup(String name, List<String> members) async {
    if (!_premiumProvider.canCreateGroup(_groups.length)) {
      return false;
    }

    for (var member in members) {
      if (!_premiumProvider.canAddMemberToGroup(members.length)) {
        return false;
      }
    }

    try {
      final group = Group(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        members: members,
        createdAt: DateTime.now(),
      );

      await _db.insertGroup(group);
      await loadGroups();
      return true;
    } catch (e) {
      debugPrint('Error creating group: $e');
      return false;
    }
  }

  Future<bool> updateGroup(Group group) async {
    // Check member limit for non-premium
    if (!_premiumProvider.isPremium &&
        group.members.length > AppConstants.maxFreeGroupMembers) {
      return false;
    }

    try {
      await _db.updateGroup(group);
      await loadGroups();
      return true;
    } catch (e) {
      debugPrint('Error updating group: $e');
      return false;
    }
  }

  Future<void> deleteGroup(String id) async {
    try {
      await _db.deleteGroup(id);
      await loadGroups();
    } catch (e) {
      debugPrint('Error deleting group: $e');
    }
  }

  Group? getGroupById(String id) {
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }
}
