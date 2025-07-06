class TagGroup {
  String id;
  String name;
  List<String> tags;

  TagGroup({required this.id, required this.name, this.tags = const []});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tags': tags,
      };

  factory TagGroup.fromJson(Map<String, dynamic> json) => TagGroup(
        id: json['id'],
        name: json['name'],
        tags: List<String>.from(json['tags'] ?? []),
      );

  TagGroup copyWith({
    String? id,
    String? name,
    List<String>? tags,
  }) {
    return TagGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      tags: tags ?? this.tags,
    );
  }
}
