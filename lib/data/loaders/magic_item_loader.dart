import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/magic_item_data.dart';

Future<List<MagicItemData>>? _magicItemsCache;

Future<List<MagicItemData>> loadMagicItems() {
  return _magicItemsCache ??= _loadMagicItemsFromAsset();
}

Future<List<MagicItemData>> _loadMagicItemsFromAsset() async {
  final jsonString = await rootBundle.loadString(
    'assets/data/magic_items.json',
  );
  final Map<String, dynamic> jsonData = jsonDecode(jsonString);
  final List<dynamic> itemList = jsonData['items'];
  return itemList
      .map((item) => MagicItemData.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}
