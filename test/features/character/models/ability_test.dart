import 'package:flutter_test/flutter_test.dart';
import 'package:uhtyrfs_lab/features/character/models/ability.dart';
import 'package:uhtyrfs_lab/features/character/models/character.dart';

void main() {
  group('Ability', () {
    test('normalizes long JSON keys to short character keys', () {
      expect(
        Ability.normalizeBonuses({
          'strength': 2,
          'wisdom': 1,
          'str': 1,
        }),
        {'str': 3, 'wis': 1},
      );
    });

    test('calculates effective scores without changing base scores', () {
      final character = Character(
        id: 'test',
        name: 'Тест',
        abilityScores: {
          'str': 15,
          'dex': 10,
          'con': 12,
          'int': 8,
          'wis': 13,
          'cha': 10,
        },
        // Старый формат сохранения использовал длинные JSON-ключи.
        racialAbilityBonuses: {
          'strength': 2,
          'wisdom': 1,
        },
      );

      expect(character.effectiveAbilityScores['str'], 17);
      expect(character.effectiveAbilityScores['wis'], 14);
      expect(character.abilityScores['str'], 15);
    });
  });
}
