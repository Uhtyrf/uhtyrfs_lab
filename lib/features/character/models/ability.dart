/// Единое соответствие ключей характеристик в интерфейсе и JSON D&D.
class Ability {
  final String key;
  final String jsonKey;
  final String name;

  const Ability(this.key, this.jsonKey, this.name);

  static const all = <Ability>[
    Ability('str', 'strength', 'Сила'),
    Ability('dex', 'dexterity', 'Ловкость'),
    Ability('con', 'constitution', 'Телосложение'),
    Ability('int', 'intelligence', 'Интеллект'),
    Ability('wis', 'wisdom', 'Мудрость'),
    Ability('cha', 'charisma', 'Харизма'),
  ];

  static final Map<String, Ability> _byKey = {
    for (final ability in all) ability.key: ability,
    for (final ability in all) ability.jsonKey: ability,
  };

  static String? normalizeKey(String key) => _byKey[key.toLowerCase()]?.key;

  static Map<String, int> normalizeBonuses(Map<String, int> bonuses) {
    final result = <String, int>{};
    for (final entry in bonuses.entries) {
      final key = normalizeKey(entry.key);
      if (key != null) result[key] = (result[key] ?? 0) + entry.value;
    }
    return result;
  }
}
