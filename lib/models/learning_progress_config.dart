import 'dart:convert';

enum LearningProgressType { percentage, count, stages }

class LearningProgressConfig {
  final LearningProgressType type;
  double current; // Use double for flexibility (0-100 for %, 0-max for count/stages)
  int maxCount;
  List<String> stages;

  LearningProgressConfig({
    required this.type,
    this.current = 0.0,
    this.maxCount = 10,
    this.stages = const [],
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'current': current,
    'maxCount': maxCount,
    'stages': stages,
  };

  factory LearningProgressConfig.fromJson(Map<String, dynamic> json) {
    return LearningProgressConfig(
      type: LearningProgressType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LearningProgressType.percentage,
      ),
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      maxCount: json['maxCount'] ?? 10,
      stages: List<String>.from(json['stages'] ?? []),
    );
  }
  
  static String encode(LearningProgressConfig config) => jsonEncode(config.toJson());
  
  static LearningProgressConfig decode(String jsonString) {
      if (jsonString.isEmpty) return LearningProgressConfig(type: LearningProgressType.percentage);
      try {
        return LearningProgressConfig.fromJson(jsonDecode(jsonString));
      } catch (e) {
         // Fallback
         return LearningProgressConfig(type: LearningProgressType.percentage);
      }
  }

  LearningProgressConfig copyWith({
    LearningProgressType? type,
    double? current,
    int? maxCount,
    List<String>? stages,
  }) {
    return LearningProgressConfig(
      type: type ?? this.type,
      current: current ?? this.current,
      maxCount: maxCount ?? this.maxCount,
      stages: stages ?? this.stages,
    );
  }
}
