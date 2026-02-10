import '../models/bill_item.dart';
import '../utils/helpers.dart';

class CalculationService {
  /// Calculate split amounts for each person
  /// Returns a map of person name to their total amount
  static Map<String, double> calculateSplit({
    required List<BillItem> items,
    required double tax,
    required double tip,
    required List<String> people,
  }) {
    Map<String, double> totals = {for (var p in people) p: 0.0};
    double subtotal = 0.0;

    // Calculate per-person item costs
    for (var item in items) {
      double itemTotal = item.totalPrice;
      subtotal += itemTotal;

      if (item.assignedPeople.isEmpty) {
        // If no one assigned, skip this item
        continue;
      }

      double perPersonCost = itemTotal / item.assignedPeople.length;

      for (var person in item.assignedPeople) {
        totals[person] = (totals[person] ?? 0.0) + perPersonCost;
      }
    }

    // Distribute tax and tip proportionally
    if (subtotal > 0) {
      for (var person in people) {
        double personSubtotal = totals[person] ?? 0.0;
        double proportion = personSubtotal / subtotal;
        double taxShare = Helpers.roundToTwoDecimals(tax * proportion);
        double tipShare = Helpers.roundToTwoDecimals(tip * proportion);
        totals[person] = Helpers.roundToTwoDecimals(
          personSubtotal + taxShare + tipShare,
        );
      }
    }

    return totals;
  }

  /// Calculate subtotal from items
  static double calculateSubtotal(List<BillItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Calculate tax amount (percentage or fixed)
  static double calculateTax({
    required double subtotal,
    required double taxRate, // Percentage (e.g., 8.5 for 8.5%)
    bool isPercentage = true,
  }) {
    if (isPercentage) {
      return Helpers.roundToTwoDecimals(subtotal * (taxRate / 100));
    } else {
      return Helpers.roundToTwoDecimals(taxRate);
    }
  }

  /// Calculate tip amount (percentage or fixed)
  static double calculateTip({
    required double subtotal,
    required double tipRate, // Percentage (e.g., 18 for 18%) or fixed amount
    bool isPercentage = true,
  }) {
    if (isPercentage) {
      return Helpers.roundToTwoDecimals(subtotal * (tipRate / 100));
    } else {
      return Helpers.roundToTwoDecimals(tipRate);
    }
  }

  /// Calculate total (subtotal + tax + tip)
  static double calculateTotal({
    required double subtotal,
    required double tax,
    required double tip,
  }) {
    return Helpers.roundToTwoDecimals(subtotal + tax + tip);
  }
}
