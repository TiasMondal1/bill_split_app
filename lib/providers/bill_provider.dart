import 'package:flutter/foundation.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../services/database_service.dart';
import '../services/calculation_service.dart';
import 'premium_provider.dart';

class BillProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final PremiumProvider _premiumProvider;

  List<Bill> _recentBills = [];
  Bill? _currentBill;
  bool _isLoading = false;

  List<Bill> get recentBills => _recentBills;
  Bill? get currentBill => _currentBill;
  bool get isLoading => _isLoading;

  BillProvider(this._premiumProvider) {
    loadRecentBills();
  }

  Future<void> loadRecentBills({int limit = 5}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _recentBills = await _db.getAllBills(limit: limit);
    } catch (e) {
      debugPrint('Error loading recent bills: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Bill>> loadAllBills() async {
    _isLoading = true;
    notifyListeners();

    try {
      _recentBills = await _db.getAllBills();
      return _recentBills;
    } catch (e) {
      debugPrint('Error loading all bills: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCurrentBill(Bill? bill) {
    _currentBill = bill;
    notifyListeners();
  }

  Future<Bill> calculateBill({
    required String restaurantName,
    required List<BillItem> items,
    required double taxRate,
    required bool taxIsPercentage,
    required double tipRate,
    required bool tipIsPercentage,
    String? groupId,
  }) async {
    // Get all people from items
    final allPeople = <String>{};
    for (var item in items) {
      allPeople.addAll(item.assignedPeople);
    }

    if (allPeople.isEmpty) {
      throw Exception('At least one person must be assigned to items');
    }

    final people = allPeople.toList();

    // Calculate subtotal
    final subtotal = CalculationService.calculateSubtotal(items);

    // Calculate tax and tip
    final calculatedTax = CalculationService.calculateTax(
      subtotal: subtotal,
      taxRate: taxRate,
      isPercentage: taxIsPercentage,
    );

    final calculatedTip = CalculationService.calculateTip(
      subtotal: subtotal,
      tipRate: tipRate,
      isPercentage: tipIsPercentage,
    );

    // Calculate person totals
    final personTotals = CalculationService.calculateSplit(
      items: items,
      tax: calculatedTax,
      tip: calculatedTip,
      people: people,
    );

    // Create bill
    final bill = Bill(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      restaurantName: restaurantName,
      date: DateTime.now(),
      items: items,
      subtotal: subtotal,
      tax: calculatedTax,
      tip: calculatedTip,
      total: CalculationService.calculateTotal(
        subtotal: subtotal,
        tax: calculatedTax,
        tip: calculatedTip,
      ),
      groupId: groupId,
      personTotals: personTotals,
      paidStatus: {for (var p in people) p: false},
    );

    _currentBill = bill;
    notifyListeners();

    return bill;
  }

  Future<bool> saveBillToHistory(Bill bill) async {
    // Check if user can save more bills
    final allBills = await _db.getAllBills();
    if (!_premiumProvider.canSaveBill(allBills.length) &&
        !allBills.any((b) => b.id == bill.id)) {
      // If bill already exists, allow update
      return false;
    }

    try {
      await _db.insertBill(bill);
      await loadRecentBills();
      return true;
    } catch (e) {
      debugPrint('Error saving bill: $e');
      return false;
    }
  }

  Future<Bill?> getBillById(String id) async {
    try {
      return await _db.getBillById(id);
    } catch (e) {
      debugPrint('Error getting bill: $e');
      return null;
    }
  }

  Future<void> deleteBill(String id) async {
    try {
      await _db.deleteBill(id);
      await loadRecentBills();
    } catch (e) {
      debugPrint('Error deleting bill: $e');
    }
  }

  Future<void> updateBillPaidStatus(String billId, String personName, bool paid) async {
    try {
      final bill = await _db.getBillById(billId);
      if (bill != null) {
        final updatedPaidStatus = Map<String, bool>.from(bill.paidStatus);
        updatedPaidStatus[personName] = paid;

        final updatedBill = bill.copyWith(paidStatus: updatedPaidStatus);
        await _db.insertBill(updatedBill); // Insert updates the bill
        await loadRecentBills();
        if (_currentBill?.id == billId) {
          _currentBill = updatedBill;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating paid status: $e');
    }
  }

  Future<void> clearAllBills() async {
    try {
      await _db.clearAllBills();
      _recentBills = [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing bills: $e');
    }
  }
}
