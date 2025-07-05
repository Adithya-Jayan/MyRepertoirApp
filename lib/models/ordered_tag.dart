class OrderedTag {
  String id;
  String name;
  List<String> tags;

  OrderedTag({required this.id, required this.name, this.tags = const []});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tags': tags,
      };

  factory OrderedTag.fromJson(Map<String, dynamic> json) => OrderedTag(
        id: json['id'],
        name: json['name'],
        tags: List<String>.from(json['tags'] ?? []),
      );

  OrderedTag copyWith({
    String? id,
    String? name,
    List<String>? tags,
  }) {
    return OrderedTag(
      id: id ?? this.id,
      name: name ?? this.name,
      tags: tags ?? this.tags,
    );
  }
}
