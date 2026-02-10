import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class PremiumProvider with ChangeNotifier {
  bool _isPremium = false;
  bool _isLifetime = false;
  DateTime? _premiumExpiry;

  bool get isPremium => _isPremium;
  bool get isLifetime => _isLifetime;
  DateTime? get premiumExpiry => _premiumExpiry;

  PremiumProvider() {
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool('is_premium') ?? false;
    _isLifetime = prefs.getBool('is_lifetime') ?? false;
    final expiryString = prefs.getString('premium_expiry');
    if (expiryString != null) {
      _premiumExpiry = DateTime.parse(expiryString);
      // Check if premium has expired
      if (!_isLifetime && _premiumExpiry!.isBefore(DateTime.now())) {
        _isPremium = false;
        await prefs.setBool('is_premium', false);
      }
    }
    notifyListeners();
  }

  Future<void> activatePremium({bool isLifetime = false}) async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = true;
    _isLifetime = isLifetime;
    if (!isLifetime) {
      _premiumExpiry = DateTime.now().add(const Duration(days: 30));
      await prefs.setString('premium_expiry', _premiumExpiry!.toIso8601String());
    } else {
      _premiumExpiry = null;
    }
    await prefs.setBool('is_premium', true);
    await prefs.setBool('is_lifetime', isLifetime);
    notifyListeners();
  }

  Future<void> deactivatePremium() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = false;
    _isLifetime = false;
    _premiumExpiry = null;
    await prefs.setBool('is_premium', false);
    await prefs.setBool('is_lifetime', false);
    await prefs.remove('premium_expiry');
    notifyListeners();
  }

  // Check if user can create more groups
  bool canCreateGroup(int currentGroupCount) {
    if (_isPremium) return true;
    return currentGroupCount < AppConstants.maxFreeGroups;
  }

  // Check if user can add more members to group
  bool canAddMemberToGroup(int currentMemberCount) {
    if (_isPremium) return true;
    return currentMemberCount < AppConstants.maxFreeGroupMembers;
  }

  // Check if user can save more bills
  bool canSaveBill(int currentBillCount) {
    if (_isPremium) return true;
    return currentBillCount < AppConstants.maxFreeBillHistory;
  }
}
