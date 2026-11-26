import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/feat_data.dart';

Future<List<FeatData>>? _featsCache;

Future<List<FeatData>> loadFeats() {
  return _featsCache ??= _loadFeatsFromAsset();
}

Future<List<FeatData>> _loadFeatsFromAsset() async {
  final jsonString = await rootBundle.loadString('assets/data/feats.json');
  final Map<String, dynamic> jsonData = jsonDecode(jsonString);
  final List<dynamic> featList = jsonData['feats'];
  return featList
      .map((item) => FeatData.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}
