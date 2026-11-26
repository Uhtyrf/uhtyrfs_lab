import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/spell_data.dart';

Future<List<SpellData>>? _spellsCache;

Future<List<SpellData>> loadSpells() {
  return _spellsCache ??= _loadSpellsFromAsset();
}

Future<List<SpellData>> _loadSpellsFromAsset() async {
  final jsonString = await rootBundle.loadString('assets/data/spells.json');
  final Map<String, dynamic> jsonData = jsonDecode(jsonString);
  final List<dynamic> spellList = jsonData['spells'];
  return spellList
      .map((item) => SpellData.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}
