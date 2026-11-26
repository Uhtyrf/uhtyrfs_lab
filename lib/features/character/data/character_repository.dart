import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/character.dart';

class CharacterRepository {
  static const _fileName = 'characters.json';

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<Map<String, dynamic>> _readData() async {
    final file = await _getFile();
    if (!await file.exists()) {
      return {'characters': <dynamic>[], 'quickSlots': <dynamic>[]};
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic>) {
        return {
          'characters': decoded['characters'] is List
              ? decoded['characters'] as List<dynamic>
              : <dynamic>[],
          'quickSlots': decoded['quickSlots'] is List
              ? decoded['quickSlots'] as List<dynamic>
              : <dynamic>[],
        };
      }
    } on FormatException {
      // Do not overwrite a damaged file silently. Surface the error to the UI.
      rethrow;
    }
    return {'characters': <dynamic>[], 'quickSlots': <dynamic>[]};
  }

  Future<void> _writeData(Map<String, dynamic> data) async {
    final file = await _getFile();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
      flush: true,
    );
  }

  Future<List<Character>> getCharacters() async {
    final data = await _readData();
    return (data['characters'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(Character.fromJson)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<List<String?>> getQuickSlots() async {
    final data = await _readData();
    final slots = (data['quickSlots'] as List<dynamic>)
        .map((value) => value is String ? value : null)
        .toList();
    while (slots.length < 5) {
      slots.add(null);
    }
    return slots.take(5).toList();
  }

  Future<void> saveCharacter(Character character) async {
    final data = await _readData();
    final characters = (data['characters'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .toList();
    final index = characters.indexWhere((item) => item['id'] == character.id);
    character.updatedAt = DateTime.now();
    if (index == -1) {
      characters.add(character.toJson());
    } else {
      characters[index] = character.toJson();
    }
    data['characters'] = characters;
    await _writeData(data);
  }

  Future<void> deleteCharacter(String id) async {
    final data = await _readData();
    data['characters'] = (data['characters'] as List<dynamic>)
        .where((item) => item is Map && item['id'] != id)
        .toList();
    data['quickSlots'] = (data['quickSlots'] as List<dynamic>)
        .map((item) => item == id ? null : item)
        .toList();
    await _writeData(data);
  }

  Future<void> setQuickSlot(int slotIndex, String? characterId) async {
    if (slotIndex < 0 || slotIndex >= 5) {
      throw RangeError.index(slotIndex, List.filled(5, null), 'slotIndex');
    }
    final data = await _readData();
    final slots = await getQuickSlots();
    if (characterId != null) {
      // A character can occupy only one quick slot at a time.
      for (var i = 0; i < slots.length; i++) {
        if (slots[i] == characterId) slots[i] = null;
      }
    }
    slots[slotIndex] = characterId;
    data['quickSlots'] = slots;
    await _writeData(data);
  }
}
