class BillItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final List<String> assignedPeople; // Person names

  BillItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    required this.assignedPeople,
  });

  double get totalPrice => price * quantity;

  BillItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    List<String>? assignedPeople,
  }) {
    return BillItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      assignedPeople: assignedPeople ?? this.assignedPeople,
    );
  }
}
