import 'dart:convert';

/// Configuration for PDF viewing experience.
class PdfConfig {
  final bool autoScrollEnabled;
  final double defaultSpeed; // Pixels per second or similar unit

  const PdfConfig({
    this.autoScrollEnabled = false,
    this.defaultSpeed = 1.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'autoScrollEnabled': autoScrollEnabled,
      'defaultSpeed': defaultSpeed,
    };
  }

  factory PdfConfig.fromMap(Map<String, dynamic> map) {
    return PdfConfig(
      autoScrollEnabled: map['autoScrollEnabled'] ?? false,
      defaultSpeed: (map['defaultSpeed'] ?? 1.0).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory PdfConfig.fromJson(String source) {
    try {
      return PdfConfig.fromMap(json.decode(source));
    } catch (_) {
      return PdfConfig();
    }
  }

  PdfConfig copyWith({
    bool? autoScrollEnabled,
    double? defaultSpeed,
  }) {
    return PdfConfig(
      autoScrollEnabled: autoScrollEnabled ?? this.autoScrollEnabled,
      defaultSpeed: defaultSpeed ?? this.defaultSpeed,
    );
  }
}
