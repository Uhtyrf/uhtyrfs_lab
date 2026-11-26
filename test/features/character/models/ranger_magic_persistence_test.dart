import 'package:flutter_test/flutter_test.dart';
import 'package:uhtyrfs_lab/features/character/models/character.dart';

void main() {
  group('Ranger magic persistence', () {
    test('round-trips known spells and expended spell slots', () {
      final character = Character(
        id: 'ranger-test',
        name: 'Test Ranger',
        characterClass: 'Ranger',
        level: 5,
        knownSpellIds: ['cure_wounds', 'ensnaring_strike'],
        usedSpellSlots: {'1': 2, '2': 1},
      );

      final restored = Character.fromJson(character.toJson());

      expect(restored.knownSpellIds, ['cure_wounds', 'ensnaring_strike']);
      expect(restored.preparedSpellIds, isEmpty);
      expect(restored.usedSpellSlots, {'1': 2, '2': 1});
    });

    test('loads older Ranger saves without spell data', () {
      final restored = Character.fromJson({
        'id': 'legacy-ranger',
        'name': 'Legacy Ranger',
        'characterClass': 'Ranger',
        'level': 8,
      });

      expect(restored.knownSpellIds, isEmpty);
      expect(restored.preparedSpellIds, isEmpty);
      expect(restored.usedSpellSlots, isEmpty);
    });
  });
}
