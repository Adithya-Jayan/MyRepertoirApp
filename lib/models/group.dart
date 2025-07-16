/// Represents a custom organizational category for music pieces.
///
/// Users can create groups to categorize their music repertoire,
/// such as 'Classical', 'Jazz', 'Practice Pieces', etc.
class Group {
  /// Unique identifier for the group.
  /// For user-created groups, this is typically a UUID.
  /// For special groups like "All" and "Ungrouped", this is a hardcoded string.
  String id;

  /// The display name of the group (e.g., 'Classical', 'Jazz').
  String name;

  /// The integer value that determines the group's position in ordered lists.
  /// A lower value will appear earlier in the list.
  int order;

  /// A boolean flag to determine if the group should be hidden from the UI.
  /// This allows users to temporarily hide groups without deleting them.
  bool isHidden;

  /// Constructor for the Group class.
  Group({
    required this.id,
    required this.name,
    required this.order,
    this.isHidden = false,
  });

  /// Converts a [Group] object into a JSON-compatible Map.
  ///
  /// This method is used for serializing the object for storage in a database.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'order': order,
        'isHidden': isHidden ? 1 : 0, // Convert boolean to integer (1 for true, 0 for false)
      };

  /// Creates a [Group] object from a JSON-compatible Map.
  ///
  /// This factory constructor is used for deserializing data retrieved from a
  /// database. It handles the conversion from integer back to boolean for `isHidden`.
  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'],
        name: json['name'],
        order: json['order'],
        isHidden: (json['isHidden'] as int?) == 1, // Convert integer to boolean, defaulting to false if null
      );

  /// Creates a copy of this [Group] object with optional new values.
  ///
  /// This method is useful for creating a modified instance of a group
  /// without altering the original object, promoting immutability.
  Group copyWith({
    String? id,
    String? name,
    int? order,
    bool? isHidden,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      isHidden: isHidden ?? this.isHidden,
    );
  }
}
