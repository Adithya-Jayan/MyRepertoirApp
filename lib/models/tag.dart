/// Represents a single tag that can be applied to a music piece.
///
/// Tags provide a flexible way to categorize and filter music pieces
/// beyond predefined groups.
class Tag {
  String id; // Unique ID for the tag
  String name; // Name of the tag (e.g., 'Baroque', 'Beginner')
  int? color; // Optional color associated with the tag (stored as an integer representation of Color value)
  String? type; // Optional type or category for the tag (e.g., 'Genre', 'Difficulty')

  /// Constructor for the Tag class.
  Tag({required this.id, required this.name, this.color, this.type});

  /// Converts a [Tag] object into a JSON-compatible Map.
  ///
  /// This method is used for serializing the object for storage in a database
  /// or for export.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'type': type,
      };

  /// Creates a [Tag] object from a JSON-compatible Map.
  ///
  /// This factory constructor is used for deserializing data retrieved from a
  /// database or imported from a file.
  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
        id: json['id'],
        name: json['name'],
        color: json['color'],
        type: json['type'],
      );
}
