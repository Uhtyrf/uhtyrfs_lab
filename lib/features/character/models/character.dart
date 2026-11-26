import 'ability.dart';

class Character {
  final String id;
  String name;
  String race;
  String subrace;
  String draconicAncestry;
  String raceVariant;

  Map<String, int> racialAbilityBonuses;
  Map<String, int> abilityScores;

  /// Итоговые характеристики с учётом расовых и подрасовых бонусов.
  Map<String, int> get effectiveAbilityScores {
    final bonuses = Ability.normalizeBonuses(racialAbilityBonuses);
    return {
      for (final ability in Ability.all)
        ability.key:
            (abilityScores[ability.key] ?? 8) + (bonuses[ability.key] ?? 0),
    };
  }

  // Навыки по источникам
  List<String> racialSkillProficiencies;
  List<String> backgroundSkillProficiencies;
  List<String> classSkillProficiencies;

  // Старое поле для совместимости
  String racialSkillProficiency;

  String racialFeatId;
  String racialFeatName;
  // Черты, полученные при повышении уровня
  List<String> acquiredFeatIds;
  String characterClass;
  String subclassId;
  String subclassName;
  String warlockGenieKind;
  String circleOfLandTerrain;
  String background;

  int level;
  // Здоровье и кости хитов
  int maxHitPoints;
  int currentHitPoints;
  int hitDiceTotal;
  int hitDiceUsed;

  // Боевые состояния персонажа.
  int temporaryHitPoints;
  int deathSaveSuccesses;
  int deathSaveFailures;
  int exhaustionLevel;
  List<String> conditions;

  // Персональные данные магии и инвентаря персонажа.
  List<String> knownCantripIds;
  List<String> knownSpellIds;
  List<String> bardMagicalSecretSpellIds;
  List<String> loreAdditionalSpellIds;
  List<String> preparedSpellIds;
  List<String> spellbookSpellIds;
  List<String> spellMasterySpellIds;
  List<String> signatureSpellIds;
  Map<String, String> mysticArcanumSpellIds;
  List<int> usedMysticArcanumSpellLevels;
  bool usedEldritchMaster;
  int usedSorceryPoints;
  Map<String, int> sorcererCreatedSpellSlots;
  List<String> sorcererMetamagicOptions;
  Map<String, int> usedSpellSlots;
  List<Map<String, dynamic>> inventoryItems;
  Map<String, int> currency;
  List<String> equippedItemIds;

  final DateTime createdAt;
  DateTime updatedAt;

