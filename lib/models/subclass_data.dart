class ClassSubclass {
  final String id;
  final String name;
  final String englishName;
  final String source;
  final String description;
  final List<int> featureLevels;
  final List<SubclassFeature> features;
  final List<WildSurgeResult> wildSurge;
  final Map<String, dynamic>? spellcasting;
  final List<String> alwaysPreparedSpells;
  final Map<String, Map<int, List<String>>> circleSpellLists;

  const ClassSubclass({
    required this.id,
    required this.name,
    this.englishName = '',
    this.source = '',
    this.description = '',
    required this.featureLevels,
    this.features = const [],
    this.wildSurge = const [],
    this.spellcasting,
    this.alwaysPreparedSpells = const [],
    this.circleSpellLists = const {},
  });

  factory ClassSubclass.fromJson(Map<String, dynamic> json) {
    final circleSpellListsJson =
        json['circleSpellLists'] as Map? ?? const <String, dynamic>{};

    return ClassSubclass(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      englishName: json['englishName'] ?? '',
      source: json['source'] ?? '',
      description: json['description'] ?? '',
      featureLevels: List<int>.from(json['featureLevels'] ?? []),
      features: (json['features'] as List? ?? [])
          .map((item) => SubclassFeature.fromJson(item))
          .toList(),
      wildSurge: (json['wildSurge'] as List? ?? [])
          .map((item) => WildSurgeResult.fromJson(item))
          .toList(),
      spellcasting: json['spellcasting'] == null
          ? null
          : Map<String, dynamic>.from(json['spellcasting']),
      alwaysPreparedSpells: List<String>.from(
        json['alwaysPreparedSpells'] ?? [],
      ),
      circleSpellLists: {
        for (final terrainEntry in circleSpellListsJson.entries)
          terrainEntry.key.toString(): {
            for (final levelEntry in (terrainEntry.value as Map).entries)
              int.parse(levelEntry.key.toString()): List<String>.from(
                levelEntry.value as List,
              ),
          },
      },
    );
  }
}

class SubclassFeature {
  final int level;
  final String name;
  final String description;

  const SubclassFeature({
    required this.level,
    required this.name,

    required this.description,
  });

  factory SubclassFeature.fromJson(Map<String, dynamic> json) {
    return SubclassFeature(
      level: json['level'] ?? 1,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class WildSurgeResult {
  final int roll;
  final String description;

  const WildSurgeResult({required this.roll, required this.description});

  factory WildSurgeResult.fromJson(Map<String, dynamic> json) {
    return WildSurgeResult(
      roll: json['roll'] ?? 1,
      description: json['description'] ?? '',
    );
  }
}
