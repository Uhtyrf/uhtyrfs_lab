import 'subclass_data.dart';

class DndClassData {
  final String id;
  final String name;
  final String englishName;
  final String source;
  final String description;

  final int hitDie;
  final List<String> primaryAbilities;
  final List<String> savingThrows;

  final Map<String, dynamic> proficiencies;
  final List<String> startingEquipment;

  final Map<String, dynamic>? spellcasting;
  final List<List<String>> progression;
  final List<ClassFeature> features;
  final List<ClassSubclass> subclasses;

  const DndClassData({
    required this.id,
    required this.name,
    required this.englishName,
    required this.source,
    required this.description,
    required this.hitDie,
    required this.primaryAbilities,
    required this.savingThrows,
    required this.proficiencies,
    required this.startingEquipment,
    this.spellcasting,
    required this.progression,
    this.features = const [],
    required this.subclasses,
  });

  factory DndClassData.fromJson(
    Map<String, dynamic> json, {
    List<ClassSubclass>? subclasses,
  }) {
    return DndClassData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      englishName: json['englishName'] ?? '',
      source: json['source'] ?? '',
      description: json['description'] ?? '',
      hitDie: json['hitDie'] ?? 8,
      primaryAbilities: List<String>.from(json['primaryAbilities'] ?? []),
      savingThrows: List<String>.from(json['savingThrows'] ?? []),
      proficiencies: Map<String, dynamic>.from(json['proficiencies'] ?? {}),
      startingEquipment: List<String>.from(json['startingEquipment'] ?? []),
      spellcasting: json['spellcasting'] == null
          ? null
          : Map<String, dynamic>.from(json['spellcasting']),
      progression: (json['progression'] as List? ?? [])
          .map((item) => List<String>.from(item))
          .toList(),
      features: (json['features'] as List? ?? [])
          .map((item) => ClassFeature.fromJson(item))
          .toList(),
      subclasses:
          subclasses ??
          (json['subclasses'] as List? ?? [])
              .map((item) => ClassSubclass.fromJson(item))
              .toList(),
    );
  }
}

// МОДЕЛЬ КЛАССА D&D

class ClassFeature {
  final String id;
  final int level;
  final String name;
  final String description;

  const ClassFeature({
    required this.id,
    required this.level,
    required this.name,
    required this.description,
  });

  factory ClassFeature.fromJson(Map<String, dynamic> json) {
    return ClassFeature(
      id: json['id'] ?? '',
      level: json['level'] ?? 1,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
