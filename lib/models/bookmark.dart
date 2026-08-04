import 'package:flutter/material.dart'; // For Duration

class Bookmark {
  final String id;
  final Duration timestamp;
  final int? pageNumber; // Optional page number for PDFs
  String name;
  final Color? color; // Optional color for the bookmark
  final String? mediaItemId; // Optional ID of the media item this bookmark belongs to

  Bookmark({
    required this.id,
    this.timestamp = Duration.zero,
    this.pageNumber,
    required this.name,
    this.color,
    this.mediaItemId,
  });

  // Convert Bookmark object to a JSON-compatible Map
  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.inMilliseconds, // Store as milliseconds
        'pageNumber': pageNumber,
        'name': name,
        'color': color?.toARGB32(), // Store color as int value
        'mediaItemId': mediaItemId,
      };

  // Create a Bookmark object from a JSON-compatible Map
  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        id: json['id'],
        timestamp: Duration(milliseconds: json['timestamp'] ?? 0),
        pageNumber: json['pageNumber'],
        name: json['name'],
        color: json['color'] != null ? Color(json['color']) : null,
        mediaItemId: json['mediaItemId'],
      );

  // copyWith method for immutably updating properties
  Bookmark copyWith({
    String? id,
    Duration? timestamp,
    int? pageNumber,
    String? name,
    Color? color,
    String? mediaItemId,
  }) {
    return Bookmark(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      pageNumber: pageNumber ?? this.pageNumber,
      name: name ?? this.name,
      color: color ?? this.color,
      mediaItemId: mediaItemId ?? this.mediaItemId,
    );
  }
}