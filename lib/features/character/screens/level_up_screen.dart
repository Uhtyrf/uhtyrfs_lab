import 'dart:math';

import '../../../data/loaders/feat_loader.dart';
import '../../../models/feat_data.dart';
import '../../../data/loaders/spell_loader.dart';

import 'package:flutter/material.dart';

import '../../../data/loaders/class_loader.dart';
import '../../../models/class_data.dart';
import '../../../models/subclass_data.dart';
import '../../../models/spell_data.dart';
import '../models/character.dart';
import 'spell_selection_dialog.dart';

class LevelUpResult {
  final int newLevel;
  final int gainedHitPoints;
  final int newMaxHitPoints;
  final bool rolledHitDie;
  final List<String> newFeatures;
  final Map<String, int> abilityScoreIncreases;
  final String? selectedFeatId;
  final List<String> newSpellbookSpellIds;
  final List<String> newCantripIds;
  final List<String> newKnownSpellIds;
  final List<String> newBardMagicalSecretSpellIds;
  final List<String> newLoreAdditionalSpellIds;
  final String? replacedKnownSpellId;
  final Map<String, String> mysticArcanumSpellIds;
  final List<String> spellMasterySpellIds;
  final List<String> signatureSpellIds;
  final List<String> sorcererMetamagicOptions;

  const LevelUpResult({
    required this.newLevel,
    required this.gainedHitPoints,
    required this.newMaxHitPoints,
    required this.rolledHitDie,
    required this.newFeatures,
    required this.abilityScoreIncreases,
    required this.selectedFeatId,
    required this.newSpellbookSpellIds,
    required this.newCantripIds,
    required this.newKnownSpellIds,
    required this.newBardMagicalSecretSpellIds,
    required this.newLoreAdditionalSpellIds,
    required this.replacedKnownSpellId,
    required this.mysticArcanumSpellIds,
    required this.spellMasterySpellIds,
    required this.signatureSpellIds,
    required this.sorcererMetamagicOptions,
  });
}

class LevelUpScreen extends StatefulWidget {
  final Character character;

  const LevelUpScreen({super.key, required this.character});

