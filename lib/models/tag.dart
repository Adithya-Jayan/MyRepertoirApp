class Tag {
  String id;
  String name;
  int? color;  // Store as int for Color value
  String? type;

  Tag({required this.id, required this.name, this.color, this.type});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'type': type,
      };

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
        id: json['id'],
        name: json['name'],
        color: json['color'],
        type: json['type'],
      );
}
