import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:repertoire/models/contributor.dart';

/// Loads contributor data from the `assets/contributors.json` file.
///
/// This function reads the JSON file, decodes it, and maps the data
/// to a list of [Contributor] objects.
Future<List<Contributor>> loadContributors() async {
  final jsonString = await rootBundle.loadString('assets/contributors.json'); // Load the JSON string from assets.
  final List<dynamic> jsonData = jsonDecode(jsonString); // Decode the JSON string into a list of dynamic objects.
  return jsonData.map((item) => Contributor.fromJson(item)).toList(); // Convert each JSON object to a Contributor object.
}