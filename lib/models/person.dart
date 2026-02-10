class Person {
  final String name;
  final int colorValue; // Material color value

  Person({
    required this.name,
    required this.colorValue,
  });

  Person copyWith({
    String? name,
    int? colorValue,
  }) {
    return Person(
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}
