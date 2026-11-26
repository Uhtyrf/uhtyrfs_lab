import 'package:flutter/material.dart';
import '../../magic/widgets/spell_detail_content.dart';

import 'level_up_screen.dart';
import 'combat_screen.dart';
import 'wizard_spellbook_screen.dart';
import 'spell_selection_dialog.dart';
import '../models/character.dart';
import '../data/character_repository.dart';
import '../../../data/loaders/class_loader.dart';
import '../../../data/loaders/spell_loader.dart';
import '../../../data/loaders/magic_item_loader.dart';
import '../../../models/class_data.dart';
import '../../../models/spell_data.dart';
import '../../../models/magic_item_data.dart';
import '../../../models/subclass_data.dart';

class CharacterSheetScreen extends StatefulWidget {
  final Character character;

  const CharacterSheetScreen({super.key, required this.character});

  @override
  State<CharacterSheetScreen> createState() => _CharacterSheetScreenState();
}

class _CharacterSheetScreenState extends State<CharacterSheetScreen> {
  static const List<List<int>> _thirdCasterSpellSlots = [
    [],
    [],
    [2],
    [3],
    [3],
    [3],
    [4, 2],
    [4, 2],
    [4, 2],
    [4, 3],
    [4, 3],
    [4, 3],
    [4, 3, 2],
    [4, 3, 2],
    [4, 3, 2],
    [4, 3, 3],
    [4, 3, 3],
    [4, 3, 3],
    [4, 3, 3, 1],
    [4, 3, 3, 1],
  ];

  static const List<int> _eldritchKnightKnownSpells = [
    0,
    0,
    3,
    4,
    4,
    4,
    5,
    6,
    6,
    7,
    8,
    8,
    9,
    10,
    10,
    11,
    11,
    11,
    12,
    13,
  ];
  static const List<int> _arcaneTricksterKnownSpells = [
    0,
    0,
    3,
    4,
    4,
    4,
    5,
    6,
    6,
    7,
    8,
    8,
    9,
    10,
    10,
    11,
    11,
    11,
    12,
    13,
  ];
  static const List<int> _eldritchKnightCantrips = [
    0,
    0,
    2,
    2,
    2,
    2,
    2,
    2,
    2,
    3,
    3,
    3,
    3,
    3,
    3,
    3,
    3,
    3,
    3,
    3,
  ];
  static const List<int> _arcaneTricksterCantrips = [
    0,
    0,
    3,
    3,
    3,
    3,
    3,
    3,
    3,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
    4,
  ];

  bool _useVirtualDice = false;

  int _modifier(int score) => ((score - 10) / 2).floor();

  String _signed(int value) => value >= 0 ? '+$value' : '$value';

  final CharacterRepository _repository = CharacterRepository();

  Future<void> _persist() async {
    await _repository.saveCharacter(widget.character);
    if (mounted) setState(() {});
  }

  bool _isCircleOfLand(DndClassData classData, ClassSubclass? subclass) =>
      classData.id == 'druid' && subclass?.id == 'circle_of_land';

  Set<String> _circleOfLandSpellIds(ClassSubclass? subclass) {
    if (subclass == null ||
        subclass.id != 'circle_of_land' ||
        widget.character.circleOfLandTerrain.isEmpty) {
      return <String>{};
    }

    final terrainSpells =
        subclass.circleSpellLists[widget.character.circleOfLandTerrain];
    if (terrainSpells == null) return <String>{};

    return {
      for (final entry in terrainSpells.entries)
        if (widget.character.level >= entry.key) ...entry.value,
    };
  }

