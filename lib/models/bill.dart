import 'bill_item.dart';

class Bill {
  final String id;
  final String restaurantName;
  final DateTime date;
  final List<BillItem> items;
  final double subtotal;
  final double tax;
  final double tip;
  final double total;
  final String? groupId;
  final Map<String, double> personTotals; // Person name -> total amount
  final Map<String, bool> paidStatus; // Person name -> paid status

  Bill({
    required this.id,
    required this.restaurantName,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.tip,
    required this.total,
    this.groupId,
    required this.personTotals,
    required this.paidStatus,
  });

  List<String> get allPeople {
    final people = <String>{};
    for (var item in items) {
      people.addAll(item.assignedPeople);
    }
    return people.toList();
  }

  Bill copyWith({
    String? id,
    String? restaurantName,
    DateTime? date,
    List<BillItem>? items,
    double? subtotal,
    double? tax,
    double? tip,
    double? total,
    String? groupId,
    Map<String, double>? personTotals,
    Map<String, bool>? paidStatus,
  }) {
    return Bill(
      id: id ?? this.id,
      restaurantName: restaurantName ?? this.restaurantName,
      date: date ?? this.date,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      tip: tip ?? this.tip,
      total: total ?? this.total,
      groupId: groupId ?? this.groupId,
      personTotals: personTotals ?? this.personTotals,
      paidStatus: paidStatus ?? this.paidStatus,
    );
  }
}
