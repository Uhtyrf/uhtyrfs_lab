import 'package:flutter_test/flutter_test.dart';
import 'package:uhtyrfs_lab/features/character/models/character.dart';

void main() {
  group('Warlock magic persistence', () {
    test('round-trips Mystic Arcanum selection and use state', () {
      final character = Character(
        id: 'warlock-test',
        name: 'Test Warlock',
        characterClass: 'Warlock',
        level: 11,
        knownSpellIds: ['armor_of_agathys', 'hex'],
        knownCantripIds: ['eldritch_blast', 'mage_hand'],
        mysticArcanumSpellIds: {'6': 'circle_of_death'},
        usedMysticArcanumSpellLevels: [6],
        usedEldritchMaster: true,
        usedSpellSlots: {'5': 1},
      );

      final restored = Character.fromJson(character.toJson());

      expect(restored.knownSpellIds, ['armor_of_agathys', 'hex']);
      expect(restored.knownCantripIds, ['eldritch_blast', 'mage_hand']);
      expect(restored.mysticArcanumSpellIds, {'6': 'circle_of_death'});
      expect(restored.usedMysticArcanumSpellLevels, [6]);
      expect(restored.usedEldritchMaster, isTrue);
      expect(restored.usedSpellSlots, {'5': 1});
    });

    test('loads older characters without Warlock-specific fields', () {
      final restored = Character.fromJson({
        'id': 'legacy-warlock',
        'name': 'Legacy Warlock',
        'characterClass': 'Warlock',
      });

      expect(restored.mysticArcanumSpellIds, isEmpty);
      expect(restored.usedMysticArcanumSpellLevels, isEmpty);
      expect(restored.usedEldritchMaster, isFalse);
      expect(restored.knownSpellIds, isEmpty);
      expect(restored.knownCantripIds, isEmpty);
    });
  });
}