  Character({
    required this.id,
    required this.name,
    this.race = '',
    this.subrace = '',
    this.draconicAncestry = '',
    this.raceVariant = '',
    this.racialAbilityBonuses = const {},
    this.abilityScores = const {
      'str': 8,
      'dex': 8,
      'con': 8,
      'int': 8,
      'wis': 8,
      'cha': 8,
    },
    this.racialSkillProficiencies = const [],
    this.backgroundSkillProficiencies = const [],
    this.classSkillProficiencies = const [],
    this.racialSkillProficiency = '',
    this.racialFeatId = '',
    this.racialFeatName = '',
    List<String>? acquiredFeatIds,
    this.characterClass = '',
    this.subclassId = '',
    this.subclassName = '',
    this.warlockGenieKind = '',
    this.circleOfLandTerrain = '',
    this.background = '',
    this.level = 1,
    this.maxHitPoints = 0,
    this.currentHitPoints = 0,
    this.hitDiceTotal = 1,
    this.hitDiceUsed = 0,
    this.temporaryHitPoints = 0,
    this.deathSaveSuccesses = 0,
    this.deathSaveFailures = 0,
    this.exhaustionLevel = 0,
    List<String>? conditions,
    List<String>? knownCantripIds,
    List<String>? knownSpellIds,
    List<String>? bardMagicalSecretSpellIds,
    List<String>? loreAdditionalSpellIds,
    List<String>? preparedSpellIds,
    List<String>? spellbookSpellIds,
    List<String>? spellMasterySpellIds,
    List<String>? signatureSpellIds,
    Map<String, String>? mysticArcanumSpellIds,
    List<int>? usedMysticArcanumSpellLevels,
    this.usedEldritchMaster = false,
    this.usedSorceryPoints = 0,
    Map<String, int>? sorcererCreatedSpellSlots,
    List<String>? sorcererMetamagicOptions,
    Map<String, int>? usedSpellSlots,
    List<Map<String, dynamic>>? inventoryItems,
    Map<String, int>? currency,
    List<String>? equippedItemIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : conditions = List<String>.from(conditions ?? const []),
       knownCantripIds = List<String>.from(knownCantripIds ?? const []),
       knownSpellIds = List<String>.from(knownSpellIds ?? const []),
       bardMagicalSecretSpellIds = List<String>.from(
         bardMagicalSecretSpellIds ?? const [],
       ),
       loreAdditionalSpellIds = List<String>.from(
         loreAdditionalSpellIds ?? const [],
       ),
       preparedSpellIds = List<String>.from(preparedSpellIds ?? const []),
       spellbookSpellIds = List<String>.from(spellbookSpellIds ?? const []),
       spellMasterySpellIds = List<String>.from(
         spellMasterySpellIds ?? const [],
       ),
       signatureSpellIds = List<String>.from(signatureSpellIds ?? const []),
       mysticArcanumSpellIds = Map<String, String>.from(
         mysticArcanumSpellIds ?? const {},
       ),
       usedMysticArcanumSpellLevels = List<int>.from(
         usedMysticArcanumSpellLevels ?? const [],
       ),
       sorcererCreatedSpellSlots = Map<String, int>.from(sorcererCreatedSpellSlots ?? const {}),
       sorcererMetamagicOptions = List<String>.from(sorcererMetamagicOptions ?? const []),
       usedSpellSlots = Map<String, int>.from(usedSpellSlots ?? const {}),
       inventoryItems = (inventoryItems ?? const [])
           .map((item) => Map<String, dynamic>.from(item))
           .toList(),
       currency = Map<String, int>.from(
         currency ?? const {'cp': 0, 'sp': 0, 'ep': 0, 'gp': 0, 'pp': 0},
       ),
       equippedItemIds = List<String>.from(equippedItemIds ?? const []),
       acquiredFeatIds = List<String>.from(acquiredFeatIds ?? const []),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Все владения навыками без повторов
  List<String> get allSkillProficiencies {
    return {
      ...racialSkillProficiencies,
      ...backgroundSkillProficiencies,
      ...classSkillProficiencies,
      if (racialSkillProficiency.isNotEmpty) racialSkillProficiency,
    }.toList();
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    final scores = Map<String, int>.from(
      (json['abilityScores'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), (value as num).toInt()),
          ) ??
          {},
    );

    for (final ability in ['str', 'dex', 'con', 'int', 'wis', 'cha']) {
      scores.putIfAbsent(ability, () => 8);
    }

    List<String> readSkills(String key) {
      return (json[key] as List?)?.map((e) => e.toString()).toList() ?? [];
    }

    final oldRacialSkill = json['racialSkillProficiency'] as String? ?? '';

    final racialSkills = readSkills('racialSkillProficiencies');

    if (racialSkills.isEmpty && oldRacialSkill.isNotEmpty) {
      racialSkills.add(oldRacialSkill);
    }

    return Character(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Без имени',
      race: json['race'] as String? ?? '',
      subrace: json['subrace'] as String? ?? '',
      draconicAncestry: json['draconicAncestry'] as String? ?? '',
      raceVariant: json['raceVariant'] as String? ?? '',
      racialAbilityBonuses: Ability.normalizeBonuses(
        Map<String, int>.from(
          (json['racialAbilityBonuses'] as Map?)?.map(
                (key, value) =>
                    MapEntry(key.toString(), (value as num).toInt()),
              ) ??
              {},
        ),
      ),
      abilityScores: scores,
      racialSkillProficiencies: racialSkills,
      backgroundSkillProficiencies: readSkills('backgroundSkillProficiencies'),
      classSkillProficiencies: readSkills('classSkillProficiencies'),
      racialSkillProficiency: oldRacialSkill,
      racialFeatId: json['racialFeatId'] as String? ?? '',
      racialFeatName: json['racialFeatName'] as String? ?? '',
      acquiredFeatIds:
          (json['acquiredFeatIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      characterClass: json['characterClass'] as String? ?? '',
      subclassId: json['subclassId'] as String? ?? '',
      subclassName: json['subclassName'] as String? ?? '',
      warlockGenieKind: json['warlockGenieKind'] as String? ?? '',
      circleOfLandTerrain: json['circleOfLandTerrain'] as String? ?? '',
      background: json['background'] as String? ?? '',
      level: (json['level'] as num?)?.toInt() ?? 1,
      maxHitPoints: (json['maxHitPoints'] as num?)?.toInt() ?? 0,
      currentHitPoints: (json['currentHitPoints'] as num?)?.toInt() ?? 0,
      hitDiceTotal: (json['hitDiceTotal'] as num?)?.toInt() ?? 1,
      hitDiceUsed: (json['hitDiceUsed'] as num?)?.toInt() ?? 0,
      temporaryHitPoints: (json['temporaryHitPoints'] as num?)?.toInt() ?? 0,
      deathSaveSuccesses: (json['deathSaveSuccesses'] as num?)?.toInt() ?? 0,
      deathSaveFailures: (json['deathSaveFailures'] as num?)?.toInt() ?? 0,
      exhaustionLevel: (json['exhaustionLevel'] as num?)?.toInt() ?? 0,
      conditions:
          (json['conditions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      knownSpellIds:
          (json['knownSpellIds'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      bardMagicalSecretSpellIds:
          (json['bardMagicalSecretSpellIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      loreAdditionalSpellIds:
          (json['loreAdditionalSpellIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      knownCantripIds:
          (json['knownCantripIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      preparedSpellIds:
          (json['preparedSpellIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      spellbookSpellIds:
          (json['spellbookSpellIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      spellMasterySpellIds:
          (json['spellMasterySpellIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      signatureSpellIds:
          (json['signatureSpellIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      mysticArcanumSpellIds: Map<String, String>.from(
        (json['mysticArcanumSpellIds'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ) ??
            {},
      ),
      usedMysticArcanumSpellLevels:
          (json['usedMysticArcanumSpellLevels'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      usedEldritchMaster: json['usedEldritchMaster'] as bool? ?? false,
      usedSorceryPoints: (json['usedSorceryPoints'] as num?)?.toInt() ?? 0,
      sorcererCreatedSpellSlots: Map<String, int>.from(
        (json['sorcererCreatedSpellSlots'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), (value as num).toInt()),
            ) ??
            {},
      ),
      sorcererMetamagicOptions: (json['sorcererMetamagicOptions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      usedSpellSlots: Map<String, int>.from(
        (json['usedSpellSlots'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), (value as num).toInt()),
            ) ??
            {},
      ),
      inventoryItems:
          (json['inventoryItems'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      currency: Map<String, int>.from(
        (json['currency'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), (value as num).toInt()),
            ) ??
            {'cp': 0, 'sp': 0, 'ep': 0, 'gp': 0, 'pp': 0},
      ),
      equippedItemIds:
          (json['equippedItemIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'race': race,
    'subrace': subrace,
    'draconicAncestry': draconicAncestry,
    'raceVariant': raceVariant,
    'racialAbilityBonuses': racialAbilityBonuses,
    'abilityScores': abilityScores,
    'racialSkillProficiencies': racialSkillProficiencies,
    'backgroundSkillProficiencies': backgroundSkillProficiencies,
    'classSkillProficiencies': classSkillProficiencies,
    'racialSkillProficiency': racialSkillProficiency,
    'racialFeatId': racialFeatId,
    'racialFeatName': racialFeatName,
    'acquiredFeatIds': acquiredFeatIds,
    'characterClass': characterClass,
    'subclassId': subclassId,
    'subclassName': subclassName,
    'warlockGenieKind': warlockGenieKind,
    'circleOfLandTerrain': circleOfLandTerrain,
    'background': background,
    'level': level,
    'maxHitPoints': maxHitPoints,
    'currentHitPoints': currentHitPoints,
    'hitDiceTotal': hitDiceTotal,
    'hitDiceUsed': hitDiceUsed,
    'temporaryHitPoints': temporaryHitPoints,
    'deathSaveSuccesses': deathSaveSuccesses,
    'deathSaveFailures': deathSaveFailures,
    'exhaustionLevel': exhaustionLevel,
    'conditions': conditions,
    'knownSpellIds': knownSpellIds,
    'bardMagicalSecretSpellIds': bardMagicalSecretSpellIds,
    'loreAdditionalSpellIds': loreAdditionalSpellIds,
    'preparedSpellIds': preparedSpellIds,
    'knownCantripIds': knownCantripIds,
    'spellbookSpellIds': spellbookSpellIds,
    'spellMasterySpellIds': spellMasterySpellIds,
    'signatureSpellIds': signatureSpellIds,
    'mysticArcanumSpellIds': mysticArcanumSpellIds,
    'usedMysticArcanumSpellLevels': usedMysticArcanumSpellLevels,
    'usedEldritchMaster': usedEldritchMaster,
    'usedSorceryPoints': usedSorceryPoints,
    'sorcererCreatedSpellSlots': sorcererCreatedSpellSlots,
    'sorcererMetamagicOptions': sorcererMetamagicOptions,
    'usedSpellSlots': usedSpellSlots,
    'inventoryItems': inventoryItems,
    'currency': currency,
    'equippedItemIds': equippedItemIds,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
