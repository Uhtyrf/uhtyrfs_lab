import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/class_data.dart';
import '../../models/subclass_data.dart';

Future<List<DndClassData>>? _classesCache;

Future<List<DndClassData>> loadClasses() {
  return _classesCache ??= _loadClassesFromAsset();
}

Future<List<DndClassData>> _loadClassesFromAsset() async {
  final classesJsonString = await rootBundle.loadString(
    'assets/data/classes.json',
  );
  final Map<String, dynamic> classesJson = jsonDecode(classesJsonString);
  final List<dynamic> classList = classesJson['classes'];

  final subclassesJsonString = await rootBundle.loadString(
    'assets/data/subclasses.json',
  );
  final Map<String, dynamic> subclassesJson = jsonDecode(subclassesJsonString);
  final List<dynamic> subclassList = subclassesJson['subclasses'];

  final Map<String, List<ClassSubclass>> subclassesByClass = {};
  for (final item in subclassList) {
    final subclassJson = Map<String, dynamic>.from(item);
    final classId = subclassJson['classId'] as String?;
    if (classId == null || classId.isEmpty) {
      throw const FormatException(
        'У подкласса отсутствует обязательное поле classId.',
      );
    }
    subclassesByClass.putIfAbsent(classId, () => []);
    subclassesByClass[classId]!.add(ClassSubclass.fromJson(subclassJson));
  }

  final classIds = <String>{};
  final allClasses = classList.map((item) {
    final classJson = Map<String, dynamic>.from(item);
    final classId = classJson['id'] as String?;
    if (classId == null || classId.isEmpty) {
      throw const FormatException('У класса отсутствует обязательное поле id.');
    }
    classIds.add(classId);
    return DndClassData.fromJson(
      classJson,
      subclasses: subclassesByClass[classId] ?? const [],
    );
  }).toList();

  final unknownClassIds = subclassesByClass.keys
      .where((classId) => !classIds.contains(classId))
      .toList();
  if (unknownClassIds.isNotEmpty) {
    throw FormatException(
      'В subclasses.json найдены неизвестные classId: '
      '${unknownClassIds.join(', ')}',
    );
  }
  return allClasses;
}
