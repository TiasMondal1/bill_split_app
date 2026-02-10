class Group {
  final String id;
  final String name;
  final List<String> members;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.members,
    required this.createdAt,
  });

  Group copyWith({
    String? id,
    String? name,
    List<String>? members,
    DateTime? createdAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