  @override
  State<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _KnownSpellReplacementDialog extends StatelessWidget {
  final List<SpellData> knownSpells;
  final List<SpellData> replacementSpells;

  const _KnownSpellReplacementDialog({
    required this.knownSpells,
    required this.replacementSpells,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Заменить известное заклинание?'),
      content: SizedBox(
        width: double.maxFinite,
        height: 360,
        child: ListView(
          children: [
            for (final known in knownSpells)
              ExpansionTile(
                title: Text('Заменить: ${known.name}'),
                children: [
                  for (final replacement in replacementSpells)
                    ListTile(
                      dense: true,
                      title: Text(replacement.name),
                      subtitle: Text(
                        '${replacement.level}-й круг · ${replacement.school}',
                      ),
                      onTap: () =>
                          Navigator.of(context)
                              .pop(MapEntry(known.id, replacement.id)),
                    ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Оставить без замены'),
        ),
      ],
    );
  }
}

class _LevelUpScreenState extends State<LevelUpScreen> {
  late Future<List<DndClassData>> _classesFuture;
  late Future<List<FeatData>> _featsFuture;

  String _asiChoice = 'plus2';
  String? _firstAbility;
  String? _secondAbility;
  String? _selectedFeatId;
  String? _selectedFeatAbility;
  int _selectedFeatAbilityBonus = 0;
  final List<String> _selectedFeatAbilities = [];

  bool _useRoll = false;
  int? _rolledValue;
  int? _gainedHitPoints;

  int _modifier(int score) => ((score - 10) / 2).floor();

  @override
  void initState() {
    super.initState();
    _classesFuture = loadClasses();
    _featsFuture = loadFeats();
  }

  DndClassData? _findClass(List<DndClassData> classes) {
    for (final item in classes) {
      if (item.name == widget.character.characterClass ||
          item.englishName == widget.character.characterClass ||
          item.id == widget.character.characterClass) {
        return item;
      }
    }
    return null;
  }

  ClassSubclass? _findSubclass(DndClassData classData) {
    for (final item in classData.subclasses) {
      if (item.id == widget.character.subclassId ||
          item.name == widget.character.subclassName) {
        return item;
      }
    }
    return null;
  }

  bool _hasAbilityScoreImprovement(List<String> progression) {
    return progression.any((item) => item.contains('Увеличение характеристик'));
  }

  static const Map<String, String> _abilityNames = {
    'str': 'Сила',
    'dex': 'Ловкость',
    'con': 'Телосложение',
    'int': 'Интеллект',
    'wis': 'Мудрость',
    'cha': 'Харизма',
  };
  List<String> _availableAbilities(int maxScore) {
    final scores = widget.character.effectiveAbilityScores;

    return _abilityNames.keys
        .where((ability) => (scores[ability] ?? 8) <= maxScore)
        .toList();
  }

  void _calculateHitPoints(int hitDie) {
    final con = widget.character.effectiveAbilityScores['con'] ?? 8;
    final conModifier = _modifier(con);

    final roll = _useRoll ? Random().nextInt(hitDie) + 1 : (hitDie ~/ 2) + 1;

    final gained = max(1, roll + conModifier);

    setState(() {
      _rolledValue = roll;
      _gainedHitPoints = gained;
    });
  }

  Future<void> _confirm(
    int nextLevel,
    List<String> features,
    bool hasAsi,
    DndClassData classData,
  ) async {
    final character = widget.character;
    final gained = _gainedHitPoints;
    if (gained == null) return;

    final abilityIncreases = <String, int>{};
    String? featId;

    if (hasAsi) {
      if (_asiChoice == 'plus2') {
        if (_firstAbility == null) {
          _showSelectionError();
          return;
        }
        abilityIncreases[_firstAbility!] = 2;
      } else if (_asiChoice == 'plus1') {
        if (_firstAbility == null ||
            _secondAbility == null ||
            _firstAbility == _secondAbility) {
          _showSelectionError();
          return;
        }

        abilityIncreases[_firstAbility!] = 1;
        abilityIncreases[_secondAbility!] = 1;
      } else if (_asiChoice == 'feat') {
        if (_selectedFeatId == null) {
          _showSelectionError();
          return;
        }

        featId = _selectedFeatId;

        if (_selectedFeatAbilities.isNotEmpty) {
          final ability = _selectedFeatAbilities.length == 1
              ? _selectedFeatAbilities.first
              : _selectedFeatAbility;

          if (ability == null ||
              (character.effectiveAbilityScores[ability] ?? 8) >= 20) {
            _showSelectionError();
            return;
          }

          abilityIncreases[ability] = _selectedFeatAbilityBonus;
        }
      }
    }

    await _finishLevelUp(
      nextLevel,
      features,
      abilityIncreases,
      featId,
      classData,
    );
  }

  bool _sameSpellClass(String left, String right) =>
      left.trim().toLowerCase() == right.trim().toLowerCase();

  bool _isClassSpell(SpellData spell, DndClassData classData) =>
      spell.classes.any(
        (name) =>
            _sameSpellClass(name, classData.name) ||
            _sameSpellClass(name, classData.englishName) ||
            _sameSpellClass(name, classData.id),
      );

  bool _isWizardSpell(SpellData spell, DndClassData wizard) =>
      _isClassSpell(spell, wizard);

  bool _isWarlockSpell(SpellData spell, DndClassData warlock, String patronId) {
    final classSpell = spell.classes.any(
      (name) =>
          _sameSpellClass(name, warlock.name) ||
          _sameSpellClass(name, warlock.englishName) ||
          _sameSpellClass(name, warlock.id),
    );
    if (classSpell || spell.subclasses.contains(patronId)) return true;
    return patronId == 'genie' &&
        widget.character.warlockGenieKind.isNotEmpty &&
        spell.subclasses.contains('genie_${widget.character.warlockGenieKind}');
  }

  int _eldritchKnightMaxSpellLevel(int level) {
    if (level >= 19) return 4;
    if (level >= 13) return 3;
    if (level >= 7) return 2;
    if (level >= 3) return 1;
    return 0;
  }

  bool _isEldritchKnightSchoolSpell(SpellData spell) {
    final school = spell.school.trim().toLowerCase();
    return school == 'ограждение' ||
        school == 'воплощение' ||
        school == 'abjuration' ||
        school == 'evocation';
  }

  bool _isEldritchKnightSpell(SpellData spell, DndClassData wizard) =>
      _isWizardSpell(spell, wizard);

  bool _isRangerSpell(SpellData spell, DndClassData ranger) =>
      spell.classes.any(
        (name) =>
            _sameSpellClass(name, ranger.name) ||
            _sameSpellClass(name, ranger.englishName) ||
            _sameSpellClass(name, ranger.id),
      );

  Future<List<String>?> _chooseWizardSpells(
    List<SpellData> spells,
    int count,
    String title,
  ) {
    return showDialog<List<String>>(
      context: context,
      builder: (context) => SpellSelectionDialog(
        spells: spells,
        selectionCount: count,
        title: title,
      ),
    );
  }

  Future<void> _finishLevelUp(
    int nextLevel,
    List<String> features,
    Map<String, int> abilityIncreases,
    String? featId,
    DndClassData classData,
  ) async {
    final character = widget.character;
    final wizardBookAdditions = <String>[];
    final cantripAdditions = <String>[];
    final knownSpellAdditions = <String>[];
    final bardSecretAdditions = <String>[];
    final loreSecretAdditions = <String>[];
    final mysticArcanumAdditions = <String, String>{};
    String? replacedKnownSpellId;
    var masteryIds = <String>[];
    var signatureIds = <String>[];
    var sorcererMetamagicAdditions = <String>[];

    if (classData.id == 'fighter' && widget.character.subclassId == 'eldritch-knight') {
      final spells = await loadSpells();
      final classes = await loadClasses();
      if (!mounted) return;
      final wizard = classes.where((item) => item.id == 'wizard').firstOrNull;
      if (wizard == null) {
        _showWizardChoiceError('Не найден класс Волшебник для списка заклинаний Мистического рыцаря.');
        return;
      }

      final knownProgression = const [
        0, 0, 3, 4, 4, 4, 5, 6, 6, 7,
        8, 8, 9, 10, 10, 11, 11, 11, 12, 13,
      ];
      final nextKnownCount = knownProgression[nextLevel - 1];
      final currentKnown = character.knownSpellIds
          .map((id) => spells.where((spell) => spell.id == id).firstOrNull)
          .whereType<SpellData>()
          .where((spell) => spell.level > 0 && _isEldritchKnightSpell(spell, wizard))
          .toList();
      final gainedKnownSpells = (nextKnownCount - currentKnown.length)
          .clamp(0, 20).toInt();

      final cantripProgression = const [
        0, 0, 2, 2, 2, 2, 2, 2, 2, 3,
        3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
      ];
      final nextCantripCount = cantripProgression[nextLevel - 1];
      final currentCantrips = character.knownCantripIds
          .map((id) => spells.where((spell) => spell.id == id).firstOrNull)
          .whereType<SpellData>()
          .where((spell) => spell.level == 0 && _isEldritchKnightSpell(spell, wizard))
          .length;
      final gainedCantrips = (nextCantripCount - currentCantrips)
          .clamp(0, 20).toInt();

      if (gainedCantrips > 0) {
        final knownCantrips = character.knownCantripIds.toSet();
        final options = spells.where((spell) =>
          spell.level == 0 &&
          _isEldritchKnightSpell(spell, wizard) &&
          !knownCantrips.contains(spell.id)).toList();
        if (options.length < gainedCantrips) {
          _showWizardChoiceError('Недостаточно доступных заговоров волшебника в каталоге.');
          return;
        }
        final chosen = await _chooseWizardSpells(
          options, gainedCantrips,
          'Выбери $gainedCantrips заговор(а) Мистического рыцаря',
        );
        if (chosen == null || !mounted) return;
        cantripAdditions.addAll(chosen);
      }

      if (gainedKnownSpells > 0) {
        final alreadyKnown = character.knownSpellIds.toSet();
        final available = spells.where((spell) =>
          spell.level > 0 &&
          spell.level <= _eldritchKnightMaxSpellLevel(nextLevel) &&
          _isEldritchKnightSpell(spell, wizard) &&
          !alreadyKnown.contains(spell.id)).toList();

        if (nextLevel == 3) {
          final restricted = available.where(_isEldritchKnightSchoolSpell).toList();
          if (restricted.length < 2 || available.length < 3) {
            _showWizardChoiceError('Для Мистического рыцаря нужны 2 заклинания Ограждения/Воплощения и 1 заклинание любой школы.');
            return;
          }
          final restrictedChoices = await _chooseWizardSpells(
            restricted, 2,
            'Выбери 2 заклинания Ограждения или Воплощения',
          );
          if (restrictedChoices == null || !mounted) return;
          knownSpellAdditions.addAll(restrictedChoices);
          final anySchoolOptions = available.where((spell) =>
            !alreadyKnown.contains(spell.id) &&
            !knownSpellAdditions.contains(spell.id)).toList();
          final anySchoolChoice = await _chooseWizardSpells(
            anySchoolOptions, 1,
            'Выбери 1 заклинание любой школы',
          );
          if (anySchoolChoice == null || !mounted) return;
          knownSpellAdditions.addAll(anySchoolChoice);
        } else {
          final mayChooseAnySchool = const {8, 14, 20}.contains(nextLevel);
          final options = mayChooseAnySchool
              ? available
              : available.where(_isEldritchKnightSchoolSpell).toList();
          if (options.length < gainedKnownSpells) {
            _showWizardChoiceError('Недостаточно доступных заклинаний подходящей школы и круга для Мистического рыцаря.');
            return;
          }
          final chosen = await _chooseWizardSpells(
            options, gainedKnownSpells,
            mayChooseAnySchool
                ? 'Выбери новое заклинание любой школы'
                : 'Выбери новое заклинание Ограждения или Воплощения',
          );
          if (chosen == null || !mounted) return;
          knownSpellAdditions.addAll(chosen);
        }
      }

      final replacementOptions = spells.where((spell) =>
        spell.level > 0 &&
        spell.level <= _eldritchKnightMaxSpellLevel(nextLevel) &&
        _isEldritchKnightSpell(spell, wizard) &&
        !character.knownSpellIds.contains(spell.id) &&
        !knownSpellAdditions.contains(spell.id) &&
        (const {8, 14, 20}.contains(nextLevel) || _isEldritchKnightSchoolSpell(spell))
      ).toList();
      if (currentKnown.isNotEmpty && replacementOptions.isNotEmpty) {
        final replacement = await showDialog<MapEntry<String, String>>(
          context: context,
          builder: (context) => _KnownSpellReplacementDialog(
            knownSpells: currentKnown,
            replacementSpells: replacementOptions,
          ),
        );
        if (!mounted) return;
        if (replacement != null) {
          replacedKnownSpellId = replacement.key;
          knownSpellAdditions.add(replacement.value);
        }
      }
    } else if (classData.id == 'rogue' &&
        (widget.character.subclassId == 'arcane_trickster' ||
            widget.character.subclassId == 'arcane-trickster')) {
      // Мистический ловкач использует список заклинаний Волшебника.
      final spells = await loadSpells();
      final classes = await loadClasses();
      if (!mounted) return;
      final wizard = classes.where((item) => item.id == 'wizard').firstOrNull;
      if (wizard == null) {
        _showWizardChoiceError(
          'Не найден класс Волшебник для списка заклинаний Мистического ловкача.',
        );
        return;
      }

      const knownProgression = [
        0, 0, 3, 4, 4, 4, 5, 6, 6, 7,
        8, 8, 9, 10, 10, 11, 11, 11, 12, 13,
      ];
      const cantripProgression = [
        0, 0, 3, 3, 3, 3, 3, 3, 3, 4,
        4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
      ];

      final nextKnownCount = knownProgression[nextLevel - 1];
      final currentKnown = character.knownSpellIds
          .map((id) => spells.where((spell) => spell.id == id).firstOrNull)
          .whereType<SpellData>()
          .where((spell) => spell.level > 0 && _isWizardSpell(spell, wizard))
          .toList();
      final gainedKnownSpells =
          (nextKnownCount - currentKnown.length).clamp(0, 20).toInt();

      final nextCantripCount = cantripProgression[nextLevel - 1];
      final currentCantrips = character.knownCantripIds
          .map((id) => spells.where((spell) => spell.id == id).firstOrNull)
          .whereType<SpellData>()
          .where((spell) => spell.level == 0 && _isWizardSpell(spell, wizard))
          .length;
      final gainedCantrips =
          (nextCantripCount - currentCantrips).clamp(0, 20).toInt();

      if (gainedCantrips > 0) {
        final alreadyKnownCantrips = character.knownCantripIds.toSet();
        final mageHand = spells.where((spell) =>
            spell.level == 0 &&
            _isWizardSpell(spell, wizard) &&
            (spell.id == 'mage_hand' ||
                spell.id == 'mage-hand' ||
                spell.name.trim().toLowerCase() == 'волшебная рука' ||
                spell.name.trim().toLowerCase() == 'mage hand') &&
            !alreadyKnownCantrips.contains(spell.id)).toList();

        if (nextLevel == 3 && mageHand.isEmpty &&
            !character.knownCantripIds.any((id) =>
                id == 'mage_hand' || id == 'mage-hand')) {
          _showWizardChoiceError(
            'В каталоге не найдена «Волшебная рука» — обязательный заговор Мистического ловкача.',
          );
          return;
        }

        final chosenCantrips = <String>[];
        if (nextLevel == 3 && mageHand.isNotEmpty) {
          chosenCantrips.add(mageHand.first.id);
        }
        final remainingCount = gainedCantrips - chosenCantrips.length;
        if (remainingCount > 0) {
          final options = spells.where((spell) =>
              spell.level == 0 &&
              _isWizardSpell(spell, wizard) &&
              !alreadyKnownCantrips.contains(spell.id) &&
              !chosenCantrips.contains(spell.id)).toList();
          if (options.length < remainingCount) {
            _showWizardChoiceError(
              'Недостаточно доступных заговоров Волшебника для Мистического ловкача.',
            );
            return;
          }
          final selected = await _chooseWizardSpells(
            options,
            remainingCount,
            'Выбери $remainingCount дополнительных заговора Мистического ловкача',
          );
          if (selected == null || !mounted) return;
          chosenCantrips.addAll(selected);
        }
        cantripAdditions.addAll(chosenCantrips);
      }

      if (gainedKnownSpells > 0) {
        final alreadyKnown = character.knownSpellIds.toSet();
        final available = spells.where((spell) =>
            spell.level > 0 &&
            spell.level <= _eldritchKnightMaxSpellLevel(nextLevel) &&
            _isWizardSpell(spell, wizard) &&
            !alreadyKnown.contains(spell.id)).toList();

        if (nextLevel == 3) {
          bool isTricksterSchool(SpellData spell) {
            final school = spell.school.trim().toLowerCase();
            return school == 'очарование' ||
                school == 'иллюзия' ||
                school == 'enchantment' ||
                school == 'illusion';
          }

          final restricted = available.where(isTricksterSchool).toList();
          if (restricted.length < 2 || available.length < 3) {
            _showWizardChoiceError(
              'Для Мистического ловкача нужны 2 заклинания Очарования/Иллюзии и 1 заклинание любой школы.',
            );
            return;
          }
          final restrictedChoices = await _chooseWizardSpells(
            restricted,
            2,
            'Выбери 2 заклинания Очарования или Иллюзии',
          );
          if (restrictedChoices == null || !mounted) return;
          knownSpellAdditions.addAll(restrictedChoices);

          final anySchoolOptions = available.where((spell) =>
              !knownSpellAdditions.contains(spell.id)).toList();
          final anySchoolChoice = await _chooseWizardSpells(
            anySchoolOptions,
            1,
            'Выбери 1 заклинание любой школы',
          );
          if (anySchoolChoice == null || !mounted) return;
          knownSpellAdditions.addAll(anySchoolChoice);
        } else {
          bool isTricksterSchool(SpellData spell) {
            final school = spell.school.trim().toLowerCase();
            return school == 'очарование' ||
                school == 'иллюзия' ||
                school == 'enchantment' ||
                school == 'illusion';
          }

          final mayChooseAnySchool = const {8, 14, 20}.contains(nextLevel);
          final options = mayChooseAnySchool
              ? available
              : available.where(isTricksterSchool).toList();
          if (options.length < gainedKnownSpells) {
            _showWizardChoiceError(
              'Недостаточно доступных заклинаний подходящей школы и круга для Мистического ловкача.',
            );
            return;
          }
          final chosen = await _chooseWizardSpells(
            options,
            gainedKnownSpells,
            mayChooseAnySchool
                ? 'Выбери новое заклинание любой школы'
                : 'Выбери новое заклинание Очарования или Иллюзии',
          );
          if (chosen == null || !mounted) return;
          knownSpellAdditions.addAll(chosen);
        }
      }

      bool isTricksterSchool(SpellData spell) {
        final school = spell.school.trim().toLowerCase();
        return school == 'очарование' ||
            school == 'иллюзия' ||
            school == 'enchantment' ||
            school == 'illusion';
      }

      final replacementOptions = spells.where((spell) =>
          spell.level > 0 &&
          spell.level <= _eldritchKnightMaxSpellLevel(nextLevel) &&
          _isWizardSpell(spell, wizard) &&
          !character.knownSpellIds.contains(spell.id) &&
          !knownSpellAdditions.contains(spell.id) &&
          (const {8, 14, 20}.contains(nextLevel) || isTricksterSchool(spell)))
          .toList();
      if (currentKnown.isNotEmpty && replacementOptions.isNotEmpty) {
        final replacement = await showDialog<MapEntry<String, String>>(
          context: context,
          builder: (context) => _KnownSpellReplacementDialog(
            knownSpells: currentKnown,
            replacementSpells: replacementOptions,
          ),
        );
        if (!mounted) return;
        if (replacement != null) {
          replacedKnownSpellId = replacement.key;
          knownSpellAdditions.add(replacement.value);
        }
      }
    } else if (classData.id == 'bard') {
      final spells = await loadSpells();
      if (!mounted) return;
      final casting = classData.spellcasting ?? const <String, dynamic>{};
      final slotTable = casting['spellSlotsByLevel'] as List? ?? const [];
      final slotRow = nextLevel - 1 < slotTable.length
          ? slotTable[nextLevel - 1] as List? ?? const []
          : const [];
      var maximumSpellLevel = 0;
      for (var index = 0; index < slotRow.length; index++) {
        if ((slotRow[index] as num).toInt() > 0) maximumSpellLevel = index + 1;
      }

      final cantripProgression =
          casting['cantripsKnownByLevel'] as List? ?? const [];
      final currentCantrips = character.knownCantripIds.length;
      final nextCantrips = nextLevel - 1 < cantripProgression.length
          ? (cantripProgression[nextLevel - 1] as num).toInt()
          : currentCantrips;
      final gainedCantrips = (nextCantrips - currentCantrips)
          .clamp(0, 20)
          .toInt();
      if (gainedCantrips > 0) {
        final knownCantrips = character.knownCantripIds.toSet();
        final options = spells.where((spell) {
          return spell.level == 0 &&
              _isClassSpell(spell, classData) &&
              !knownCantrips.contains(spell.id);
        }).toList();
        if (options.length < gainedCantrips) {
          _showWizardChoiceError('Недостаточно доступных заговоров барда в каталоге.');
          return;
        }
        final chosen = await _chooseWizardSpells(
          options,
          gainedCantrips,
          'Выбери $gainedCantrips новый заговор барда',
        );
        if (chosen == null || !mounted) return;
        cantripAdditions.addAll(chosen);
      }

      final knownProgression =
          casting['spellsKnownByLevel'] as List? ?? const [];
      final nextKnownCount = nextLevel - 1 < knownProgression.length
          ? (knownProgression[nextLevel - 1] as num).toInt()
          : character.knownSpellIds.length +
                character.bardMagicalSecretSpellIds.length;
      final currentClassKnown = {
        ...character.knownSpellIds,
        ...character.bardMagicalSecretSpellIds,
      }.length;
      final getsMagicalSecrets = const {10, 14, 18}.contains(nextLevel);
      final newSecretCount = getsMagicalSecrets ? 2 : 0;
      final neededClassSpells = (nextKnownCount -
              currentClassKnown -
              newSecretCount)
          .clamp(0, 22)
          .toInt();
      if (neededClassSpells > 0) {
        final alreadyChosen = {
          ...character.knownSpellIds,
          ...character.bardMagicalSecretSpellIds,
          ...character.loreAdditionalSpellIds,
        };
        final options = spells.where((spell) {
          return spell.level > 0 &&
              spell.level <= maximumSpellLevel &&
              _isClassSpell(spell, classData) &&
              !alreadyChosen.contains(spell.id);
        }).toList();
        if (options.length < neededClassSpells) {
          _showWizardChoiceError('Недостаточно доступных заклинаний барда в каталоге.');
          return;
        }
        final chosen = await _chooseWizardSpells(
          options,
          neededClassSpells,
          'Выбери $neededClassSpells новых заклинаний барда',
        );
        if (chosen == null || !mounted) return;
        knownSpellAdditions.addAll(chosen);
      }

      if (getsMagicalSecrets) {
        final alreadyChosen = {
          ...character.knownSpellIds,
          ...character.bardMagicalSecretSpellIds,
          ...character.loreAdditionalSpellIds,
          ...knownSpellAdditions,
        };
        final options = spells.where((spell) {
          return (spell.level == 0 || spell.level <= maximumSpellLevel) &&
              spell.classes.isNotEmpty &&
              !alreadyChosen.contains(spell.id);
        }).toList();
        if (options.length < 2) {
          _showWizardChoiceError('Недостаточно заклинаний для Магических секретов.');
          return;
        }
        final chosen = await _chooseWizardSpells(
          options,
          2,
          'Выбери 2 заклинания для Магических секретов',
        );
        if (chosen == null || !mounted) return;
        bardSecretAdditions.addAll(chosen);
      }

      if (nextLevel == 6 && widget.character.subclassId == 'college_of_lore') {
        final alreadyChosen = {
          ...character.knownSpellIds,
          ...character.bardMagicalSecretSpellIds,
          ...character.loreAdditionalSpellIds,
          ...knownSpellAdditions,
          ...bardSecretAdditions,
        };
        final options = spells.where((spell) {
          return (spell.level == 0 || spell.level <= maximumSpellLevel) &&
              spell.classes.isNotEmpty &&
              !alreadyChosen.contains(spell.id);
        }).toList();
        if (options.length < 2) {
          _showWizardChoiceError(
            'Недостаточно заклинаний для Additional Magical Secrets Коллегии знаний.',
          );
          return;
        }
        final chosen = await _chooseWizardSpells(
          options,
          2,
          'Выбери 2 дополнительных Магических секрета Коллегии знаний',
        );
        if (chosen == null || !mounted) return;
        loreSecretAdditions.addAll(chosen);
      }

      final replacementOptions = spells.where((spell) {
        return spell.level > 0 &&
            spell.level <= maximumSpellLevel &&
            _isClassSpell(spell, classData) &&
            !character.knownSpellIds.contains(spell.id) &&
            !character.bardMagicalSecretSpellIds.contains(spell.id) &&
            !character.loreAdditionalSpellIds.contains(spell.id) &&
            !knownSpellAdditions.contains(spell.id) &&
            !bardSecretAdditions.contains(spell.id) &&
            !loreSecretAdditions.contains(spell.id);
      }).toList();
      final currentKnownIds = {
        ...character.knownSpellIds,
        ...character.bardMagicalSecretSpellIds,
        ...character.loreAdditionalSpellIds,
      };
      final currentKnown = currentKnownIds
          .map((id) => spells.where((spell) => spell.id == id).firstOrNull)
          .whereType<SpellData>()
          .where((spell) => spell.level > 0)
          .toList();
      if (currentKnown.isNotEmpty && replacementOptions.isNotEmpty) {
        final replacement = await showDialog<MapEntry<String, String>>(
          context: context,
          builder: (context) => _KnownSpellReplacementDialog(
            knownSpells: currentKnown,
            replacementSpells: replacementOptions,
          ),
        );
        if (!mounted) return;
        if (replacement != null) {
          replacedKnownSpellId = replacement.key;
          if (character.bardMagicalSecretSpellIds.contains(replacement.key)) {
            bardSecretAdditions.add(replacement.value);
          } else if (character.loreAdditionalSpellIds.contains(
            replacement.key,
          )) {
            loreSecretAdditions.add(replacement.value);
          } else {
            knownSpellAdditions.add(replacement.value);
          }
        }
      }
    } else if (classData.id == 'sorcerer') {
      final spells = await loadSpells();
      if (!mounted) return;
      final casting = classData.spellcasting ?? const <String, dynamic>{};
      final slotTable = casting['spellSlotsByLevel'] as List? ?? const [];
      final slotRow = nextLevel - 1 < slotTable.length
          ? slotTable[nextLevel - 1] as List? ?? const []
          : const [];
      var maximumSpellLevel = 0;
      for (var index = 0; index < slotRow.length; index++) {
        if ((slotRow[index] as num).toInt() > 0) maximumSpellLevel = index + 1;
      }

      final cantripProgression =
          casting['cantripsKnownByLevel'] as List? ?? const [];
      final currentCantrips = character.knownCantripIds
          .map((id) => spells.where((spell) => spell.id == id).firstOrNull)
          .whereType<SpellData>()
          .where((spell) => spell.level == 0 && _isClassSpell(spell, classData))
          .length;
      final nextCantrips = nextLevel - 1 < cantripProgression.length
          ? (cantripProgression[nextLevel - 1] as num).toInt()
          : currentCantrips;
      final gainedCantrips = (nextCantrips - currentCantrips).clamp(0, 20).toInt();
      if (gainedCantrips > 0) {
        final alreadyKnown = character.knownCantripIds.toSet();
        final options = spells.where((spell) =>
            spell.level == 0 &&
            _isClassSpell(spell, classData) &&
            !alreadyKnown.contains(spell.id)).toList();
        if (options.length < gainedCantrips) {
          _showWizardChoiceError('Недостаточно доступных заговоров чародея в каталоге.');
          return;
        }
        final chosen = await _chooseWizardSpells(
          options, gainedCantrips, 'Выбери $gainedCantrips новый заговор чародея',
        );
        if (chosen == null || !mounted) return;
        cantripAdditions.addAll(chosen);
      }

      final knownProgression =
          casting['spellsKnownByLevel'] as List? ?? const [];
      final nextKnownCount = nextLevel - 1 < knownProgression.length
          ? (knownProgression[nextLevel - 1] as num).toInt()
          : character.knownSpellIds.length;
      final currentKnown = character.knownSpellIds
          .map((id) => spells.where((spell) => spell.id == id).firstOrNull)
          .whereType<SpellData>()
          .where((spell) => spell.level > 0 && _isClassSpell(spell, classData))
          .length;
      final gainedKnownSpells = (nextKnownCount - currentKnown).clamp(0, 20).toInt();
      if (gainedKnownSpells > 0) {
        final alreadyKnown = character.knownSpellIds.toSet();
        final options = spells.where((spell) =>
            spell.level > 0 &&
            spell.level <= maximumSpellLevel &&
            _isClassSpell(spell, classData) &&
            !alreadyKnown.contains(spell.id)).toList();
        if (options.length < gainedKnownSpells) {
          _showWizardChoiceError('Недостаточно доступных заклинаний чародея в каталоге.');
          return;
        }
        final chosen = await _chooseWizardSpells(
          options, gainedKnownSpells,
          'Выбери $gainedKnownSpells новых известных заклинаний чародея',
        );
        if (chosen == null || !mounted) return;
        knownSpellAdditions.addAll(chosen);
      }

      final replacementOptions = spells.where((spell) =>
          spell.level > 0 &&
          spell.level <= maximumSpellLevel &&
          _isClassSpell(spell, classData) &&
          !character.knownSpellIds.contains(spell.id) &&
          !knownSpellAdditions.contains(spell.id)).toList();
      final currentKnownSpells = character.knownSpellIds
          .map((id) => spells.where((spell) => spell.id == id).firstOrNull)
          .whereType<SpellData>()
          .where((spell) => spell.level > 0 && _isClassSpell(spell, classData))
          .toList();
      if (currentKnownSpells.isNotEmpty && replacementOptions.isNotEmpty) {
        final replacement = await showDialog<MapEntry<String, String>>(
          context: context,
          builder: (context) => _KnownSpellReplacementDialog(
            knownSpells: currentKnownSpells,
            replacementSpells: replacementOptions,
          ),
        );
        if (!mounted) return;
        if (replacement != null) {
          replacedKnownSpellId = replacement.key;
          knownSpellAdditions.add(replacement.value);
        }
      }

      final metamagicOptions = <String, String>{
        'careful_spell': 'Аккуратное заклинание',
        'distant_spell': 'Далёкое заклинание',
        'empowered_spell': 'Усиленное заклинание',
        'extended_spell': 'Продлённое заклинание',
        'heightened_spell': 'Усиленное воздействие',
        'quickened_spell': 'Быстрое заклинание',
        'subtle_spell': 'Незаметное заклинание',
        'twinned_spell': 'Сдвоенное заклинание',
      };
      final metamagicCount = nextLevel == 3 ? 2 : (nextLevel == 10 || nextLevel == 17 ? 1 : 0);
      if (metamagicCount > 0) {
        final alreadySelected = character.sorcererMetamagicOptions.toSet();
        final options = metamagicOptions.entries
            .where((entry) => !alreadySelected.contains(entry.key))
            .toList();
        final selected = await showDialog<List<String>>(
          context: context,
          builder: (dialogContext) {
            final chosen = <String>{};
            return StatefulBuilder(
              builder: (context, setDialogState) => AlertDialog(
                title: Text('Выбери $metamagicCount варианта Метамагии'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final option in options)
                        CheckboxListTile(
                          dense: true,
                          value: chosen.contains(option.key),
                          title: Text(option.value),
                          onChanged: (value) => setDialogState(() {
                            if (value == true && chosen.length < metamagicCount) {
                              chosen.add(option.key);
                            } else {
                              chosen.remove(option.key);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: chosen.length == metamagicCount
                        ? () => Navigator.of(dialogContext).pop(chosen.toList())
                        : null,
                    child: const Text('Подтвердить'),
                  ),
                ],
              ),
            );
          },
        );
        if (selected == null || !mounted) return;
        sorcererMetamagicAdditions.addAll(selected);
      }
    } else if (classData.id == 'wizard') {
      final spells = await loadSpells();
      if (!mounted) return;

      final casting = classData.spellcasting ?? const <String, dynamic>{};
      final slots = casting['spellSlotsByLevel'] as List? ?? const [];
      final row = nextLevel - 1 < slots.length
          ? slots[nextLevel - 1] as List? ?? const []
          : const [];
      var maxSpellLevel = 0;
      for (var index = 0; index < row.length; index++) {
        if ((row[index] as num).toInt() > 0) maxSpellLevel = index + 1;
      }

      final currentBookIds = {
        ...character.spellbookSpellIds,
        ...character.knownSpellIds,
      };
      final newSpells = spells.where((spell) {
        return spell.level > 0 &&
            spell.level <= maxSpellLevel &&
            _isWizardSpell(spell, classData) &&
            !currentBookIds.contains(spell.id);
      }).toList();
      if (newSpells.length < 2) {
        _showWizardChoiceError(
          'В каталоге недостаточно доступных заклинаний волшебника.',
        );
        return;
      }
      final chosenSpells = await _chooseWizardSpells(
        newSpells,
        2,
        'Выбери 2 новых заклинания для книги',
      );
      if (chosenSpells == null || !mounted) return;
      wizardBookAdditions.addAll(chosenSpells);

      final cantripProgression =
          casting['cantripsKnownByLevel'] as List? ?? const [];
      final oldCantripCount = character.level - 1 < cantripProgression.length
          ? (cantripProgression[character.level - 1] as num).toInt()
          : 0;
      final newCantripCount = nextLevel - 1 < cantripProgression.length
          ? (cantripProgression[nextLevel - 1] as num).toInt()
          : oldCantripCount;
      final gainedCantrips = (newCantripCount - oldCantripCount)
          .clamp(0, 20)
          .toInt();
      if (gainedCantrips > 0) {
        final knownCantripIds = character.knownCantripIds.toSet();
        final availableCantrips = spells.where((spell) {
          return spell.level == 0 &&
              _isWizardSpell(spell, classData) &&
              !knownCantripIds.contains(spell.id);
        }).toList();
        if (availableCantrips.length < gainedCantrips) {
          _showWizardChoiceError(
            'В каталоге недостаточно доступных заговоров волшебника.',
          );
          return;
        }
        final chosenCantrips = await _chooseWizardSpells(
          availableCantrips,
          gainedCantrips,
          'Выбери $gainedCantrips новый заговор',
        );
        if (chosenCantrips == null || !mounted) return;
        cantripAdditions.addAll(chosenCantrips);
      }

      final availableBook = {...currentBookIds, ...wizardBookAdditions};
      if (nextLevel == 18) {
        final firstLevelSpells = spells
            .where(
              (spell) =>
                  spell.level == 1 &&
                  availableBook.contains(spell.id) &&
                  _isWizardSpell(spell, classData),
            )
            .toList();
        final firstMastery = await _chooseWizardSpells(
          firstLevelSpells,
          1,
          'Spell Mastery: выбери заклинание 1-го уровня из книги',
        );
        if (firstMastery == null || !mounted) return;
        final secondLevelSpells = spells
            .where(
              (spell) =>
                  spell.level == 2 &&
                  availableBook.contains(spell.id) &&
                  _isWizardSpell(spell, classData),
            )
            .toList();
        final secondMastery = await _chooseWizardSpells(
          secondLevelSpells,
          1,
          'Spell Mastery: выбери заклинание 2-го уровня из книги',
        );
        if (secondMastery == null || !mounted) return;
        masteryIds = [...firstMastery, ...secondMastery];
      }

      if (nextLevel == 20) {
        final thirdLevelSpells = spells
            .where(
              (spell) =>
                  spell.level == 3 &&
                  availableBook.contains(spell.id) &&
                  _isWizardSpell(spell, classData),
            )
            .toList();
        if (thirdLevelSpells.length < 2) {
          _showWizardChoiceError(
            'Для Signature Spells нужны два заклинания 3-го круга в книге.',
          );
          return;
        }
        final chosenSignatures = await _chooseWizardSpells(
          thirdLevelSpells,
          2,
          'Signature Spells: выбери 2 заклинания 3-го круга из книги',
        );
        if (chosenSignatures == null || !mounted) return;
        signatureIds = chosenSignatures;
      }
    } else if (classData.id == 'ranger') {
      final spells = await loadSpells();
      if (!mounted) return;
      final casting = classData.spellcasting ?? const <String, dynamic>{};
      final slotTable = casting['spellSlotsByLevel'] as List? ?? const [];
      final slotRow = nextLevel - 1 < slotTable.length
          ? slotTable[nextLevel - 1] as List? ?? const []
          : const [];
      var maximumSpellLevel = 0;
      for (var index = 0; index < slotRow.length; index++) {
        if ((slotRow[index] as num).toInt() > 0) {
          maximumSpellLevel = index + 1;
        }
      }

      final knownProgression =
          casting['spellsKnownByLevel'] as List? ?? const [];
      final nextKnownCount = nextLevel - 1 < knownProgression.length
          ? (knownProgression[nextLevel - 1] as num).toInt()
          : character.knownSpellIds.length;
      final currentKnownCount = character.knownSpellIds
          .map((id) => spells.where((spell) => spell.id == id).firstOrNull)
          .whereType<SpellData>()
          .where((spell) => spell.level > 0 && _isRangerSpell(spell, classData))
          .length;
      final gainedKnownSpells = (nextKnownCount - currentKnownCount)
          .clamp(0, 20)
          .toInt();
      if (gainedKnownSpells > 0) {
        final alreadyKnown = character.knownSpellIds.toSet();
        final options = spells.where((spell) {
          return spell.level > 0 &&
              spell.level <= maximumSpellLevel &&
              _isRangerSpell(spell, classData) &&
              !alreadyKnown.contains(spell.id);
        }).toList();
        if (options.length < gainedKnownSpells) {
          _showWizardChoiceError(
            'Недостаточно заклинаний Следопыта подходящего круга в каталоге.',
          );
          return;
        }
        final chosen = await _chooseWizardSpells(
          options,
          gainedKnownSpells,
          'Выбери $gainedKnownSpells новое известное заклинание Следопыта',
        );
        if (chosen == null || !mounted) return;
        knownSpellAdditions.addAll(chosen);
      }

      final replacementOptions = spells.where((spell) {
        return spell.level > 0 &&
            spell.level <= maximumSpellLevel &&
            _isRangerSpell(spell, classData) &&
            !character.knownSpellIds.contains(spell.id) &&
            !knownSpellAdditions.contains(spell.id);
      }).toList();
      final currentKnown = character.knownSpellIds
          .map((id) => spells.where((spell) => spell.id == id).firstOrNull)
          .whereType<SpellData>()
          .where((spell) => spell.level > 0 && _isRangerSpell(spell, classData))
          .toList();
      if (currentKnown.isNotEmpty && replacementOptions.isNotEmpty) {
        final replacement = await showDialog<MapEntry<String, String>>(
          context: context,
          builder: (context) => _KnownSpellReplacementDialog(
            knownSpells: currentKnown,
            replacementSpells: replacementOptions,
          ),
        );
        if (!mounted) return;
        if (replacement != null) {
          replacedKnownSpellId = replacement.key;
          knownSpellAdditions.add(replacement.value);
        }
      }
    } else if (classData.id == 'warlock') {
      final spells = await loadSpells();
      if (!mounted) return;
      final casting = classData.spellcasting ?? const <String, dynamic>{};
      final pactMagic = casting['pactMagic'] as Map? ?? const {};
      final slotLevels = pactMagic['slotLevelByLevel'] as List? ?? const [];
      final maximumSpellLevel = slotLevels.isEmpty
          ? 0
          : (slotLevels[(nextLevel - 1).clamp(0, slotLevels.length - 1)] as num)
                .toInt();
      final patronId = widget.character.subclassId;
      final knownProgression =
          casting['spellsKnownByLevel'] as List? ?? const [];
      final previousKnownCount = character.level - 1 < knownProgression.length
          ? (knownProgression[character.level - 1] as num).toInt()
          : character.knownSpellIds.length;
      final nextKnownCount = nextLevel - 1 < knownProgression.length
          ? (knownProgression[nextLevel - 1] as num).toInt()
          : previousKnownCount;
      final gainedKnownSpells = (nextKnownCount - previousKnownCount)
          .clamp(0, 20)
          .toInt();
      if (gainedKnownSpells > 0) {
        final alreadyKnown = character.knownSpellIds.toSet();
        final options = spells.where((spell) {
          return spell.level > 0 &&
              spell.level <= maximumSpellLevel &&
              _isWarlockSpell(spell, classData, patronId) &&
              !alreadyKnown.contains(spell.id);
        }).toList();
        if (options.length < gainedKnownSpells) {
          _showWizardChoiceError(
            'Недостаточно доступных заклинаний колдуна в каталоге.',
          );
          return;
        }
        final chosen = await _chooseWizardSpells(
          options,
          gainedKnownSpells,
          'Выбери $gainedKnownSpells новое известное заклинание',
        );
        if (chosen == null || !mounted) return;
        knownSpellAdditions.addAll(chosen);
      }

      final cantripProgression =
          casting['cantripsKnownByLevel'] as List? ?? const [];
      final oldCantripCount = character.level - 1 < cantripProgression.length
          ? (cantripProgression[character.level - 1] as num).toInt()
          : character.knownCantripIds.length;
      final nextCantripCount = nextLevel - 1 < cantripProgression.length
          ? (cantripProgression[nextLevel - 1] as num).toInt()
          : oldCantripCount;
      final gainedCantrips = (nextCantripCount - oldCantripCount)
          .clamp(0, 20)
          .toInt();
      if (gainedCantrips > 0) {
        final knownCantrips = character.knownCantripIds.toSet();
        final options = spells.where((spell) {
          return spell.level == 0 &&
              _isWarlockSpell(spell, classData, patronId) &&
              !knownCantrips.contains(spell.id);
        }).toList();
        if (options.length < gainedCantrips) {
          _showWizardChoiceError(
            'Недостаточно доступных заговоров колдуна в каталоге.',
          );
          return;
        }
        final chosen = await _chooseWizardSpells(
          options,
          gainedCantrips,
          'Выбери $gainedCantrips новый заговор колдуна',
        );
        if (chosen == null || !mounted) return;
        cantripAdditions.addAll(chosen);
      }

      final replacementOptions = spells.where((spell) {
        return spell.level > 0 &&
            spell.level <= maximumSpellLevel &&
            _isWarlockSpell(spell, classData, patronId) &&
            !character.knownSpellIds.contains(spell.id) &&
            !knownSpellAdditions.contains(spell.id);
      }).toList();
      final currentKnown = character.knownSpellIds
          .map((id) => spells.where((spell) => spell.id == id).firstOrNull)
          .whereType<SpellData>()
          .where((spell) => spell.level > 0)
          .toList();
      if (currentKnown.isNotEmpty && replacementOptions.isNotEmpty) {
        final replacement = await showDialog<MapEntry<String, String>>(
          context: context,
          builder: (context) => _KnownSpellReplacementDialog(
            knownSpells: currentKnown,
            replacementSpells: replacementOptions,
          ),
        );
        if (!mounted) return;
        if (replacement != null) {
          replacedKnownSpellId = replacement.key;
          knownSpellAdditions.add(replacement.value);
        }
      }

      final arcanumEntries = pactMagic['mysticArcanum'] as List? ?? const [];
      final unlockedArcanum = arcanumEntries.whereType<Map>().where((entry) {
        return (entry['classLevel'] as num?)?.toInt() == nextLevel;
      });
      for (final entry in unlockedArcanum) {
        final spellLevel = (entry['spellLevel'] as num).toInt();
        final levelKey = '$spellLevel';
        if (character.mysticArcanumSpellIds.containsKey(levelKey)) continue;
        final options = spells.where((spell) {
          return spell.level == spellLevel &&
              spell.classes.any(
                (name) =>
                    _sameSpellClass(name, classData.name) ||
                    _sameSpellClass(name, classData.englishName) ||
                    _sameSpellClass(name, classData.id),
              );
        }).toList();
        if (options.isEmpty) {
          _showWizardChoiceError(
            'В каталоге нет заклинаний $spellLevel-го круга для Мистического арканума.',
          );
          return;
        }
        final chosen = await _chooseWizardSpells(
          options,
          1,
          'Выбери заклинание $spellLevel-го круга для Мистического арканума',
        );
        if (chosen == null || !mounted) return;
        mysticArcanumAdditions[levelKey] = chosen.single;
      }
    }

    Navigator.of(context).pop(
      LevelUpResult(
        newLevel: nextLevel,
        gainedHitPoints: _gainedHitPoints!,
        newMaxHitPoints: character.maxHitPoints + _gainedHitPoints!,
        rolledHitDie: _useRoll,
        newFeatures: features,
        abilityScoreIncreases: abilityIncreases,
        selectedFeatId: featId,
        newSpellbookSpellIds: wizardBookAdditions,
        newCantripIds: cantripAdditions,
        newKnownSpellIds: knownSpellAdditions,
        newBardMagicalSecretSpellIds: bardSecretAdditions,
        newLoreAdditionalSpellIds: loreSecretAdditions,
        replacedKnownSpellId: replacedKnownSpellId,
        mysticArcanumSpellIds: mysticArcanumAdditions,
        spellMasterySpellIds: masteryIds,
        signatureSpellIds: signatureIds,
        sorcererMetamagicOptions: sorcererMetamagicAdditions,
      ),
    );
  }

  void _showWizardChoiceError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSelectionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Сначала выбери характеристику или черту.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final character = widget.character;
    final nextLevel = character.level + 1;

    if (character.level >= 20) {
      return Scaffold(
        appBar: AppBar(title: const Text('Повышение уровня')),
        body: const Center(child: Text('Персонаж уже достиг 20-го уровня.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Повышение уровня'), centerTitle: true),
      body: FutureBuilder<List<DndClassData>>(
        future: _classesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Ошибка загрузки классов: ${snapshot.error}'),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }

          final classData = _findClass(snapshot.data!);

          if (classData == null) {
            return const Center(
              child: Text('Не удалось найти данные класса персонажа.'),
            );
          }

          final subclass = _findSubclass(classData);

          final classFeatures = classData.features
              .where((feature) => feature.level == nextLevel)
              .toList();

          final subclassFeatures =
              subclass?.features
                  .where((feature) => feature.level == nextLevel)
                  .toList() ??
              [];

          final features = <String>[
            ...classFeatures.map((f) => '${f.name}: ${f.description}'),
            ...subclassFeatures.map((f) => '${f.name}: ${f.description}'),
          ];

          final progression = nextLevel <= classData.progression.length
              ? classData.progression[nextLevel - 1]
              : <String>[];

          final hasAsi = _hasAbilityScoreImprovement(progression);

          final con = character.effectiveAbilityScores['con'] ?? 8;
          final conModifier = _modifier(con);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Уровень ${character.level} → $nextLevel',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${character.characterClass}'
                        '${character.subclassName.isNotEmpty ? ' · ${character.subclassName}' : ''}',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Здоровье',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Кость хитов: к${classData.hitDie}'),
                      Text(
                        'Телосложение: $con (${conModifier >= 0 ? '+' : ''}$conModifier)',
                      ),
                      const SizedBox(height: 12),
                      const Text('Как получить хиты?'),
                      RadioGroup<bool>(
                        groupValue: _useRoll,
                        onChanged: (value) {
                          if (_gainedHitPoints != null) return;

                          setState(() {
                            _useRoll = value!;
                            _rolledValue = null;
                            _gainedHitPoints = null;
                          });
                        },
                        child: Column(
                          children: [
                            RadioListTile<bool>(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Бросить кость хитов'),
                              value: true,
                            ),
                            RadioListTile<bool>(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Взять среднее значение'),
                              subtitle: Text(
                                'Среднее для к${classData.hitDie}: ${(classData.hitDie ~/ 2) + 1}',
                              ),
                              value: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: _gainedHitPoints != null
                            ? null
                            : () => _calculateHitPoints(classData.hitDie),
                        child: Text(
                          _gainedHitPoints != null
                              ? 'Результат зафиксирован'
                              : _useRoll
                              ? 'Бросить кость'
                              : 'Рассчитать хиты',
                        ),
                      ),
                      if (_gainedHitPoints != null) ...[
                        const SizedBox(height: 12),
                        Text('Результат кости: $_rolledValue'),
                        Text(
                          'Получено хитов: +$_gainedHitPoints',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Новый максимум HP: '
                          '${character.maxHitPoints + _gainedHitPoints!}',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Новые особенности',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (features.isEmpty)
                        const Text('На этом уровне новых особенностей нет.'),
                      for (final feature in classFeatures) ...[
                        Text(
                          feature.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(feature.description),
                        const SizedBox(height: 8),
                      ],
                      for (final feature in subclassFeatures) ...[
                        Text(
                          feature.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(feature.description),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (progression.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Прогрессия класса',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        for (final item in progression)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• $item'),
                          ),
                      ],
                    ),
                  ),
                ),
              if (hasAsi)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Увеличение характеристик или черта',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text('Выбери один вариант:'),

                        RadioGroup<String>(
                          groupValue: _asiChoice,
                          onChanged: (value) {
                            setState(() {
                              _asiChoice = value!;
                              _firstAbility = null;
                              _secondAbility = null;
                              _selectedFeatId = null;
                            });
                          },
                          child: const Column(
                            children: [
                              RadioListTile<String>(
                                contentPadding: EdgeInsets.zero,
                                title: Text('+2 к одной характеристике'),
                                value: 'plus2',
                              ),
                              RadioListTile<String>(
                                contentPadding: EdgeInsets.zero,
                                title: Text('+1 к двум разным характеристикам'),
                                value: 'plus1',
                              ),
                              RadioListTile<String>(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Выбрать черту'),
                                value: 'feat',
                              ),
                            ],
                          ),
                        ),

                        if (_asiChoice == 'plus2' || _asiChoice == 'plus1') ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _firstAbility,
                            decoration: InputDecoration(
                              labelText: _asiChoice == 'plus2'
                                  ? 'Выбери характеристику (+2)'
                                  : 'Первая характеристика (+1)',
                              border: const OutlineInputBorder(),
                            ),
                            items:
                                _availableAbilities(
                                      _asiChoice == 'plus2' ? 18 : 19,
                                    )
                                    .map(
                                      (ability) => DropdownMenuItem<String>(
                                        value: ability,
                                        child: Text(_abilityNames[ability]!),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                _firstAbility = value;
                                _secondAbility = null;
                              });
                            },
                          ),
                        ],

                        if (_asiChoice == 'plus1') ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _secondAbility,
                            decoration: const InputDecoration(
                              labelText: 'Вторая характеристика (+1)',
                              border: OutlineInputBorder(),
                            ),
                            items: _availableAbilities(19)
                                .where((ability) => ability != _firstAbility)
                                .map(
                                  (ability) => DropdownMenuItem<String>(
                                    value: ability,
                                    child: Text(_abilityNames[ability]!),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _secondAbility = value;
                              });
                            },
                          ),
                        ],

                        if (_asiChoice == 'feat') ...[
                          const SizedBox(height: 12),
                          FutureBuilder<List<FeatData>>(
                            future: _featsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Text(
                                  'Ошибка загрузки черт: ${snapshot.error}',
                                );
                              }

                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final feats = snapshot.data!;

                              final selectedFeat = feats
                                  .where((feat) => feat.id == _selectedFeatId)
                                  .firstOrNull;

                              return Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedFeatId,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Выбери черту',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: feats.map((feat) {
                                      return DropdownMenuItem<String>(
                                        value: feat.id,
                                        child: Text(feat.name),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedFeatId = value;
                                        _selectedFeatAbility = null;

                                        _selectedFeatAbilities.clear();

                                        final feat = feats
                                            .where((item) => item.id == value)
                                            .firstOrNull;

                                        final increase =
                                            feat?.abilityScoreIncrease;

                                        _selectedFeatAbilityBonus =
                                            increase?.amount ?? 0;

                                        if (increase != null) {
                                          _selectedFeatAbilities.addAll(
                                            increase.abilities,
                                          );

                                          if (increase.abilities.length == 1) {
                                            _selectedFeatAbility =
                                                increase.abilities.first;
                                          }
                                        }
                                      });
                                    },
                                  ),

                                  if (selectedFeat != null &&
                                      selectedFeat.abilityScoreIncrease !=
                                          null &&
                                      _selectedFeatAbilities.length > 1) ...[
                                    const SizedBox(height: 12),

                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedFeatAbility,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Выбери характеристику для увеличения',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: _selectedFeatAbilities
                                          .where(
                                            (ability) =>
                                                (widget
                                                        .character
                                                        .effectiveAbilityScores[ability] ??
                                                    8) <
                                                20,
                                          )
                                          .map(
                                            (ability) =>
                                                DropdownMenuItem<String>(
                                                  value: ability,
                                                  child: Text(
                                                    _abilityNames[ability] ??
                                                        ability,
                                                  ),
                                                ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedFeatAbility = value;
                                        });
                                      },
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),
              const SizedBox(height: 16),

              FilledButton.icon(
                onPressed: _gainedHitPoints == null
                    ? null
                    : () => _confirm(nextLevel, features, hasAsi, classData),
                icon: const Icon(Icons.check),
                label: const Text('Подтвердить повышение'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
            ],
          );
        },
      ),
    );
  }
}
