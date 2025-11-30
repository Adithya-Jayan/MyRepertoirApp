import 'package:flutter/material.dart';

class PracticeStage {
  String id;
  String name;
  int colorValue;
  int holdDays;
  int transitionDays;

  PracticeStage({
    required this.id,
    required this.name,
    required this.colorValue,
    this.holdDays = 0,
    this.transitionDays = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'holdDays': holdDays,
        'transitionDays': transitionDays,
      };

  factory PracticeStage.fromJson(Map<String, dynamic> json) => PracticeStage(
        id: json['id'],
        name: json['name'],
        colorValue: json['colorValue'],
        holdDays: json['holdDays'] ?? 0,
        transitionDays: json['transitionDays'] ?? 0,
      );
      
  Color get color => Color(colorValue);
}