  Widget _buildCircleOfLandTerrainInfo() {
    const terrains = <String, String>{
      'arctic': 'Arctic — Арктика',
      'coast': 'Coast — Побережье',
      'desert': 'Desert — Пустыня',
      'forest': 'Forest — Лес',
      'grassland': 'Grassland — Луга',
      'mountain': 'Mountain — Горы',
      'swamp': 'Swamp — Болото',
      'underdark': 'Underdark — Подземье',
    };
    final currentTerrain =
        terrains.containsKey(widget.character.circleOfLandTerrain)
        ? widget.character.circleOfLandTerrain
        : null;

    final message = currentTerrain == null
        ? 'Местность Круга земли не задана. В приложении нет редактора этого параметра. Чтобы получить круговые заклинания, пересоздайте персонажа и выберите местность.'
        : 'Местность Круга земли: ${terrains[currentTerrain]}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(message, style: Theme.of(context).textTheme.bodySmall),
    );
  }

  Future<void> _levelUp() async {
    final character = widget.character;

    if (character.level >= 20) return;

    final result = await Navigator.of(context).push<LevelUpResult>(
      MaterialPageRoute(builder: (_) => LevelUpScreen(character: character)),
    );

    if (result == null || !mounted) return;

    character.level = result.newLevel;

    if (result.replacedKnownSpellId != null) {
      character.knownSpellIds.remove(result.replacedKnownSpellId);
      character.bardMagicalSecretSpellIds.remove(result.replacedKnownSpellId);
      character.loreAdditionalSpellIds.remove(result.replacedKnownSpellId);
    }
    for (final id in result.newKnownSpellIds) {
      if (!character.knownSpellIds.contains(id)) {
        character.knownSpellIds.add(id);
      }
    }
    for (final id in result.newBardMagicalSecretSpellIds) {
      if (!character.bardMagicalSecretSpellIds.contains(id)) {
        character.bardMagicalSecretSpellIds.add(id);
      }
    }
    for (final id in result.newLoreAdditionalSpellIds) {
      if (!character.loreAdditionalSpellIds.contains(id)) {
        character.loreAdditionalSpellIds.add(id);
      }
    }
    character.mysticArcanumSpellIds.addAll(result.mysticArcanumSpellIds);
    character.sorcererMetamagicOptions.addAll(
      result.sorcererMetamagicOptions.where(
        (id) => !character.sorcererMetamagicOptions.contains(id),
      ),
    );

    character.maxHitPoints = result.newMaxHitPoints;

    character.currentHitPoints =
        (character.currentHitPoints + result.gainedHitPoints)
            .clamp(0, character.maxHitPoints)
            .toInt();

    character.hitDiceTotal = result.newLevel;

    for (final id in result.newSpellbookSpellIds) {
      if (!character.spellbookSpellIds.contains(id)) {
        character.spellbookSpellIds.add(id);
      }
    }
    for (final id in result.newCantripIds) {
      if (!character.knownCantripIds.contains(id)) {
        character.knownCantripIds.add(id);
      }
    }
    if (result.spellMasterySpellIds.isNotEmpty) {
      character.spellMasterySpellIds = List<String>.from(
        result.spellMasterySpellIds,
      );
    }
    if (result.signatureSpellIds.isNotEmpty) {
      character.signatureSpellIds = List<String>.from(result.signatureSpellIds);
    }

    // Применяем увеличение характеристик
    result.abilityScoreIncreases.forEach((ability, increase) {
      character.abilityScores[ability] =
          (character.abilityScores[ability] ?? 8) + increase;
    });

    // Добавляем выбранную черту
    final featId = result.selectedFeatId;
    if (featId != null && !character.acquiredFeatIds.contains(featId)) {
      character.acquiredFeatIds.add(featId);
    }

    await _persist();
  }

  Future<void> _addSpell() async {
    final spells = await loadSpells();
    final classes = await loadClasses();
    if (!mounted) return;
    final character = widget.character;
    final classData = _findCharacterClass(classes);
    if (classData == null) return;
    final subclass = _findCharacterSubclass(classData);
    final casting = classData.spellcasting ?? subclass?.spellcasting;
    if (casting == null) return;

    final isWizard = classData.id == 'wizard';
    final allSelectedIds = {
      ...character.knownCantripIds,
      ...character.knownSpellIds,
      ...character.bardMagicalSecretSpellIds,
      ...character.loreAdditionalSpellIds,
      ...character.preparedSpellIds,
      ...character.spellbookSpellIds,
      ...character.mysticArcanumSpellIds.values,
    };
    final wizardBookIds = {
      ...character.spellbookSpellIds,
      // Legacy wizard saves used knownSpellIds for book entries.
      ...character.knownSpellIds,
    };
    final alwaysPreparedIds = _unlockedAlwaysPreparedIds(
      spells,
      classData,
      subclass,
      casting,
    );
    final rangerSubclassSpellIds = _unlockedRangerSubclassSpellIds(
      spells,
      classData,
      subclass,
    );

    final preparedLimit = !_usesPreparedSpellList(classData, casting)
        ? null
        : _preparedSpellLimit(classData);
    final preparedCount = character.preparedSpellIds
        .toSet()
        .where((id) => !alwaysPreparedIds.contains(id))
        .map((id) => _spellById(spells, id))
        .where((spell) => spell != null && spell.level > 0)
        .length;
    final cantripLimit = _cantripLimit(classData, casting);
    final cantripIdsForLimit = classData.id == 'bard'
        ? <String>{...character.knownCantripIds}
        : <String>{
            ...character.knownCantripIds,
            ...character.knownSpellIds,
            ...character.bardMagicalSecretSpellIds,
            ...character.loreAdditionalSpellIds,
            ...character.preparedSpellIds,
            ...character.spellbookSpellIds,
          };
    final cantripCount = _selectedSpellCount(
      spells,
      cantripIdsForLimit,
      cantrips: true,
    );
    final knownLimit = isWizard
        ? null
        : _progressionLimit(classData, casting, 'spellsKnownByLevel');
    final knownCount = _selectedSpellCount(
      spells,
      {
        ...character.knownSpellIds,
        ...character.bardMagicalSecretSpellIds,
        ...character.preparedSpellIds,
      },
      cantrips: false,
      excludeWarlockArcanum: classData.id == 'warlock',
    );

    final available = spells.where((spell) {
      if (classData.id == 'warlock' && spell.level > 5) return false;
      if (!_isSpellAvailable(spell, spells, classData, subclass, casting)) {
        return false;
      }

      final alreadySelected = isWizard && spell.level > 0
          ? wizardBookIds.contains(spell.id)
          : allSelectedIds.contains(spell.id);
      if (alreadySelected ||
          alwaysPreparedIds.contains(spell.id) ||
          rangerSubclassSpellIds.contains(spell.id)) {
        return false;
      }

      if (spell.level == 0 &&
          cantripLimit != null &&
          cantripCount >= cantripLimit) {
        return false;
      }

      if (spell.level > 0 &&
          knownLimit != null &&
          _usesKnownSpellList(classData, casting) &&
          !(classData.id == 'warlock' && spell.level > 5) &&
          knownCount >= knownLimit) {
        return false;
      }

      if (!isWizard &&
          spell.level > 0 &&
          preparedLimit != null &&
          preparedCount >= preparedLimit) {
        return false;
      }

      return true;
    }).toList();

    final selected = await showDialog<SpellData>(
      context: context,
      builder: (context) =>
          _SpellPickerDialog(spells: available, showSchoolFilter: isWizard),
    );
    if (selected == null) return;

    if (selected.level == 0) {
      character.knownCantripIds.add(selected.id);
    } else if (isWizard) {
      character.spellbookSpellIds.add(selected.id);
    } else if (_usesKnownSpellList(classData, casting)) {
      character.knownSpellIds.add(selected.id);
    } else {
      character.preparedSpellIds.add(selected.id);
    }
    await _persist();
  }

  Future<void> _prepareWizardSpell() async {
    final spells = await loadSpells();
    final classes = await loadClasses();
    if (!mounted) return;

    final character = widget.character;
    final classData = _findCharacterClass(classes);
    if (classData == null || classData.id != 'wizard') return;
    final subclass = _findCharacterSubclass(classData);
    final casting = classData.spellcasting ?? subclass?.spellcasting;
    if (casting == null) return;

    final limit = _preparedSpellLimit(classData);
    final alwaysPreparedIds = _unlockedAlwaysPreparedIds(
      spells,
      classData,
      subclass,
      casting,
    );
    final preparedCount = character.preparedSpellIds
        .toSet()
        .where((id) => !alwaysPreparedIds.contains(id))
        .map((id) => _spellById(spells, id))
        .where((spell) => spell != null && spell.level > 0)
        .length;
    if (limit != null && preparedCount >= limit) {
      _showSpellLimitMessage(limit);
      return;
    }

    final bookIds = {
      ...character.spellbookSpellIds,
      // Old saves may have wizard spells in knownSpellIds; keep reading them
      // as book entries without moving or rewriting the saved IDs.
      ...character.knownSpellIds,
    };
    final available = spells.where((spell) {
      return spell.level > 0 &&
          bookIds.contains(spell.id) &&
          !character.preparedSpellIds.contains(spell.id) &&
          !alwaysPreparedIds.contains(spell.id) &&
          _isSpellAvailable(spell, spells, classData, subclass, casting);
    }).toList();

    final selected = await showDialog<SpellData>(
      context: context,
      builder: (context) =>
          _SpellPickerDialog(spells: available, showSchoolFilter: true),
    );
    if (selected == null) return;

    character.preparedSpellIds.add(selected.id);
    await _persist();
  }

  int? _progressionLimit(
    DndClassData classData,
    Map<String, dynamic> casting,
    String key,
  ) {
    final index = _classLevelIndex();
    if ((classData.id == 'fighter' || classData.id == 'rogue') &&
        casting['maxSpellLevel'] != null) {
      if (key == 'spellsKnownByLevel') {
        return classData.id == 'fighter'
            ? _eldritchKnightKnownSpells[index]
            : _arcaneTricksterKnownSpells[index];
      }
      return null;
    }
    final progression = casting[key] as List?;
    if (progression == null || index >= progression.length) return null;
    return (progression[index] as num).toInt();
  }

  int? _cantripLimit(DndClassData classData, Map<String, dynamic> casting) {
    final index = _classLevelIndex();
    if (classData.id == 'fighter' && casting['maxSpellLevel'] != null) {
      return _eldritchKnightCantrips[index];
    }
    if (classData.id == 'rogue' && casting['maxSpellLevel'] != null) {
      return _arcaneTricksterCantrips[index];
    }
    final limit = _progressionLimit(classData, casting, 'cantripsKnownByLevel');
    final subclassId = _findCharacterSubclass(classData)?.id;
    final hasBonusCantrip =
        (classData.id == 'druid' &&
            subclassId == 'circle_of_land' &&
            widget.character.level >= 2) ||
        (classData.id == 'artificer' &&
            subclassId == 'alchemist' &&
            widget.character.level >= 3);
    if (hasBonusCantrip && limit != null) {
      return limit + 1;
    }
    return limit;
  }

  int _selectedSpellCount(
    List<SpellData> spells,
    Set<String> ids, {
    required bool cantrips,
    bool excludeWarlockArcanum = false,
  }) {
    return ids.map((id) => _spellById(spells, id)).where((spell) {
      if (spell == null) return false;
      if (cantrips) return spell.level == 0;
      return spell.level > 0 && !(excludeWarlockArcanum && spell.level > 5);
    }).length;
  }

  ClassSubclass? _findCharacterSubclass(DndClassData classData) {
    for (final subclass in classData.subclasses) {
      if (subclass.id == widget.character.subclassId ||
          subclass.name == widget.character.subclassName) {
        return subclass;
      }
    }
    return null;
  }

  SpellData? _spellById(List<SpellData> spells, String id) {
    for (final spell in spells) {
      if (spell.id == id) return spell;
    }
    return null;
  }

  Widget _spellInfoButton(SpellData spell) {
    return IconButton(
      tooltip: 'Информация о заклинании',
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.info_outline),
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (sheetContext) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              child: SpellDetailContent(spell: spell),
            ),
          ),
        );
      },
    );
  }

  Set<String> _unlockedAlwaysPreparedIds(
    List<SpellData> spells,
    DndClassData classData,
    ClassSubclass? subclass,
    Map<String, dynamic> casting,
  ) {
    final wizardSignatureIds =
        classData.id == 'wizard' && widget.character.level >= 20
        ? widget.character.signatureSpellIds.toSet()
        : <String>{};
    if (subclass == null && wizardSignatureIds.isEmpty) {
      return <String>{};
    }
    if (subclass != null && subclass.featureLevels.isNotEmpty) {
      final firstFeatureLevel = subclass.featureLevels.reduce(
        (a, b) => a < b ? a : b,
      );
      if (widget.character.level < firstFeatureLevel) return <String>{};
    }

    final circleSpellIds =
        subclass != null && _isCircleOfLand(classData, subclass)
        ? _circleOfLandSpellIds(subclass)
        : <String>{};
    final candidateIds = {
      ...?subclass?.alwaysPreparedSpells,
      ...circleSpellIds,
      ...wizardSignatureIds,
    };

    return <String>{
      for (final spellId in candidateIds)
        if (_spellById(spells, spellId) case final spell?)
          if (_isSpellAvailable(spell, spells, classData, subclass, casting))
            spellId,
    };
  }

  Set<String> _unlockedRangerSubclassSpellIds(
    List<SpellData> spells,
    DndClassData classData,
    ClassSubclass? subclass,
  ) {
    if (classData.id != 'ranger' || subclass?.id != 'horizon_walker') {
      return <String>{};
    }
    const unlocks = <int, String>{
      3: 'protection_from_evil_and_good',
      5: 'misty_step',
      9: 'haste',
      13: 'banishment',
      17: 'teleportation_circle',
    };
    return <String>{
      for (final entry in unlocks.entries)
        if (widget.character.level >= entry.key)
          if (_spellById(spells, entry.value) case final spell?)
            if (spell.subclasses.contains('horizon_walker')) entry.value,
    };
  }

  int _classLevelIndex() => (widget.character.level.clamp(1, 20) - 1).toInt();

  List<MapEntry<int, int>> _currentSpellSlotPools(
    DndClassData classData,
    Map<String, dynamic> casting,
  ) {
    final index = _classLevelIndex();

    if (classData.id == 'warlock' && casting['pactMagic'] is Map) {
      final pactMagic = Map<String, dynamic>.from(casting['pactMagic'] as Map);
      final counts = pactMagic['spellSlotsByLevel'] as List? ?? const [];
      final levels = pactMagic['slotLevelByLevel'] as List? ?? const [];
      if (index >= counts.length || index >= levels.length) return [];
      final count = (counts[index] as num).toInt();
      final spellLevel = (levels[index] as num).toInt();
      return count > 0 && spellLevel > 0 ? [MapEntry(spellLevel, count)] : [];
    }

    List<dynamic> slotsTable =
        casting['spellSlotsByLevel'] as List? ?? const [];
    if ((classData.id == 'fighter' || classData.id == 'rogue') &&
        casting['maxSpellLevel'] != null) {
      slotsTable = _thirdCasterSpellSlots;
    }

    if (index >= slotsTable.length) return [];
    final row = slotsTable[index] as List? ?? const [];
    final pools = <MapEntry<int, int>>[
      for (var slotIndex = 0; slotIndex < row.length; slotIndex++)
        if ((row[slotIndex] as num).toInt() > 0)
          MapEntry(slotIndex + 1, (row[slotIndex] as num).toInt()),
    ];
    if (classData.id == 'sorcerer') {
      for (var index = 0; index < pools.length; index++) {
        final level = pools[index].key;
        final created = widget.character.sorcererCreatedSpellSlots['$level'] ?? 0;
        if (created > 0) {
          pools[index] = MapEntry(level, pools[index].value + created);
        }
      }
    }
    return pools;
  }

  int _maximumSpellLevel(DndClassData classData, Map<String, dynamic> casting) {
    final pools = _currentSpellSlotPools(classData, casting);
    var maximum = pools.isEmpty ? 0 : pools.last.key;
    final subclassMaximum = casting['maxSpellLevel'];
    if (subclassMaximum is num) {
      maximum = maximum.clamp(0, subclassMaximum.toInt()).toInt();
    }
    return maximum;
  }

  bool _hasAvailableMysticArcanum(
    SpellData spell,
    List<SpellData> spells,
    Map<String, dynamic> casting,
  ) {
    if (spell.level < 6 || spell.level > 9) return false;
    final arcanum = casting['mysticArcanum'] as List? ?? const [];
    final unlocked = arcanum.any((entry) {
      if (entry is! Map) return false;
      final classLevel = (entry['classLevel'] as num?)?.toInt() ?? 21;
      final spellLevel = (entry['spellLevel'] as num?)?.toInt() ?? 0;
      return classLevel <= widget.character.level && spellLevel == spell.level;
    });
    if (!unlocked) return false;

    final chosenAtLevel =
        {
          ...widget.character.knownSpellIds,
          ...widget.character.preparedSpellIds,
          ...widget.character.spellbookSpellIds,
        }.any((id) {
          final knownSpell = _spellById(spells, id);
          return knownSpell?.level == spell.level;
        });
    return !chosenAtLevel &&
        !widget.character.mysticArcanumSpellIds.containsKey('${spell.level}');
  }

  bool _isSpellAvailable(
    SpellData spell,
    List<SpellData> allSpells,
    DndClassData classData,
    ClassSubclass? subclass,
    Map<String, dynamic> casting,
  ) {
    if (spell.level == 0) {
      // Cantrips are not gated by spell-slot progression.
    } else {
      final maximum = _maximumSpellLevel(classData, casting);
      final arcanumAvailable =
          classData.id == 'warlock' &&
          _hasAvailableMysticArcanum(spell, allSpells, casting);
      if (spell.level > maximum && !arcanumAvailable) {
        return false;
      }
    }

    final classSpell = spell.classes.any(
      (name) =>
          _sameName(name, classData.name) ||
          _sameName(name, classData.englishName) ||
          _sameName(name, classData.id),
    );
    final subclassSpell =
        subclass != null &&
        (spell.subclasses.contains(subclass.id) ||
            (classData.id == 'warlock' &&
                subclass.id == 'genie' &&
                widget.character.warlockGenieKind.isNotEmpty &&
                spell.subclasses.contains(
                  'genie_${widget.character.warlockGenieKind}',
                )));
    final subclassCastingClass = casting['class']?.toString();
    final subclassSpellList =
        subclassCastingClass != null &&
        spell.classes.any((name) => _sameName(name, subclassCastingClass));
    final alwaysPrepared =
        (subclass != null &&
            subclass.alwaysPreparedSpells.contains(spell.id)) ||
        (_isCircleOfLand(classData, subclass) &&
            _circleOfLandSpellIds(subclass).contains(spell.id));

    if (!classSpell &&
        !subclassSpell &&
        !subclassSpellList &&
        !alwaysPrepared) {
      return false;
    }

    final schools = casting['schools'] as List?;
    if (schools == null || schools.isEmpty || spell.level == 0) return true;
    if (schools.any((school) => _sameName(school.toString(), spell.school))) {
      return true;
    }

    final unrestrictedLevels =
        casting['anySchoolAtLevels'] as List? ?? const [];
    final unrestrictedCount = unrestrictedLevels
        .whereType<num>()
        .where((level) => level <= widget.character.level)
        .length;
    if (unrestrictedCount == 0) return false;

    final selectedIds = {
      ...widget.character.knownSpellIds,
      ...widget.character.preparedSpellIds,
    };
    final selectedOffSchool = selectedIds
        .map((id) => _spellById(allSpells, id))
        .whereType<SpellData>()
        .where(
          (knownSpell) =>
              knownSpell.level > 0 &&
              !schools.any(
                (school) => _sameName(school.toString(), knownSpell.school),
              ),
        )
        .length;
    return selectedOffSchool < unrestrictedCount;
  }

  bool _sameName(String left, String right) =>
      left.trim().toLowerCase() == right.trim().toLowerCase();

  bool _usesKnownSpellList(
    DndClassData classData,
    Map<String, dynamic> casting,
  ) {
    return casting['type'] == 'known' ||
        ((classData.id == 'fighter' || classData.id == 'rogue') &&
            casting['maxSpellLevel'] != null);
  }

  bool _usesPreparedSpellList(
    DndClassData classData,
    Map<String, dynamic> casting,
  ) {
    return casting['type'] == 'prepared' && classData.id != 'wizard';
  }

  int? _preparedSpellLimit(DndClassData classData) {
    final abilityKey = _spellcastingAbilityKey(classData);
    final level = widget.character.level.clamp(1, 20).toInt();
    if (classData.id == 'paladin' && level < 2) return 0;
    final levelTerm = switch (classData.id) {
      'cleric' || 'druid' || 'wizard' => level,
      'paladin' || 'artificer' => level ~/ 2,
      _ => null,
    };
    if (levelTerm == null) return null;

    final abilityScore =
        widget.character.effectiveAbilityScores[abilityKey] ?? 8;
    final limit = _modifier(abilityScore) + levelTerm;
    return limit < 1 ? 1 : limit;
  }

  String _spellcastingAbilityKey(DndClassData classData) {
    return switch (classData.id) {
      'bard' || 'paladin' || 'sorcerer' || 'warlock' => 'cha',
      'cleric' || 'druid' || 'ranger' => 'wis',
      'wizard' || 'artificer' || 'fighter' || 'rogue' => 'int',
      _ => 'int',
    };
  }

  void _showSpellLimitMessage(int limit) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Можно подготовить не более $limit заклинаний.')),
    );
  }

  Future<void> _addMagicItem() async {
    final items = await loadMagicItems();
    if (!mounted) return;
    final selected = await showDialog<MagicItemData>(
      context: context,
      builder: (context) => _MagicItemPickerDialog(items: items),
    );
    if (selected == null) return;
    widget.character.inventoryItems.add({
      'id': selected.id,
      'name': selected.name,
      'quantity': 1,
      'category': selected.category,
      'equipped': false,
      'magical': true,
    });
    await _persist();
  }

  Future<void> _addCustomItem() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить предмет'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Название предмета'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    widget.character.inventoryItems.add({
      'id': 'custom_${DateTime.now().microsecondsSinceEpoch}',
      'name': name,
      'quantity': 1,
      'category': 'other',
      'equipped': false,
      'magical': false,
    });
    await _persist();
  }

  Future<void> _changeCurrency(String key, int delta) async {
    final current = widget.character.currency[key] ?? 0;
    widget.character.currency[key] = (current + delta).clamp(0, 999999).toInt();
    await _persist();
  }

  DndClassData? _findCharacterClass(List<DndClassData> classes) {
    for (final item in classes) {
      if (item.name == widget.character.characterClass ||
          item.englishName == widget.character.characterClass ||
          item.id == widget.character.characterClass) {
        return item;
      }
    }

    return null;
  }

  int get _initiative =>
      _modifier(widget.character.effectiveAbilityScores['dex'] ?? 8);

  int get _passivePerception {
    final wisdom = _modifier(
      widget.character.effectiveAbilityScores['wis'] ?? 8,
    );
    final proficient = widget.character.allSkillProficiencies.any(
      (skill) =>
          skill.toLowerCase().contains('воспр') ||
          skill.toLowerCase().contains('perception'),
    );
    return 10 +
        wisdom +
        (proficient ? (widget.character.level >= 5 ? 3 : 2) : 0);
  }


  @override
  Widget build(BuildContext context) {
    final character = widget.character;
    final proficiency = 2 + ((character.level - 1) ~/ 4);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Лист персонажа'), centerTitle: true),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final abilityWidth =
                (constraints.maxWidth * 0.205).clamp(70.0, 88.0).toDouble();
            final availableHeight = constraints.maxHeight;
            // The profile photo adapts to the actual screen height so the
            // complete main sheet remains visible without page scrolling.
            final portraitHeight =
                (availableHeight * 0.145).clamp(72.0, 148.0).toDouble();
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: abilityWidth,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 3, 4),
                    child: _buildAbilityColumn(character, proficiency, theme),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(3, 4, 8, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopPanel(
                          character,
                          theme,
                          portraitHeight: portraitHeight,
                        ),
                        const SizedBox(height: 4),
                        _buildQuickActionsPanel(theme),
                        const SizedBox(height: 4),
                        _buildStatsPanel(theme),
                        const SizedBox(height: 4),
                        _buildGameArea(theme),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopPanel(
    Character character,
    ThemeData theme, {
    required double portraitHeight,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: portraitHeight,
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.add_a_photo_outlined,
              color: theme.colorScheme.onSurfaceVariant,
              size: 42,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 2, 7, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  character.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (character.race.isNotEmpty)
                  _identityLine(Icons.person, 'Раса: ${character.race}', theme),
                if (character.characterClass.isNotEmpty || character.subclassName.isNotEmpty)
                  _identityLine(
                    Icons.military_tech,
                    [
                      if (character.characterClass.isNotEmpty) 'Класс: ${character.characterClass}',
                      if (character.subclassName.isNotEmpty) 'Подкласс: ${character.subclassName}',
                    ].join(' · '),
                    theme,
                  ),
                const SizedBox(height: 1),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: character.level < 20 ? _levelUp : null,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Уровень ${character.level}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _identityLine(IconData icon, String text, ThemeData theme) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Icon(icon, size: 17, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );

  Widget _buildStatsPanel(ThemeData theme) {
    final character = widget.character;
    final stats = <(String, String, IconData)>[
      // Верхний ряд: инициатива, HP, скорость.
      ('Иниц.', _signed(_initiative), Icons.bolt),
      ('HP', '${character.currentHitPoints}/${character.maxHitPoints}', Icons.favorite_border),
      ('Скор.', '—', Icons.directions_run),
      // Нижний ряд: КД, временные HP под HP, пассивное внимание под скоростью.
      ('КД', '—', Icons.shield_outlined),
      ('Врем. HP', '${character.temporaryHitPoints}', Icons.favorite_border),
      ('Пасс. вним.', '$_passivePerception', Icons.visibility_outlined),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        // Wider-than-tall cards reduce the block's height and help prevent
        // vertical overflow on shorter phones.
        childAspectRatio: 1.32,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          margin: EdgeInsets.zero,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(stat.$3, color: theme.colorScheme.primary, size: 20),
                const SizedBox(height: 1),
                Text(
                  stat.$1,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    stat.$2,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsPanel(ThemeData theme) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      child: Row(
        children: [
          Flexible(
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontSize: 12),
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.casino_outlined, size: 14),
                  label: Text('Физ.'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.casino, size: 14),
                  label: Text('Вирт.'),
                ),
              ],
              selected: {_useVirtualDice},
              onSelectionChanged: (value) =>
                  setState(() => _useVirtualDice = value.first),
            ),
          ),
          const SizedBox(width: 3),
          IconButton(
            tooltip: 'Короткий отдых',
            onPressed: null,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.coffee, size: 20),
          ),
          IconButton(
            tooltip: 'Долгий отдых',
            onPressed: null,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.bed_outlined, size: 20),
          ),
        ],
      ),
    ),
  );

  Widget _buildAbilityColumn(
    Character character,
    int proficiency,
    ThemeData theme,
  ) {
    const abilities = [
      ('str', 'СИЛ', 'Сила', Icons.fitness_center),
      ('dex', 'ЛОВ', 'Ловкость', Icons.air),
      ('con', 'ТЕЛ', 'Телосложение', Icons.favorite_border),
      ('int', 'ИНТ', 'Интеллект', Icons.menu_book_outlined),
      ('wis', 'МДР', 'Мудрость', Icons.visibility_outlined),
      ('cha', 'ХАР', 'Харизма', Icons.auto_awesome),
    ];
    return Column(
      children: [
        for (final ability in abilities)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: GestureDetector(
                onLongPress: () => _showAbilityDetails(ability.$3, ability.$1, character, proficiency),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(ability.$4, size: 24, color: theme.colorScheme.primary),
                        Text(ability.$2, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('${character.effectiveAbilityScores[ability.$1] ?? 8}', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        Text(_signed(_modifier(character.effectiveAbilityScores[ability.$1] ?? 8)), style: theme.textTheme.labelMedium),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showAbilityDetails(
    String name,
    String key,
    Character character,
    int proficiency,
  ) {
    final score = character.effectiveAbilityScores[key] ?? 8;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Значение: $score  •  Модификатор: ${_signed(_modifier(score))}',
              ),
              const SizedBox(height: 8),
              Text('Бонус мастерства: ${_signed(proficiency)}'),
              const SizedBox(height: 12),
              const Text(
                'Подробности спасбросков и навыков добавим следующим этапом.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameArea(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CombatScreen(character: widget.character)),
            );
            if (!mounted) return;
            setState(() {});
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 25),
                const SizedBox(width: 10),
                Expanded(child: Text('Бой', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
                Icon(Icons.chevron_right, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 3),
      _sectionCard(
        'Особенности персонажа',
        Icons.auto_awesome,
        'Расовые особенности, класс и подкласс, черты и предыстория будут собраны здесь',
        theme,
      ),
      const SizedBox(height: 3),
      _buildInventorySection(theme),
      const SizedBox(height: 3),
      _buildMagicSection(theme),
    ],
  );

  Widget _buildInventorySection(ThemeData theme) {
    final character = widget.character;
    const coins = [
      ('cp', 'ММ'),
      ('sp', 'СМ'),
      ('ep', 'ЭМ'),
      ('gp', 'ЗМ'),
      ('pp', 'ПМ'),
    ];
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        leading: Icon(
          Icons.backpack,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        title: Text('Инвентарь', style: theme.textTheme.titleSmall),
        subtitle: Text('${character.inventoryItems.length} предмет(ов)'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Экипировка и рюкзак', style: theme.textTheme.labelLarge),
                if (character.inventoryItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Пока нет предметов. Добавь предмет вручную или из справочника.',
                    ),
                  ),
                for (final item in character.inventoryItems)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(item['name']?.toString() ?? 'Предмет'),
                    subtitle: Text(
                      'Количество: ${item['quantity'] ?? 1}${item['equipped'] == true ? ' · Надето' : ' · В рюкзаке'}',
                    ),
                    trailing: Wrap(
                      spacing: 0,
                      children: [
                        IconButton(
                          tooltip: item['equipped'] == true
                              ? 'Убрать из экипировки'
                              : 'Экипировать',
                          onPressed: () async {
                            item['equipped'] = !(item['equipped'] == true);
                            await _persist();
                          },
                          icon: Icon(
                            item['equipped'] == true
                                ? Icons.check_circle
                                : Icons.shield_outlined,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Удалить',
                          onPressed: () async {
                            character.inventoryItems.remove(item);
                            await _persist();
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _addCustomItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить предмет'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _addMagicItem,
                      icon: const Icon(Icons.diamond_outlined),
                      label: const Text('Из справочника'),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Text('Кошелёк', style: theme.textTheme.labelLarge),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    for (final coin in coins)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${coin.$2}: ${character.currency[coin.$1] ?? 0}',
                            ),
                            IconButton(
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: () => _changeCurrency(coin.$1, -1),
                              icon: const Icon(Icons.remove, size: 15),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: () => _changeCurrency(coin.$1, 1),
                              icon: const Icon(Icons.add, size: 15),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicSection(ThemeData theme) {
    return FutureBuilder<List<DndClassData>>(
      future: loadClasses(),
      builder: (context, snapshot) {
        final classData = snapshot.hasData
            ? _findCharacterClass(snapshot.data!)
            : null;
        final subclass = classData == null
            ? null
            : _findCharacterSubclass(classData);
        final casting = classData?.spellcasting ?? subclass?.spellcasting;

        if (classData == null || casting == null) {
          return const SizedBox.shrink();
        }
        if (classData.id == 'ranger' &&
            widget.character.level < 2 &&
            widget.character.knownCantripIds.isEmpty &&
            widget.character.knownSpellIds.isEmpty &&
            widget.character.preparedSpellIds.isEmpty) {
          return const SizedBox.shrink();
        }

        final slotPools = _currentSpellSlotPools(classData, casting);
        final abilityName = (casting['ability'] ?? '—').toString();
        final abilityKey = _spellcastingAbilityKey(classData);
        final abilityMod = _modifier(
          widget.character.effectiveAbilityScores[abilityKey] ?? 8,
        );
        final proficiency = 2 + ((widget.character.level - 1) ~/ 4);
        final saveDc = 8 + proficiency + abilityMod;
        final attackBonus = proficiency + abilityMod;

        return Card(
          margin: EdgeInsets.zero,
          child: ExpansionTile(
            leading: Icon(
              Icons.auto_awesome,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            title: Text('Магия', style: theme.textTheme.titleSmall),
            subtitle: Text(
              'Сл спасброска $saveDc · Атака ${_signed(attackBonus)}',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Характеристика: $abilityName',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    if (classData.id == 'sorcerer')
                      _buildSorcererResources(theme),
                    if (_isCircleOfLand(classData, subclass))
                      _buildCircleOfLandTerrainInfo(),
                    if (slotPools.isNotEmpty) ...[
                      if (classData.id == 'warlock')
                        Text(
                          'Pact Magic · ${slotPools.first.value} ячеек ${slotPools.first.key}-го круга',
                          style: theme.textTheme.labelLarge,
                        ),
                      Text(
                        'Ячейки заклинаний',
                        style: theme.textTheme.labelLarge,
                      ),
                      for (final pool in slotPools)
                        Row(
                          children: [
                            SizedBox(
                              width: 64,
                              child: Text('${pool.key} круг'),
                            ),
                            Expanded(
                              child: Text(
                                '${(widget.character.usedSpellSlots['${pool.key}'] ?? 0).clamp(0, pool.value)} / ${pool.value} использовано',
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                final key = '${pool.key}';
                                final used =
                                    widget.character.usedSpellSlots[key] ?? 0;
                                if (used < pool.value) {
                                  widget.character.usedSpellSlots[key] =
                                      used + 1;
                                  await _persist();
                                }
                              },
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 19,
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                final key = '${pool.key}';
                                final used =
                                    widget.character.usedSpellSlots[key] ?? 0;
                                if (used > 0) {
                                  widget.character.usedSpellSlots[key] =
                                      used - 1;
                                  await _persist();
                                }
                              },
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 19,
                              ),
                            ),
                          ],
                        ),
                      if (classData.id != 'warlock')
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: classData.id == 'sorcerer'
                                ? () => _restoreSorcererResources(longRest: true)
                                : () async {
                                    widget.character.usedSpellSlots.clear();
                                    await _persist();
                                  },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text(
                              classData.id == 'ranger' || classData.id == 'sorcerer'
                                  ? 'Долгий отдых · восстановить ресурсы'
                                  : 'Восстановить ячейки',
                            ),
                          ),
                        ),
                      if (classData.id == 'warlock')
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  _restoreWarlockResources(longRest: false),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Короткий отдых'),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  _restoreWarlockResources(longRest: true),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Долгий отдых'),
                            ),
                          ],
                        ),
                      if (classData.id == 'warlock' &&
                          widget.character.level >= 20 &&
                          !widget.character.usedEldritchMaster)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _useEldritchMaster,
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text(
                              'Мастер потусторонних сил · восстановить ячейки',
                            ),
                          ),
                        ),
                    ],
                    const Divider(),
                    Text('Заклинания', style: theme.textTheme.labelLarge),
                    FutureBuilder<List<SpellData>>(
                      future: loadSpells(),
                      builder: (context, spellSnapshot) {
                        if (!spellSnapshot.hasData) {
                          return const LinearProgressIndicator();
                        }

                        final all = spellSnapshot.data!;
                        final unlockedAlwaysPreparedIds =
                            _unlockedAlwaysPreparedIds(
                              all,
                              classData,
                              subclass,
                              casting,
                            );
                        final rangerSubclassSpellIds =
                            _unlockedRangerSubclassSpellIds(
                              all,
                              classData,
                              subclass,
                            );
                        if (classData.id == 'wizard') {
                          return _buildWizardSpellSections(
                            all,
                            classData,
                            subclass,
                            casting,
                            unlockedAlwaysPreparedIds,
                            theme,
                          );
                        }
                        if (classData.id == 'bard') {
                          return _buildBardSpellSections(
                            all,
                            classData,
                            casting,
                            theme,
                          );
                        }
                        final selectedIds = <String>{
                          ...widget.character.knownCantripIds,
                          ...widget.character.knownSpellIds,
                          ...widget.character.bardMagicalSecretSpellIds,
                          ...widget.character.loreAdditionalSpellIds,
                          ...widget.character.preparedSpellIds,
                          ...widget.character.spellbookSpellIds,
                          ...widget.character.spellMasterySpellIds,
                          ...widget.character.signatureSpellIds,
                          ...unlockedAlwaysPreparedIds,
                          ...rangerSubclassSpellIds,
                        };
                        final selected =
                            all
                                .where(
                                  (spell) => selectedIds.contains(spell.id),
                                )
                                .toList()
                              ..sort((a, b) {
                                final level = a.level.compareTo(b.level);
                                return level != 0
                                    ? level
                                    : a.name.compareTo(b.name);
                              });
                        final knownIds = <String>{
                          ...widget.character.knownSpellIds,
                          ...widget.character.bardMagicalSecretSpellIds,
                          ...widget.character.preparedSpellIds,
                        };
                        final cantripIds = <String>{
                          ...widget.character.knownCantripIds,
                          ...widget.character.knownSpellIds,
                          ...widget.character.bardMagicalSecretSpellIds,
                          ...widget.character.loreAdditionalSpellIds,
                          ...widget.character.preparedSpellIds,
                          ...widget.character.spellbookSpellIds,
                        };
                        final cantripLimit = _cantripLimit(classData, casting);
                        final preparedLimit = _preparedSpellLimit(classData);
                        final preparedCount = _selectedSpellCount(
                          all,
                          widget.character.preparedSpellIds
                              .where(
                                (id) => !unlockedAlwaysPreparedIds.contains(id),
                              )
                              .toSet(),
                          cantrips: false,
                        );
                        final knownLimit = _progressionLimit(
                          classData,
                          casting,
                          'spellsKnownByLevel',
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _spellCapacitySummary(
                                all,
                                classData,
                                casting,
                                unlockedAlwaysPreparedIds,
                                knownIds,
                                cantripIds,
                                cantripLimit,
                                preparedCount,
                                preparedLimit,
                                knownLimit,
                              ),
                              style: theme.textTheme.bodySmall,
                            ),
                            if (selected.isEmpty)
                              const Text('Пока не добавлены.'),
                            for (final spell in selected)
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: _spellInfoButton(spell),
                                title: Text(spell.name),
                                subtitle: Text(
                                  _spellStatus(
                                    spell,
                                    classData,
                                    unlockedAlwaysPreparedIds,
                                    rangerSubclassSpellIds,
                                  ),
                                ),
                                trailing: _spellActions(
                                  spell,
                                  classData,
                                  unlockedAlwaysPreparedIds,
                                  rangerSubclassSpellIds,
                                ),
                              ),
                            if (classData.id == 'warlock') ...[
                              const SizedBox(height: 8),
                              _buildWarlockArcanumSection(
                                all,
                                classData,
                                casting,
                                theme,
                              ),
                            ],
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton.tonalIcon(
                                onPressed: _addSpell,
                                icon: const Icon(Icons.add),
                                label: const Text('Добавить заклинание'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openWizardSpellbook(
    List<SpellData> spells,
    DndClassData classData,
    ClassSubclass? subclass,
    Map<String, dynamic> casting,
  ) async {
    final eligibleWizardSpells = spells
        .where(
          (spell) =>
              spell.level > 0 &&
              _isSpellAvailable(spell, spells, classData, subclass, casting),
        )
        .toList();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WizardSpellbookScreen(
          character: widget.character,
          allSpells: spells,
          eligibleWizardSpells: eligibleWizardSpells,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _addWizardCantrip(
    List<SpellData> spells,
    DndClassData classData,
    ClassSubclass? subclass,
    Map<String, dynamic> casting,
  ) async {
    final knownCantrips = widget.character.knownCantripIds.toSet();
    final limit = _cantripLimit(classData, casting);
    final count = _selectedSpellCount(spells, knownCantrips, cantrips: true);
    if (limit != null && count >= limit) {
      _showSpellLimitMessage(limit);
      return;
    }
    final available = spells.where((spell) {
      return spell.level == 0 &&
          !knownCantrips.contains(spell.id) &&
          _isSpellAvailable(spell, spells, classData, subclass, casting);
    }).toList();
    final selected = await showDialog<SpellData>(
      context: context,
      builder: (context) =>
          _SpellPickerDialog(spells: available, showSchoolFilter: true),
    );
    if (selected == null) return;
    if (!widget.character.knownCantripIds.contains(selected.id)) {
      widget.character.knownCantripIds.add(selected.id);
      await _persist();
    }
  }

  Future<void> _removeWizardCantrip(String id) async {
    widget.character.knownCantripIds.removeWhere(
      (cantripId) => cantripId == id,
    );
    await _persist();
  }

  Future<void> _chooseWarlockArcanum(
    List<SpellData> spells,
    DndClassData classData,
    int spellLevel,
  ) async {
    final levelKey = '$spellLevel';
    if (widget.character.mysticArcanumSpellIds.containsKey(levelKey)) return;
    final alreadyUsedIds = {
      ...widget.character.knownCantripIds,
      ...widget.character.knownSpellIds,
      ...widget.character.preparedSpellIds,
      ...widget.character.mysticArcanumSpellIds.values,
    };
    final available = spells.where((spell) {
      final patronSpell =
          spell.subclasses.contains(widget.character.subclassId) ||
          (widget.character.subclassId == 'genie' &&
              widget.character.warlockGenieKind.isNotEmpty &&
              spell.subclasses.contains(
                'genie_${widget.character.warlockGenieKind}',
              ));
      return spell.level == spellLevel &&
          !alreadyUsedIds.contains(spell.id) &&
          (patronSpell ||
              spell.classes.any(
                (name) =>
                    _sameName(name, classData.id) ||
                    _sameName(name, classData.name) ||
                    _sameName(name, classData.englishName),
              ));
    }).toList();
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) => SpellSelectionDialog(
        spells: available,
        selectionCount: 1,
        title:
            'Выбери заклинание $spellLevel-го круга для Мистического арканума',
      ),
    );
    if (selected == null || !mounted) return;
    widget.character.mysticArcanumSpellIds[levelKey] = selected.single;
    await _persist();
  }

  Future<void> _toggleMysticArcanumUse(int spellLevel) async {
    final used = widget.character.usedMysticArcanumSpellLevels;
    if (used.contains(spellLevel)) {
      used.remove(spellLevel);
    } else {
      used.add(spellLevel);
    }
    await _persist();
  }

  Future<void> _restoreWarlockResources({required bool longRest}) async {
    widget.character.usedSpellSlots.clear();
    if (longRest) {
      widget.character.usedMysticArcanumSpellLevels.clear();
      widget.character.usedEldritchMaster = false;
    }
    await _persist();
  }

  Future<void> _useEldritchMaster() async {
    if (widget.character.level < 20 || widget.character.usedEldritchMaster) {
      return;
    }
    widget.character.usedSpellSlots.clear();
    widget.character.usedEldritchMaster = true;
    await _persist();
  }

  Widget _buildWarlockArcanumSection(
    List<SpellData> spells,
    DndClassData classData,
    Map<String, dynamic> casting,
    ThemeData theme,
  ) {
    final pactMagic = casting['pactMagic'] as Map? ?? const {};
    final entries = (pactMagic['mysticArcanum'] as List? ?? const [])
        .whereType<Map>()
        .where(
          (entry) =>
              (entry['classLevel'] as num?)?.toInt() != null &&
              (entry['classLevel'] as num).toInt() <= widget.character.level,
        )
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Мистический арканум', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Каждое выбранное заклинание можно применить один раз; использование восстанавливается после продолжительного отдыха.',
              style: theme.textTheme.bodySmall,
            ),
            for (final entry in entries) ...[
              Builder(
                builder: (context) {
                  final spellLevel = (entry['spellLevel'] as num).toInt();
                  final levelKey = '$spellLevel';
                  final spellId =
                      widget.character.mysticArcanumSpellIds[levelKey];
                  final spell = spellId == null
                      ? null
                      : _spellById(spells, spellId);
                  final used = widget.character.usedMysticArcanumSpellLevels
                      .contains(spellLevel);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: spell == null ? null : _spellInfoButton(spell),
                    title: Text('$spellLevel-й круг'),
                    subtitle: Text(
                      spell?.name ?? 'Заклинание не выбрано',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: spell == null
                        ? IconButton(
                            tooltip: 'Выбрать арканум',
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _chooseWarlockArcanum(
                              spells,
                              classData,
                              spellLevel,
                            ),
                          )
                        : TextButton(
                            onPressed: () =>
                                _toggleMysticArcanumUse(spellLevel),
                            child: Text(used ? 'Использовано' : 'Готово · 1/1'),
                          ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWizardSpellSections(
    List<SpellData> spells,
    DndClassData classData,
    ClassSubclass? subclass,
    Map<String, dynamic> casting,
    Set<String> alwaysPreparedIds,
    ThemeData theme,
  ) {
    final bookIds = {
      ...widget.character.spellbookSpellIds,
      ...widget.character.knownSpellIds,
    };
    final preparedIds = widget.character.preparedSpellIds.toSet();
    final preparedSpells =
        preparedIds
            .map((id) => _spellById(spells, id))
            .whereType<SpellData>()
            .where(
              (spell) =>
                  spell.level > 0 && !alwaysPreparedIds.contains(spell.id),
            )
            .toList()
          ..sort((a, b) {
            final level = a.level.compareTo(b.level);
            return level != 0 ? level : a.name.compareTo(b.name);
          });
    final preparedCount = _selectedSpellCount(
      spells,
      preparedIds.where((id) => !alwaysPreparedIds.contains(id)).toSet(),
      cantrips: false,
    );
    final preparedLimit = _preparedSpellLimit(classData) ?? 0;
    final cantripLimit = _cantripLimit(classData, casting) ?? 0;
    final cantrips =
        widget.character.knownCantripIds
            .toSet()
            .map((id) => _spellById(spells, id))
            .whereType<SpellData>()
            .where((spell) => spell.level == 0)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final masterySpells = widget.character.spellMasterySpellIds
        .toSet()
        .map((id) => _spellById(spells, id))
        .whereType<SpellData>()
        .toList();
    final signatureSpells = widget.character.signatureSpellIds
        .toSet()
        .map((id) => _spellById(spells, id))
        .whereType<SpellData>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.tonalIcon(
          onPressed: () =>
              _openWizardSpellbook(spells, classData, subclass, casting),
          icon: const Icon(Icons.menu_book),
          label: Text('Книга заклинаний · ${bookIds.length}'),
        ),
        if (bookIds.length < 6)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'В книге меньше шести заклинаний. Открой книгу, чтобы дополнить её.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Подготовка · $preparedCount/$preparedLimit',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Выбирай только из книги. Снятие подготовки оставляет заклинание в книге.',
                  style: theme.textTheme.bodySmall,
                ),
                if (preparedSpells.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Нет подготовленных заклинаний.'),
                  ),
                for (final spell in preparedSpells)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: _spellInfoButton(spell),
                    title: Text(spell.name),
                    subtitle: Text(
                      bookIds.contains(spell.id)
                          ? '${spell.level} круг · Подготовлено'
                          : '${spell.level} круг · В книге отсутствует (старое сохранение)',
                    ),
                    trailing: IconButton(
                      tooltip: 'Снять подготовку, оставить книгу без изменений',
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () async {
                        widget.character.preparedSpellIds.removeWhere(
                          (id) => id == spell.id,
                        );
                        await _persist();
                      },
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _prepareWizardSpell,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Подготовить из книги'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Заговоры · ${cantrips.length}/$cantripLimit',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Не входят в книгу и не расходуют лимит подготовки.',
                  style: theme.textTheme.bodySmall,
                ),
                if (cantrips.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Нет выбранных заговоров.'),
                  ),
                for (final spell in cantrips)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: _spellInfoButton(spell),
                    title: Text(spell.name),
                    subtitle: Text('Заговор · ${spell.school}'),
                    trailing: IconButton(
                      tooltip: 'Удалить заговор',
                      icon: const Icon(Icons.close),
                      onPressed: () => _removeWizardCantrip(spell.id),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        _addWizardCantrip(spells, classData, subclass, casting),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить заговор'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.character.level >= 18) ...[
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Особые возможности волшебника',
                    style: theme.textTheme.titleSmall,
                  ),
                  if (widget.character.level >= 18) ...[
                    const SizedBox(height: 8),
                    const Text('Spell Mastery · 18-й уровень'),
                    Text(
                      'Выбранные заклинания можно накладывать без ячейки, когда они подготовлены.',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (masterySpells.isEmpty)
                      const Text('Заклинания Spell Mastery не выбраны.'),
                    for (final spell in masterySpells)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: _spellInfoButton(spell),
                        title: Text(spell.name),
                        subtitle: Text('${spell.level} круг · Spell Mastery'),
                      ),
                  ],
                  if (widget.character.level >= 20) ...[
                    const Divider(),
                    const Text('Signature Spells · 20-й уровень'),
                    Text(
                      'Всегда подготовлены и не расходуют обычный лимит подготовки.',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (signatureSpells.isEmpty)
                      const Text('Signature Spells не выбраны.'),
                    for (final spell in signatureSpells)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: _spellInfoButton(spell),
                        title: Text(spell.name),
                        subtitle: const Text('Всегда подготовлено · Signature Spells'),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  static const Map<String, String> _sorcererMetamagicNames = {
    'careful_spell': 'Аккуратное заклинание',
    'distant_spell': 'Далёкое заклинание',
    'empowered_spell': 'Усиленное заклинание',
    'extended_spell': 'Продлённое заклинание',
    'heightened_spell': 'Усиленное воздействие',
    'quickened_spell': 'Быстрое заклинание',
    'subtle_spell': 'Незаметное заклинание',
    'twinned_spell': 'Сдвоенное заклинание',
  };

  Widget _buildSorcererResources(ThemeData theme) {
    final character = widget.character;
    // Font of Magic появляется только на 2-м уровне.
    if (character.level < 2) return const SizedBox.shrink();
    final maximum = character.level;
    final used = character.usedSorceryPoints.clamp(0, maximum);
    final known = character.sorcererMetamagicOptions
        .map((id) => _sorcererMetamagicNames[id])
        .whereType<String>()
        .toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Источник магии', style: theme.textTheme.titleSmall),
            Text('Очки чародейства: ${maximum - used} / $maximum'),
            Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 0,
              children: [
                IconButton(
                  tooltip: 'Потратить 1 очко',
                  onPressed: used < maximum
                      ? () async {
                          character.usedSorceryPoints = used + 1;
                          await _persist();
                        }
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                IconButton(
                  tooltip: 'Вернуть 1 очко',
                  onPressed: used > 0
                      ? () async {
                          character.usedSorceryPoints = used - 1;
                          await _persist();
                        }
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                TextButton(
                  onPressed: () => _restoreSorcererResources(longRest: true),
                  child: const Text('Долгий отдых'),
                ),
                if (character.level >= 20)
                  TextButton(
                    onPressed: () => _restoreSorcererResources(longRest: false),
                    child: const Text('Короткий отдых · 4 очка'),
                  ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (character.level >= 2) OutlinedButton.icon(
                  onPressed: used < maximum ? _createSorcererSpellSlot : null,
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Создать ячейку'),
                ),
                if (character.level >= 2) OutlinedButton.icon(
                  onPressed: used > 0 ? _convertSorcererSlotToPoints : null,
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Ячейка → очки'),
                ),
              ],
            ),
            if (character.level >= 3) ...[
              const Divider(),
              Text('Метамагия · ${known.length} варианта',
                  style: theme.textTheme.labelLarge),
              if (known.isEmpty)
                const Text('Варианты метамагии ещё не выбраны.')
              else
                for (final name in known) Text('• $name'),
            ],
          ],
        ),
      ),
    );
  }

  static const Map<int, int> _sorcererSlotCosts = {
    1: 2,
    2: 3,
    3: 5,
    4: 6,
    5: 7,
  };

  Future<void> _createSorcererSpellSlot() async {
    final character = widget.character;
    final classes = await loadClasses();
    if (!mounted) return;
    final classData = _findCharacterClass(classes);
    if (classData == null || classData.id != 'sorcerer') return;
    final casting = classData.spellcasting ?? const <String, dynamic>{};
    final table = casting['spellSlotsByLevel'] as List? ?? const [];
    final index = (character.level.clamp(1, 20) - 1).toInt();
    if (index >= table.length) return;
    final row = table[index] as List? ?? const [];
    final choices = <int>[];
    for (final entry in _sorcererSlotCosts.entries) {
      final slotLevel = entry.key;
      if (slotLevel > row.length) continue;
      final baseMaximum = (row[slotLevel - 1] as num).toInt();
      final created = character.sorcererCreatedSpellSlots['$slotLevel'] ?? 0;
      if (baseMaximum > 0 && created < baseMaximum &&
          character.usedSorceryPoints + entry.value <= character.level) {
        choices.add(slotLevel);
      }
    }
    if (choices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сейчас нельзя создать дополнительную ячейку.')),
      );
      return;
    }
    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Создать ячейку заклинания'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final level in choices)
              ListTile(
                title: Text('$level-й круг'),
                subtitle: Text('Стоимость: ${_sorcererSlotCosts[level]} очков чародейства'),
                onTap: () => Navigator.pop(dialogContext, level),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    final cost = _sorcererSlotCosts[selected]!;
    final currentUsed = character.usedSorceryPoints;
    if (currentUsed + cost > character.level) return;
    character.usedSorceryPoints = currentUsed + cost;
    final key = '$selected';
    character.sorcererCreatedSpellSlots[key] =
        (character.sorcererCreatedSpellSlots[key] ?? 0) + 1;
    await _persist();
  }

  Future<void> _convertSorcererSlotToPoints() async {
    final character = widget.character;
    final classes = await loadClasses();
    if (!mounted) return;
    final classData = _findCharacterClass(classes);
    if (classData == null || classData.id != 'sorcerer') return;
    final casting = classData.spellcasting ?? const <String, dynamic>{};
    final basePools = _currentSpellSlotPools(classData, casting);
    final choices = <int>[];
    for (final pool in basePools) {
      final level = pool.key;
      if (level > 5) continue;
      final total = pool.value;
      final used = character.usedSpellSlots['$level'] ?? 0;
      if (used < total && character.usedSorceryPoints - level >= 0) {
        choices.add(level);
      }
    }
    if (choices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет доступной ячейки 1–5-го круга или недостаточно места для очков.')),
      );
      return;
    }
    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Преобразовать ячейку в очки'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final level in choices)
              ListTile(
                title: Text('$level-й круг'),
                subtitle: Text('Вернёт $level ${level == 1 ? 'очко' : 'очка'} чародейства'),
                onTap: () => Navigator.pop(dialogContext, level),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    final used = character.usedSpellSlots['$selected'] ?? 0;
    final total = basePools.firstWhere((pool) => pool.key == selected).value;
    if (used >= total || character.usedSorceryPoints < selected) return;
    character.usedSpellSlots['$selected'] = used + 1;
    character.usedSorceryPoints -= selected;
    await _persist();
  }

  Future<void> _restoreSorcererResources({required bool longRest}) async {
    final character = widget.character;
    if (longRest) {
      character.usedSorceryPoints = 0;
      character.usedSpellSlots.clear();
      character.sorcererCreatedSpellSlots.clear();
    } else if (character.level >= 20) {
      character.usedSorceryPoints =
          (character.usedSorceryPoints - 4).clamp(0, character.level);
    }
    await _persist();
  }

  Widget _buildBardSpellSections(
    List<SpellData> allSpells,
    DndClassData classData,
    Map<String, dynamic> casting,
    ThemeData theme,
  ) {
    final bardSecretIds = widget.character.bardMagicalSecretSpellIds.toSet();
    final loreSecretIds = widget.character.loreAdditionalSpellIds.toSet();
    final claimedIds = <String>{};

    List<SpellData> resolveIds(Iterable<String> ids) {
      final result = <SpellData>[];
      for (final id in ids) {
        if (!claimedIds.add(id)) continue;
        final spell = _spellById(allSpells, id);
        if (spell != null) result.add(spell);
      }
      result.sort((a, b) {
        final level = a.level.compareTo(b.level);
        return level != 0 ? level : a.name.compareTo(b.name);
      });
      return result;
    }

    final magicalSecrets = resolveIds(bardSecretIds);
    final loreSecrets = resolveIds(loreSecretIds);
    final cantrips = resolveIds(widget.character.knownCantripIds).where((spell) {
      return spell.level == 0;
    }).toList();
    final regularSpells = resolveIds(widget.character.knownSpellIds).where((spell) {
      return spell.level > 0;
    }).toList();
    final knownCount = _selectedSpellCount(
      allSpells,
      {
        ...widget.character.knownSpellIds,
        ...widget.character.bardMagicalSecretSpellIds,
      },
      cantrips: false,
    );
    final knownLimit = _progressionLimit(
      classData,
      casting,
      'spellsKnownByLevel',
    );
    // Магические секреты хранятся отдельно и не расходуют обычный лимит
    // заговоров барда.
    final cantripCount = _selectedSpellCount(
      allSpells,
      widget.character.knownCantripIds.toSet(),
      cantrips: true,
    );
    final cantripLimit = _cantripLimit(classData, casting) ?? 0;
    final slotPools = _currentSpellSlotPools(classData, casting);
    final mastery = _modifier(
      widget.character.effectiveAbilityScores['cha'] ?? 8,
    );
    final proficiency = 2 + ((widget.character.level - 1) ~/ 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Известно заклинаний: $knownCount/${knownLimit ?? 0}'),
        Text('Заговоры: $cantripCount/$cantripLimit'),
        for (final pool in slotPools)
          Text(
            '${pool.key}-й круг: ${((widget.character.usedSpellSlots['${pool.key}'] ?? 0).clamp(0, pool.value))} / ${pool.value} использовано',
          ),
        Text('Ритуальное колдовство: известные ритуалы без расхода ячейки'),
        const SizedBox(height: 8),
        _buildBardSpellGroup('Заговоры', cantrips, allSpells, classData),
        _buildBardSpellGroup(
          'Известные заклинания',
          regularSpells,
          allSpells,
          classData,
        ),
        _buildBardSpellGroup(
          'Магические секреты',
          magicalSecrets,
          allSpells,
          classData,
        ),
        if (classData.id == 'bard' &&
            widget.character.subclassId == 'college_of_lore')
          _buildBardSpellGroup(
            'Дополнительные секреты Коллегии знаний',
            loreSecrets,
            allSpells,
            classData,
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: _addSpell,
            icon: const Icon(Icons.add),
            label: const Text('Добавить известное заклинание'),
          ),
        ),
        if (slotPools.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                widget.character.usedSpellSlots.clear();
                await _persist();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Продолжительный отдых · восстановить ячейки'),
            ),
          ),
        Text(
          'Харизма · Сл спасброска ${8 + proficiency + mastery} · атака заклинанием +${proficiency + mastery}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildBardSpellGroup(
    String title,
    List<SpellData> spells,
    List<SpellData> allSpells,
    DndClassData classData,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ExpansionTile(
        dense: true,
        title: Text('$title · ${spells.length}'),
        children: [
          if (spells.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Пока нет заклинаний.'),
            ),
          for (final spell in spells)
            ListTile(
              dense: true,
              leading: _spellInfoButton(spell),
              title: Text(spell.name),
              subtitle: Text(
                _spellStatus(spell, classData, const <String>{}),
              ),
              trailing: _spellActions(
                spell,
                classData,
                const <String>{},
              ),
            ),
        ],
      ),
    );
  }

  String _spellCapacitySummary(
    List<SpellData> spells,
    DndClassData classData,
    Map<String, dynamic> casting,
    Set<String> alwaysPreparedIds,
    Set<String> knownIds,
    Set<String> cantripIds,
    int? cantripLimit,
    int preparedCount,
    int? preparedLimit,
    int? knownLimit,
  ) {
    final cantrips = _selectedSpellCount(spells, cantripIds, cantrips: true);
    final cantripLabel = cantripLimit == null
        ? '$cantrips заговоров'
        : '$cantrips/$cantripLimit заговоров';
    if (classData.id == 'wizard') {
      final bookIds = {
        ...widget.character.spellbookSpellIds,
        ...widget.character.knownSpellIds,
      };
      return 'Книга: ${bookIds.length} · Подготовлено: $preparedCount/${preparedLimit ?? 0} · $cantripLabel';
    }
    if (_usesKnownSpellList(classData, casting)) {
      final knownCount = _selectedSpellCount(
        spells,
        knownIds,
        cantrips: false,
        excludeWarlockArcanum: classData.id == 'warlock',
      );
      final knownLabel = knownLimit == null
          ? '$knownCount известных'
          : '$knownCount/$knownLimit известных';
      final alwaysLabel = alwaysPreparedIds.isEmpty
          ? ''
          : ' · ${alwaysPreparedIds.length} всегда подготовлено';
      return '$knownLabel · $cantripLabel$alwaysLabel';
    }
    final alwaysLabel = alwaysPreparedIds.isEmpty
        ? ''
        : ' · ${alwaysPreparedIds.length} всегда подготовлено';
    final preparedLabel = preparedLimit == null
        ? '$preparedCount подготовлено'
        : '$preparedCount/$preparedLimit подготовлено';
    return '$preparedLabel · $cantripLabel$alwaysLabel';
  }

  Widget? _spellActions(
    SpellData spell,
    DndClassData classData,
    Set<String> alwaysPreparedIds, [
    Set<String> rangerSubclassSpellIds = const <String>{},
  ]) {
    final character = widget.character;
    final isAlwaysOnly =
        alwaysPreparedIds.contains(spell.id) &&
        !character.knownCantripIds.contains(spell.id) &&
        !character.knownSpellIds.contains(spell.id) &&
        !character.bardMagicalSecretSpellIds.contains(spell.id) &&
        !character.loreAdditionalSpellIds.contains(spell.id) &&
        !character.preparedSpellIds.contains(spell.id) &&
        !character.spellbookSpellIds.contains(spell.id);

    if (isAlwaysOnly || rangerSubclassSpellIds.contains(spell.id)) {
      return null;
    }
    if (classData.id == 'wizard' && spell.level > 0) {
      final inBook =
          character.spellbookSpellIds.contains(spell.id) ||
          character.knownSpellIds.contains(spell.id);
      final isPrepared = character.preparedSpellIds.contains(spell.id);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPrepared)
            IconButton(
              tooltip: 'Снять подготовку, оставить в книге',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () async {
                character.preparedSpellIds.removeWhere((id) => id == spell.id);
                await _persist();
              },
            ),
          if (inBook)
            IconButton(
              tooltip: 'Удалить из книги и снять подготовку',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                character.spellbookSpellIds.removeWhere((id) => id == spell.id);
                character.knownSpellIds.removeWhere((id) => id == spell.id);
                character.preparedSpellIds.removeWhere((id) => id == spell.id);
                character.spellMasterySpellIds.removeWhere(
                  (id) => id == spell.id,
                );
                character.signatureSpellIds.removeWhere((id) => id == spell.id);
                await _persist();
              },
            ),
          if (!inBook && !isPrepared)
            IconButton(
              tooltip: 'Удалить',
              icon: const Icon(Icons.close),
              onPressed: () async {
                character.knownCantripIds.remove(spell.id);
                character.knownSpellIds.remove(spell.id);
                character.bardMagicalSecretSpellIds.remove(spell.id);
                character.loreAdditionalSpellIds.remove(spell.id);
                character.preparedSpellIds.remove(spell.id);
                character.spellbookSpellIds.remove(spell.id);
                await _persist();
              },
            ),
        ],
      );
    }
    return IconButton(
      icon: const Icon(Icons.close),
      onPressed: () async {
        character.knownCantripIds.remove(spell.id);
        character.knownSpellIds.remove(spell.id);
        character.bardMagicalSecretSpellIds.remove(spell.id);
        character.loreAdditionalSpellIds.remove(spell.id);
        character.preparedSpellIds.remove(spell.id);
        character.spellbookSpellIds.remove(spell.id);
        await _persist();
      },
    );
  }

  String _spellStatus(
    SpellData spell,
    DndClassData classData,
    Set<String> alwaysPreparedIds, [
    Set<String> rangerSubclassSpellIds = const <String>{},
  ]) {
    final labels = <String>[];
    if (spell.level == 0) labels.add('Заговор');
    if (classData.id == 'bard') {
      if (widget.character.bardMagicalSecretSpellIds.contains(spell.id)) {
        labels.add('Магический секрет');
      }
      if (widget.character.loreAdditionalSpellIds.contains(spell.id)) {
        labels.add('Дополнительный секрет Коллегии знаний');
      }
    }

    if (alwaysPreparedIds.contains(spell.id)) {
      labels.add('Всегда подготовлено');
    }

    if (rangerSubclassSpellIds.contains(spell.id)) {
      labels.add('Subclass spell · automatically known');
    }

    if (spell.level > 0) {
      final isKnown = widget.character.knownSpellIds.contains(spell.id);
      final isPrepared = widget.character.preparedSpellIds.contains(spell.id);
      if (classData.id == 'wizard') {
        final inBook =
            widget.character.spellbookSpellIds.contains(spell.id) || isKnown;
        if (widget.character.spellMasterySpellIds.contains(spell.id)) {
          labels.add('Spell Mastery');
        }
        if (widget.character.signatureSpellIds.contains(spell.id)) {
          labels.add('Signature Spell');
        }
        if (isPrepared) labels.add('Подготовлено');
        if (inBook) labels.add('Книга заклинаний');
      } else if (classData.id == 'warlock' && spell.level > 5) {
        labels.add('Мистический арканум');
      } else if (classData.spellcasting?['type'] == 'known' ||
          classData.id == 'fighter' ||
          classData.id == 'rogue') {
        if (isKnown || isPrepared) labels.add('Известно');
      } else if (isPrepared) {
        labels.add('Подготовлено');
      } else if (isKnown) {
        labels.add('Сохранено ранее');
      }
    }

    if (spell.level > 0) labels.insert(0, '${spell.level} круг');
    return labels.isEmpty ? 'Заклинание' : labels.join(' · ');
  }

  Widget _sectionCard(
    String title,
    IconData icon,
    String subtitle,
    ThemeData theme,
  ) => Card(
    margin: EdgeInsets.zero,
    child: ExpansionTile(
      dense: true,
      leading: Icon(icon, color: theme.colorScheme.primary, size: 20),
      title: Text(title, style: theme.textTheme.titleSmall),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(subtitle, style: theme.textTheme.bodySmall),
        ),
      ],
    ),
  );
}
// ============================================================
// ОКНО ВЫБОРА ЗАКЛИНАНИЙ
// ============================================================

class _SpellPickerDialog extends StatefulWidget {
  final List<SpellData> spells;
  final bool showSchoolFilter;

  const _SpellPickerDialog({
    required this.spells,
    this.showSchoolFilter = false,
  });

  @override
  State<_SpellPickerDialog> createState() => _SpellPickerDialogState();
}

class _SpellPickerDialogState extends State<_SpellPickerDialog> {
  final TextEditingController _searchController = TextEditingController();

  int? _selectedLevel;
  String? _selectedSchool;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered =
        widget.spells.where((spell) {
          final matchesQuery =
              query.isEmpty ||
              spell.name.toLowerCase().contains(query) ||
              spell.englishName.toLowerCase().contains(query);

          final matchesLevel =
              _selectedLevel == null || spell.level == _selectedLevel;
          final matchesSchool =
              !widget.showSchoolFilter ||
              _selectedSchool == null ||
              spell.school == _selectedSchool;

          return matchesQuery && matchesLevel && matchesSchool;
        }).toList()..sort((a, b) {
          final levelCompare = a.level.compareTo(b.level);

          return levelCompare != 0 ? levelCompare : a.name.compareTo(b.name);
        });

    return AlertDialog(
      title: const Text('Выбрать заклинание'),
      content: SizedBox(
        width: double.maxFinite,
        height: 480,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск заклинания',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<int?>(
              initialValue: _selectedLevel,
              decoration: const InputDecoration(
                labelText: 'Уровень',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Все уровни'),
                ),
                for (var level = 0; level <= 9; level++)
                  DropdownMenuItem<int?>(
                    value: level,
                    child: Text(level == 0 ? 'Заговоры' : '$level уровень'),
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLevel = value;
                });
              },
            ),

            if (widget.showSchoolFilter) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _selectedSchool,
                decoration: const InputDecoration(
                  labelText: 'Школа магии',
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Все школы'),
                  ),
                  for (final school
                      in (widget.spells
                          .map((spell) => spell.school)
                          .where((school) => school.isNotEmpty)
                          .toSet()
                          .toList()
                        ..sort()))
                    DropdownMenuItem<String?>(
                      value: school,
                      child: Text(school),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSchool = value;
                  });
                },
              ),
            ],

            const SizedBox(height: 8),

            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Ничего не найдено'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final spell = filtered[index];

                        return ListTile(
                          dense: true,
                          title: Text(spell.name),
                          subtitle: Text(
                            spell.level == 0
                                ? 'Заговор · ${spell.school}'
                                : '${spell.level} уровень · ${spell.school}',
                          ),
                          onTap: () {
                            Navigator.of(context).pop(spell);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Отмена'),
        ),
      ],
    );
  }
}

// ============================================================
// ОКНО ВЫБОРА МАГИЧЕСКИХ ПРЕДМЕТОВ
// ============================================================

class _MagicItemPickerDialog extends StatefulWidget {
  final List<MagicItemData> items;

  const _MagicItemPickerDialog({required this.items});

  @override
  State<_MagicItemPickerDialog> createState() => _MagicItemPickerDialogState();
}

class _MagicItemPickerDialogState extends State<_MagicItemPickerDialog> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = widget.items.where((item) {
      return query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.englishName.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.rarity.toLowerCase().contains(query);
    }).toList()..sort((a, b) => a.name.compareTo(b.name));

    return AlertDialog(
      title: const Text('Магические предметы'),
      content: SizedBox(
        width: double.maxFinite,
        height: 480,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск предмета',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Ничего не найдено'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];

                        return ListTile(
                          dense: true,
                          title: Text(item.name),
                          subtitle: Text(
                            [
                              if (item.rarity.isNotEmpty) item.rarity,
                              if (item.category.isNotEmpty) item.category,
                              if (item.requiresAttunement)
                                'Требуется настройка',
                            ].join(' · '),
                          ),
                          onTap: () {
                            Navigator.of(context).pop(item);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Отмена'),
        ),
      ],
    );
  }
}
