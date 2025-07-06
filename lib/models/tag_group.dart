class TagGroup {
  String id;
  String name;
  List<String> tags;
  int? color; // Store color as ARGB int

  TagGroup({required this.id, required this.name, this.tags = const [], this.color});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tags': tags,
        'color': color,
      };

  factory TagGroup.fromJson(Map<String, dynamic> json) => TagGroup(
        id: json['id'],
        name: json['name'],
        tags: List<String>.from(json['tags'] ?? []),
        color: json['color'],
      );

  TagGroup copyWith({
    String? id,
    String? name,
    List<String>? tags,
    int? color,
  }) {
    return TagGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      tags: tags ?? this.tags,
      color: color ?? this.color,
    );
  }
}
