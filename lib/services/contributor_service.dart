import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:repertoire/models/contributor.dart';

Future<List<Contributor>> loadContributors() async {
  final jsonString = await rootBundle.loadString('assets/contributors.json');
  final List<dynamic> jsonData = jsonDecode(jsonString);
  return jsonData.map((item) => Contributor.fromJson(item)).toList();
}