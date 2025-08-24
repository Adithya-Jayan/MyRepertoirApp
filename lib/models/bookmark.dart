import 'package:flutter/material.dart'; // For Duration

class Bookmark {
  final String id;
  final Duration timestamp;
  String name;
  final Color? color; // Optional color for the bookmark

  Bookmark({
    required this.id,
    required this.timestamp,
    required this.name,
    this.color,
  });

  // Convert Bookmark object to a JSON-compatible Map
  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.inMilliseconds, // Store as milliseconds
        'name': name,
        'color': color?.value, // Store color as int value
      };

  // Create a Bookmark object from a JSON-compatible Map
  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        id: json['id'],
        timestamp: Duration(milliseconds: json['timestamp']),
        name: json['name'],
        color: json['color'] != null ? Color(json['color']) : null,
      );

  // copyWith method for immutably updating properties
  Bookmark copyWith({
    String? id,
    Duration? timestamp,
    String? name,
    Color? color,
  }) {
    return Bookmark(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }
}