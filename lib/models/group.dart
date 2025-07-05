class Group {
  String id; // Unique ID for the group
  String name;
  int order; // For custom ordering
  bool isDefault; // To identify the 'Default Group'
  // Add other properties like icon, color if needed for UI

  Group({
    required this.id,
    required this.name,
    required this.order,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'order': order,
        'isDefault': isDefault ? 1 : 0,
      };

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'],
        name: json['name'],
        order: json['order'],
        isDefault: (json['isDefault'] as int) == 1,
      );

  Group copyWith({
    String? id,
    String? name,
    int? order,
    bool? isDefault,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}