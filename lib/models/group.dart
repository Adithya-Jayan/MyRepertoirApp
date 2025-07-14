/// Represents a custom organizational category for music pieces.
///
/// Users can create groups to categorize their music repertoire,
/// such as 'Classical', 'Jazz', 'Practice Pieces', etc.
class Group {
  String id; // Unique ID for the group
  String name; // Name of the group (e.g., 'Classical', 'Jazz')
  int order; // For custom ordering of groups in the UI
  bool isDefault; // Flag to identify the 'Default Group' (e.g., for pieces not assigned to any custom group)

  /// Constructor for the Group class.
  Group({
    required this.id,
    required this.name,
    required this.order,
    this.isDefault = false,
  });

  /// Converts a [Group] object into a JSON-compatible Map.
  ///
  /// This method is used for serializing the object for storage in a database
  /// or for export.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'order': order,
        'isDefault': isDefault ? 1 : 0, // Convert boolean to integer (0 or 1)
      };

  /// Creates a [Group] object from a JSON-compatible Map.
  ///
  /// This factory constructor is used for deserializing data retrieved from a
  /// database or imported from a file.
  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'],
        name: json['name'],
        order: json['order'],
        isDefault: (json['isDefault'] as int) == 1, // Convert integer (0 or 1) to boolean
      );

  /// Creates a copy of this [Group] object with optional new values.
  ///
  /// This method is useful for immutably updating properties of a group.
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