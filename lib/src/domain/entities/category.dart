class Category {
  final int? id;
  final String name;
  final String color; // Couleur hex (ex: "#FF5722")

  const Category({
    this.id,
    required this.name,
    required this.color,
  });

  Category copyWith({
    int? id,
    String? name,
    String? color,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          color == other.color;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ color.hashCode;
}