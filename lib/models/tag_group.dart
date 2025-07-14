/// Represents a group of tags, allowing for hierarchical or categorized tagging.
///
/// For example, a TagGroup could be 'Difficulty' with tags like 'Easy', 'Medium', 'Hard',
/// or 'Genre' with tags like 'Classical', 'Jazz', 'Folk'.
class TagGroup {
  String id; // Unique ID for the tag group
  String name; // Name of the tag group (e.g., 'Difficulty', 'Genre')
  List<String> tags; // List of tags belonging to this group
  int? color; // Optional color associated with the tag group (stored as ARGB integer)

  /// Constructor for the TagGroup class.
  TagGroup({required this.id, required this.name, this.tags = const [], this.color});

  /// Converts a [TagGroup] object into a JSON-compatible Map.
  ///
  /// This method is used for serializing the object for storage in a database
  /// or for export.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tags': tags, // List of strings is directly supported by JSON encoding
        'color': color,
      };

  /// Creates a [TagGroup] object from a JSON-compatible Map.
  ///
  /// This factory constructor is used for deserializing data retrieved from a
  /// database or imported from a file.
  factory TagGroup.fromJson(Map<String, dynamic> json) => TagGroup(
        id: json['id'],
        name: json['name'],
        tags: List<String>.from(json['tags'] ?? []), // Convert dynamic list to List<String>
        color: json['color'],
      );

  /// Creates a copy of this [TagGroup] object with optional new values.
  ///
  /// This method is useful for immutably updating properties of a tag group.
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
