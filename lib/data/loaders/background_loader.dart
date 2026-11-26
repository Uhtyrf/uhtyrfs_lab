import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/background_data.dart';

Future<List<BackgroundData>>? _backgroundsCache;

Future<List<BackgroundData>> loadBackgrounds() {
  return _backgroundsCache ??= _loadBackgroundsFromAsset();
}

Future<List<BackgroundData>> _loadBackgroundsFromAsset() async {
  final jsonString = await rootBundle.loadString(
    'assets/data/backgrounds.json',
  );
  final Map<String, dynamic> jsonData = jsonDecode(jsonString);
  final List<dynamic> backgroundList = jsonData['backgrounds'];
  return backgroundList
      .map((item) => BackgroundData.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}
