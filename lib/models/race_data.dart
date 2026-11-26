class RaceData {
  final String id;
  final String name;
  final String englishName;
  final String source;
  final String description;

  final String size;
  final int speed;
  final String age;
  final String alignment;

  final Map<String, int> abilityBonuses;
  final List<String> languages;
  final List<RaceTrait> traits;
  final List<RaceSubrace> subraces;

  // Дополнительные данные для будущего конструктора персонажа.
  final int schemaVersion;
  final List<Map<String, dynamic>> abilityBonusChoices;
  final List<Map<String, dynamic>> languageChoices;
  final Map<String, dynamic> mechanics;
  final List<RaceVariant> variants;

  const RaceData({
    required this.id,
    required this.name,
    required this.englishName,
    required this.source,
    required this.description,
    this.size = '',
    this.speed = 0,
    this.age = '',
    this.alignment = '',
    this.abilityBonuses = const {},
    this.languages = const [],
    this.traits = const [],
    this.subraces = const [],
    this.schemaVersion = 1,
    this.abilityBonusChoices = const [],
    this.languageChoices = const [],
    this.mechanics = const {},
    this.variants = const [],
  });

  factory RaceData.fromJson(Map<String, dynamic> json) {
    final bonuses = Map<String, dynamic>.from(json['abilityBonuses'] ?? {});

    return RaceData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      englishName: json['englishName'] ?? '',
      source: json['source'] ?? '',
      description: json['description'] ?? '',
      size: json['size'] ?? '',
      speed: (json['speed'] as num?)?.toInt() ?? 0,
      age: json['age'] ?? '',
      alignment: json['alignment'] ?? '',
      abilityBonuses: bonuses.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      languages: List<String>.from(json['languages'] ?? []),
      traits: (json['traits'] as List? ?? [])
          .map((item) => RaceTrait.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      subraces: (json['subraces'] as List? ?? [])
          .map((item) => RaceSubrace.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      abilityBonusChoices: (json['abilityBonusChoices'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      languageChoices: (json['languageChoices'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      mechanics: Map<String, dynamic>.from(json['mechanics'] ?? {}),
      variants: (json['variants'] as List? ?? [])
          .map((item) => RaceVariant.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class RaceTrait {
  final String name;
  final String description;
  final Map<String, dynamic> mechanics;

  const RaceTrait({
    required this.name,
    required this.description,
    this.mechanics = const {},
  });

  factory RaceTrait.fromJson(Map<String, dynamic> json) {
    return RaceTrait(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      mechanics: Map<String, dynamic>.from(json['mechanics'] ?? {}),
    );
  }
}

class RaceSubrace {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> mechanics;

  const RaceSubrace({
    required this.id,
    required this.name,
    required this.description,
    this.mechanics = const {},
  });

  factory RaceSubrace.fromJson(Map<String, dynamic> json) {
    return RaceSubrace(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      mechanics: Map<String, dynamic>.from(json['mechanics'] ?? {}),
    );
  }
}

class RaceVariant {
  final String id;
  final String name;
  final String description;
  final List<String> replacesBaseTraits;
  final Map<String, dynamic> mechanics;

  const RaceVariant({
    required this.id,
    required this.name,
    required this.description,
    this.replacesBaseTraits = const [],
    this.mechanics = const {},
  });

  factory RaceVariant.fromJson(Map<String, dynamic> json) {
    return RaceVariant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      replacesBaseTraits: List<String>.from(json['replacesBaseTraits'] ?? []),
      mechanics: Map<String, dynamic>.from(json['mechanics'] ?? {}),
    );
  }
}
