import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/race_data.dart';

Future<List<RaceData>>? _racesCache;

Future<List<RaceData>> loadRaces() {
  return _racesCache ??= _loadRacesFromAsset();
}

Future<List<RaceData>> _loadRacesFromAsset() async {
  final jsonString = await rootBundle.loadString('assets/data/races.json');
  final Map<String, dynamic> jsonData = jsonDecode(jsonString);
  final List<dynamic> raceList = jsonData['races'];
  return raceList
      .map((item) => RaceData.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}
