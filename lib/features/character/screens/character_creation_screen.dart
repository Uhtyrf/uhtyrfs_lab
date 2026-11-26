import 'dart:math';

import 'package:flutter/material.dart';

import '../../../data/loaders/background_loader.dart';
import '../../../data/loaders/feat_loader.dart';
import '../../../data/loaders/class_loader.dart';
import '../../../data/loaders/race_loader.dart';
import '../../../data/loaders/spell_loader.dart';
import '../../../models/background_data.dart';
import '../../../models/feat_data.dart';
import '../../../models/class_data.dart';
import '../../../models/race_data.dart';
import '../../../models/spell_data.dart';
import '../models/character.dart';
import '../models/ability.dart';
import 'spell_selection_dialog.dart';

class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  late Future<_CreationData> _dataFuture;

  final _nameController = TextEditingController();
  final _random = Random();

  int _step = 0;

  // Подтверждённые этапы.
  String _savedName = '';
  String? _savedRaceId;
  String? _savedSubraceId;
  String? _savedDraconicAncestry;
  String _savedHumanVariant = 'standard';
  String? _savedHumanAbility1;
  String? _savedHumanAbility2;
  List<String> _savedRaceAbilityChoices = [];
  String? _savedHumanSkill;
  String? _savedHumanFeatId;
  String? _savedClassId;
  String? _savedSubclassId;
  String? _savedWarlockGenieKind;
  String? _savedCircleOfLandTerrain;
  List<String> _savedWizardStartingSpellIds = [];
  List<String> _savedWizardCantripIds = [];
  List<String> _savedWarlockSpellIds = [];
  List<String> _savedWarlockCantripIds = [];
  List<String> _savedBardSpellIds = [];
  List<String> _savedBardCantripIds = [];
  List<String> _savedSorcererSpellIds = [];
  List<String> _savedSorcererCantripIds = [];
  String? _savedBackgroundId;

  List<String> _savedClassSkillProficiencies = [];
  String? _savedBackgroundChosenSkill;

  Map<String, int> _savedAbilityScores = {};

  // Временные данные текущего этапа.
  String? _raceId;
  String? _subraceId;
  String? _draconicAncestry;
  String _humanVariant = 'standard';
  String? _humanAbility1;
  String? _humanAbility2;
  final List<String> _raceAbilityChoices = [];
  String? _humanSkill;
  String? _humanFeatId;
  String? _humanFeatAbility;

  String? _classId;
  String? _subclassId;
  String? _warlockGenieKind;
  String? _circleOfLandTerrain;
  final List<String> _wizardStartingSpellIds = [];
  final List<String> _wizardCantripIds = [];
  final List<String> _warlockStartingSpellIds = [];
  final List<String> _warlockCantripIds = [];
  final List<String> _bardStartingSpellIds = [];
  final List<String> _bardCantripIds = [];
  final List<String> _sorcererStartingSpellIds = [];
  final List<String> _sorcererCantripIds = [];

  String? _backgroundId;
  String? _backgroundChosenSkill;

  final List<String> _classSkillProficiencies = [];

  String _abilityMode = 'roll';

  final Map<String, int> _abilityScores = {
    'str': 8,
    'dex': 8,
    'con': 8,
    'int': 8,
    'wis': 8,
    'cha': 8,
  };

  final Set<String> _rolledAbilities = {};

  static final Map<String, String> _abilityNames = {
    for (final ability in Ability.all) ability.jsonKey: ability.name,
  };

  static final Map<String, String> _abilityShortNames = {
    for (final ability in Ability.all) ability.key: ability.name,
  };

  static const List<String> _skills = [
    'Акробатика',
    'Анализ',
    'Атлетика',
    'Восприятие',
    'Выживание',
    'Выступление',
    'Запугивание',
    'История',
    'Ловкость рук',
    'Магия',
    'Медицина',
    'Обман',
    'Природа',
    'Проницательность',
    'Религия',
    'Скрытность',
    'Убеждение',
    'Уход за животными',
  ];

  // Стоимость Point Buy D&D 5e (2014).
  static const Map<int, int> _pointBuyCosts = {
    8: 0,
    9: 1,
    10: 2,
    11: 3,
    12: 4,
    13: 5,
    14: 7,
    15: 9,
  };

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_CreationData> _loadData() async {
    final results = await Future.wait([
      loadRaces(),
      loadClasses(),
      loadBackgrounds(),
      loadFeats(),
      loadSpells(),
    ]);

    return _CreationData(
      races: results[0] as List<RaceData>,
      classes: results[1] as List<DndClassData>,
      backgrounds: results[2] as List<BackgroundData>,
      feats: results[3] as List<FeatData>,
      spells: results[4] as List<SpellData>,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int _costForScore(int score) {
    if (score <= 8) return 0;
    if (score <= 15) return _pointBuyCosts[score] ?? 0;

    return 9 + (score - 15) * 2;
  }

  int get _spentPoints {
    return _abilityScores.values.fold(
      0,
      (sum, score) => sum + _costForScore(score),
    );
  }

  int get _remainingPoints => 27 - _spentPoints;

  int _modifier(int score) => ((score - 10) / 2).floor();

  void _changeAbility(String ability, int change) {
    if (_abilityMode != 'buy') return;

    final current = _abilityScores[ability] ?? 8;
    final next = current + change;

    if (next < 8) return;

    if (change > 0) {
      final additionalCost = _costForScore(next) - _costForScore(current);

      if (additionalCost > _remainingPoints) return;
    }

    setState(() {
      _abilityScores[ability] = next;
    });
  }

  void _rollAbility(String ability) {
    if (_rolledAbilities.contains(ability)) return;

    final dice = List.generate(4, (_) => _random.nextInt(6) + 1);
    dice.sort();

    final result = dice[1] + dice[2] + dice[3];

    setState(() {
      _abilityScores[ability] = result;
      _rolledAbilities.add(ability);
    });
  }

  void _resetAbilityStep() {
    _abilityMode = 'roll';

    _abilityScores
      ..clear()
      ..addAll({'str': 8, 'dex': 8, 'con': 8, 'int': 8, 'wis': 8, 'cha': 8});

    _rolledAbilities.clear();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Варианты навыков, которые можно выбрать от предыстории.
  List<String> _backgroundSkillChoices(BackgroundData? background) {
    if (background == null) return [];

    for (final entry in background.skillProficiencies) {
      const prefix = 'Один навык на выбор:';

      if (entry.startsWith(prefix)) {
        final optionsText = entry.substring(prefix.length).trim();

        return optionsText
            .replaceAll(' или ', ', ')
            .split(',')
            .map((skill) => skill.trim())
            .where((skill) => skill.isNotEmpty)
            .toList();
      }
    }

    return [];
  }

  // Количество навыков, которые нужно выбрать для класса.
  int _classSkillChoiceCount(_CreationData data) {
    if (_classId == null) return 0;

    final selectedClass = data.classes.firstWhere(
      (item) => item.id == _classId,
    );

    final skills = selectedClass.proficiencies['skills'];

    if (skills is! Map) return 0;

    return (skills['choose'] as num?)?.toInt() ?? 0;
  }

  // Список навыков, разрешённых выбранному классу.
  List<String> _availableClassSkills(_CreationData data) {
    if (_classId == null) return [];

    final selectedClass = data.classes.firstWhere(
      (item) => item.id == _classId,
    );

    final skills = selectedClass.proficiencies['skills'];

    if (skills is! Map) return [];

    final from = skills['from'];

    List<String> options;

    if (from == 'any') {
      options = List<String>.from(_skills);
    } else if (from is List) {
      options = from.map((item) => item.toString()).toList();
    } else {
      return [];
    }

    final background = _backgroundId == null
        ? null
        : data.backgrounds.firstWhere((item) => item.id == _backgroundId);

    final humanSkill = _humanVariant == 'variant-human' && _raceId == 'human'
        ? _humanSkill
        : null;

    final alreadyKnown = <String>{
      ?humanSkill,
      ...?background?.skillProficiencies.where(
        (skill) => !skill.startsWith('Один навык на выбор:'),
      ),
      ?_backgroundChosenSkill,
    };

    return options
        .where((skill) => !alreadyKnown.contains(skill))
        .toSet()
        .toList();
  }

  // Переход вперёд.
  void _next(_CreationData data) {
    switch (_step) {
      case 0:
        final name = _nameController.text.trim();

        if (name.isEmpty) {
          _showMessage('Введи имя персонажа');
          return;
        }

        _savedName = name;
        break;

      case 1:
        if (_raceId == null) {
          _showMessage('Выбери расу');
          return;
        }

        final race = data.races.firstWhere((item) => item.id == _raceId);

        if (race.subraces.isNotEmpty && _subraceId == null) {
          _showMessage('Выбери подрасу');
          return;
        }

        if (race.id == 'dragonborn' && _draconicAncestry == null) {
          _showMessage('Выбери драконье наследие');
          return;
        }

        final isVariantHuman =
            race.id == 'human' && _humanVariant == 'variant-human';

        if (isVariantHuman) {
          if (_humanAbility1 == null ||
              _humanAbility2 == null ||
              _humanAbility1 == _humanAbility2 ||
              _humanSkill == null ||
              _humanFeatId == null) {
            _showMessage('Заполни все выборы альтернативного человека');
            return;
          }
        }
        if (isVariantHuman && _humanFeatId != null) {
          final feat = data.feats.firstWhere((feat) => feat.id == _humanFeatId);

          final increase = feat.abilityScoreIncrease;

          if (increase != null &&
              increase.abilities.length > 1 &&
              _humanFeatAbility == null) {
            _showMessage('Выбери характеристику от черты');
            return;
          }
        }

        final raceChoice = _raceAbilityChoiceDefinition(race);
        final requiredRaceChoices =
            (raceChoice?['count'] as num?)?.toInt() ?? 0;
        if (!isVariantHuman &&
            requiredRaceChoices > 0 &&
            (_raceAbilityChoices.length != requiredRaceChoices ||
                _raceAbilityChoices.any((choice) => choice.isEmpty) ||
                _raceAbilityChoices.toSet().length != requiredRaceChoices)) {
          _showMessage(
            'Выбери $requiredRaceChoices разные характеристики от расы',
          );
          return;
        }

        _savedRaceAbilityChoices = List<String>.from(_raceAbilityChoices);
        _savedRaceId = _raceId;
        _savedSubraceId = _subraceId;
        _savedDraconicAncestry = _draconicAncestry;
        _savedHumanVariant = _humanVariant;
        _savedHumanAbility1 = _humanAbility1;
        _savedHumanAbility2 = _humanAbility2;
        _savedHumanSkill = _humanSkill;
        _savedHumanFeatId = _humanFeatId;
        break;

      case 2:
        if (_classId == null) {
          _showMessage('Выбери класс');
          return;
        }

        final selectedClass = data.classes.firstWhere(
          (item) => item.id == _classId,
        );

        if (selectedClass.subclasses.isNotEmpty && _subclassId == null) {
          _showMessage('Выбери подкласс');
          return;
        }

        final isCircleOfLand =
            selectedClass.id == 'druid' && _subclassId == 'circle_of_land';
        if (isCircleOfLand && _circleOfLandTerrain == null) {
          _showMessage('Выбери местность Круга земли');
          return;
        }
        if (selectedClass.id == 'warlock' &&
            _subclassId == 'genie' &&
            _warlockGenieKind == null) {
          _showMessage('Выбери вид джинна для расширенного списка заклинаний.');
          return;
        }

        if (selectedClass.id == 'wizard' &&
            (_wizardStartingSpellIds.toSet().length != 6 ||
                _wizardCantripIds.toSet().length != 3)) {
          _showMessage(
            'Для волшебника выбери 6 заклинаний 1-го круга и 3 заговора.',
          );
          return;
        }
        if (selectedClass.id == 'warlock' &&
            (_warlockStartingSpellIds.toSet().length != 2 ||
                _warlockCantripIds.toSet().length != 2)) {
          _showMessage(
            'Для колдуна выбери 2 известных заклинания 1-го круга и 2 заговора.',
          );
          return;
        }
        if (selectedClass.id == 'bard' &&
            (_bardStartingSpellIds.toSet().length != 4 ||
                _bardCantripIds.toSet().length != 2)) {
          _showMessage('Для барда выбери 4 известных заклинания 1-го круга и 2 заговора.');
          return;
        }
        if (selectedClass.id == 'sorcerer' &&
            (_sorcererStartingSpellIds.toSet().length != 2 ||
                _sorcererCantripIds.toSet().length != 4)) {
          _showMessage('Для чародея выбери 2 известных заклинания 1-го круга и 4 заговора.');
          return;
        }

        _savedClassId = _classId;
        _savedSubclassId = _subclassId;
        _savedWarlockGenieKind =
            selectedClass.id == 'warlock' && _subclassId == 'genie'
            ? _warlockGenieKind
            : null;
        _savedWizardStartingSpellIds = selectedClass.id == 'wizard'
            ? List<String>.from(_wizardStartingSpellIds.toSet())
            : [];
        _savedWizardCantripIds = selectedClass.id == 'wizard'
            ? List<String>.from(_wizardCantripIds.toSet())
            : [];
        _savedWarlockSpellIds = selectedClass.id == 'warlock'
            ? List<String>.from(_warlockStartingSpellIds.toSet())
            : [];
        _savedWarlockCantripIds = selectedClass.id == 'warlock'
            ? List<String>.from(_warlockCantripIds.toSet())
            : [];
        _savedBardSpellIds = selectedClass.id == 'bard'
            ? List<String>.from(_bardStartingSpellIds.toSet())
            : [];
        _savedBardCantripIds = selectedClass.id == 'bard'
            ? List<String>.from(_bardCantripIds.toSet())
            : [];
        _savedSorcererSpellIds = selectedClass.id == 'sorcerer'
            ? List<String>.from(_sorcererStartingSpellIds.toSet())
            : [];
        _savedSorcererCantripIds = selectedClass.id == 'sorcerer'
            ? List<String>.from(_sorcererCantripIds.toSet())
            : [];
        _savedCircleOfLandTerrain = isCircleOfLand
            ? _circleOfLandTerrain
            : null;
        break;

      case 3:
        final selectedBackground = _backgroundId == null
            ? null
            : data.backgrounds.firstWhere((item) => item.id == _backgroundId);

        final backgroundChoices = _backgroundSkillChoices(selectedBackground);

        if (backgroundChoices.isNotEmpty && _backgroundChosenSkill == null) {
          _showMessage('Выбери один навык от предыстории');
          return;
        }

        final requiredSkills = _classSkillChoiceCount(data);

        if (_classSkillProficiencies.length != requiredSkills) {
          _showMessage('Выбери навыки класса: $requiredSkills');
          return;
        }

        _savedBackgroundId = _backgroundId;
        _savedBackgroundChosenSkill = _backgroundChosenSkill;

        _savedClassSkillProficiencies = List<String>.from(
          _classSkillProficiencies,
        );
        break;

      case 4:
        if (_abilityMode == 'roll' && _rolledAbilities.length != 6) {
          _showMessage('Сделай отдельный бросок для каждой характеристики');
          return;
        }

        if (_abilityMode == 'buy' && _remainingPoints != 0) {
          _showMessage('Распредели все 27 очков. Осталось: $_remainingPoints');
          return;
        }

        _savedAbilityScores = Map<String, int>.from(_abilityScores);
        break;
    }

    setState(() {
      if (_step < 5) _step++;
    });
  }

  // Возврат на предыдущий этап.
  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      switch (_step) {
        case 1:
          _raceId = null;
          _subraceId = null;
          _draconicAncestry = null;
          _humanVariant = 'standard';
          _humanAbility1 = null;
          _humanAbility2 = null;
          _humanSkill = null;
          _humanFeatId = null;
          _raceAbilityChoices.clear();
          break;

        case 2:
          _classId = null;
          _subclassId = null;
          _circleOfLandTerrain = null;
          break;

        case 3:
          _backgroundId = null;
          _backgroundChosenSkill = null;
          _classSkillProficiencies.clear();
          break;

        case 4:
          _resetAbilityStep();
          break;

        case 5:
          break;
      }

      _step--;
    });
  }

  void _create(_CreationData data) {
    final race = data.races.firstWhere((item) => item.id == _savedRaceId);

    final characterClass = data.classes.firstWhere(
      (item) => item.id == _savedClassId,
    );

    final subrace = _savedSubraceId == null
        ? null
        : race.subraces.firstWhere((item) => item.id == _savedSubraceId);

    final selectedSubclass = _savedSubclassId == null
        ? null
        : characterClass.subclasses.firstWhere(
            (item) => item.id == _savedSubclassId,
          );

    final background = _savedBackgroundId == null
        ? null
        : data.backgrounds.firstWhere((item) => item.id == _savedBackgroundId);

    final isVariantHuman =
        race.id == 'human' && _savedHumanVariant == 'variant-human';

    final selectedFeat = isVariantHuman
        ? data.feats.firstWhere((feat) => feat.id == _savedHumanFeatId)
        : null;
    final startingAbilityScores = Map<String, int>.from(_savedAbilityScores);

    if (selectedFeat?.abilityScoreIncrease != null) {
      final increase = selectedFeat!.abilityScoreIncrease!;
      final ability = _humanFeatAbility;

      if (ability == null) {
        _showMessage('Не выбрана характеристика от черты');
        return;
      }

      startingAbilityScores[ability] =
          (startingAbilityScores[ability] ?? 8) + increase.amount;
    }

    final automaticBackgroundSkills =
        background?.skillProficiencies
            .where((skill) => !skill.startsWith('Один навык на выбор:'))
            .toList() ??
        [];

    final savedBackgroundSkills = [
      ...automaticBackgroundSkills,
      ?_savedBackgroundChosenSkill,
    ];
    final now = DateTime.now();

    final character = Character(
      id: now.microsecondsSinceEpoch.toString(),
      name: _savedName,
      race: race.name,
      subrace: subrace?.name ?? '',
      draconicAncestry: _savedDraconicAncestry ?? '',
      raceVariant: isVariantHuman ? 'variant-human' : '',
      racialAbilityBonuses: _racialBonusesFor(race, subrace, isVariantHuman),

      // Навыки альтернативного человека.
      racialSkillProficiency: isVariantHuman ? _savedHumanSkill ?? '' : '',

      racialSkillProficiencies: isVariantHuman && _savedHumanSkill != null
          ? [_savedHumanSkill!]
          : [],

      // Навыки от предыстории.
      backgroundSkillProficiencies: savedBackgroundSkills,

      // Навыки, выбранные от класса.
      classSkillProficiencies: List<String>.from(_savedClassSkillProficiencies),

      racialFeatId: selectedFeat?.id ?? '',
      racialFeatName: selectedFeat?.name ?? '',
      characterClass: characterClass.name,
      subclassId: selectedSubclass?.id ?? '',
      subclassName: selectedSubclass?.name ?? '',
      warlockGenieKind: _savedWarlockGenieKind ?? '',
      circleOfLandTerrain: _savedCircleOfLandTerrain ?? '',
      spellbookSpellIds: _savedClassId == 'wizard'
          ? List<String>.from(_savedWizardStartingSpellIds)
          : const [],
      knownSpellIds: _savedClassId == 'warlock'
          ? List<String>.from(_savedWarlockSpellIds)
          : _savedClassId == 'bard'
          ? List<String>.from(_savedBardSpellIds)
          : _savedClassId == 'sorcerer'
          ? List<String>.from(_savedSorcererSpellIds)
          : const [],
      knownCantripIds: _savedClassId == 'wizard'
          ? List<String>.from(_savedWizardCantripIds)
          : _savedClassId == 'warlock'
          ? List<String>.from(_savedWarlockCantripIds)
          : _savedClassId == 'bard'
          ? List<String>.from(_savedBardCantripIds)
          : _savedClassId == 'sorcerer'
          ? List<String>.from(_savedSorcererCantripIds)
          : const [],
      background: background?.name ?? '',
      abilityScores: startingAbilityScores,
      level: 1,
    );
    // Рассчитываем начальные хиты персонажа
    final conScore = character.effectiveAbilityScores['con'] ?? 8;
    final conModifier = ((conScore - 10) / 2).floor();

    final initialHitPoints = characterClass.hitDie + conModifier;

    character.maxHitPoints = initialHitPoints < 1 ? 1 : initialHitPoints;
    character.currentHitPoints = character.maxHitPoints;
    character.hitDiceTotal = 1;
    character.hitDiceUsed = 0;
    Navigator.of(context).pop(character);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Создание персонажа — ${_step + 1}/6'),
        leading: IconButton(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Назад',
        ),
      ),
      body: FutureBuilder<_CreationData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'Не удалось загрузить справочники:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _dataFuture = _loadData();
                        });
                      },
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;

          if (data.races.isEmpty || data.classes.isEmpty) {
            return const Center(
              child: Text('В справочниках не найдены расы или классы.'),
            );
          }

          return Column(
            children: [
              Expanded(child: _buildCurrentStep(data)),
              _navigationButtons(data),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentStep(_CreationData data) {
    switch (_step) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildRaceStep(data);
      case 2:
        return _buildClassStep(data);
      case 3:
        return _buildBackgroundStep(data);
      case 4:
        return _buildAbilityStep();
      case 5:
        return _buildSummaryStep(data);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _stepContent({
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }

  Widget _buildNameStep() {
    return _stepContent(
      title: 'Шаг 1. Имя персонажа',
      description: 'Как зовут твоего героя?',
      children: [
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Имя персонажа',
            hintText: 'Например, Филд Коппер',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic>? _raceAbilityChoiceDefinition(RaceData race) {
    if (race.abilityBonusChoices.isEmpty) return null;
    return race.abilityBonusChoices.first;
  }

  List<Widget> _buildRaceAbilityChoiceFields(RaceData race) {
    final choice = _raceAbilityChoiceDefinition(race)!;
    final count = (choice['count'] as num?)?.toInt() ?? 0;
    final amount = (choice['amount'] as num?)?.toInt() ?? 1;
    final excluded = (choice['exclude'] as List? ?? [])
        .map((e) => e.toString())
        .toSet();
    final chooseFrom = (choice['chooseFrom'] as List? ?? [])
        .map((e) => e.toString())
        .where((key) => !excluded.contains(key))
        .toList();

    return List<Widget>.generate(count, (index) {
      final selected = index < _raceAbilityChoices.length
          ? _raceAbilityChoices[index]
          : null;
      final usedByOthers = _raceAbilityChoices
          .asMap()
          .entries
          .where((entry) => entry.key != index)
          .map((entry) => entry.value)
          .toSet();
      return Padding(
        padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 12),
        child: DropdownButtonFormField<String>(
          key: ValueKey('race-ability-choice-$index-${race.id}'),
          initialValue: selected,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Бонус расы +$amount: характеристика ${index + 1}',
            border: const OutlineInputBorder(),
          ),
          items: chooseFrom
              .where((key) => !usedByOthers.contains(key) || key == selected)
              .map(
                (key) => DropdownMenuItem(
                  value: key,
                  child: Text(_abilityNames[key] ?? key),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              while (_raceAbilityChoices.length <= index) {
                _raceAbilityChoices.add('');
              }
              if (value == null) {
                _raceAbilityChoices[index] = '';
              } else {
                _raceAbilityChoices[index] = value;
              }
              while (_raceAbilityChoices.isNotEmpty &&
                  _raceAbilityChoices.last.isEmpty) {
                _raceAbilityChoices.removeLast();
              }
            });
          },
        ),
      );
    });
  }

  Map<String, int> _racialBonusesFor(
    RaceData race,
    RaceSubrace? subrace,
    bool isVariantHuman,
  ) {
    final bonuses = <String, int>{};
    void add(Map<String, int> values) {
      for (final entry in Ability.normalizeBonuses(values).entries) {
        bonuses[entry.key] = (bonuses[entry.key] ?? 0) + entry.value;
      }
    }

    if (isVariantHuman) {
      add({_savedHumanAbility1!: 1, _savedHumanAbility2!: 1});
      return bonuses;
    }

    add(race.abilityBonuses);
    final subraceBonuses = subrace?.mechanics['abilityBonuses'];
    if (subraceBonuses is Map) {
      add(
        subraceBonuses.map(
          (key, value) => MapEntry(key.toString(), (value as num).toInt()),
        ),
      );
    }

    final choice = _raceAbilityChoiceDefinition(race);

    if (choice != null) {
      final amount = (choice['amount'] as num?)?.toInt() ?? 1;

      for (final key in _savedRaceAbilityChoices) {
        final normalized = Ability.normalizeKey(key);

        if (normalized != null) {
          bonuses[normalized] = (bonuses[normalized] ?? 0) + amount;
        }
      }
    }

    return bonuses;
  }

  Map<String, int> _effectiveAbilityScores(_CreationData data) {
    if (_savedRaceId == null) {
      return Map<String, int>.from(_savedAbilityScores);
    }

    final race = data.races.firstWhere((item) => item.id == _savedRaceId);
    final subrace = _savedSubraceId == null
        ? null
        : race.subraces.firstWhere((item) => item.id == _savedSubraceId);

    final isVariantHuman =
        race.id == 'human' && _savedHumanVariant == 'variant-human';

    final bonuses = _racialBonusesFor(race, subrace, isVariantHuman);

    final feat = _savedHumanFeatId == null
        ? null
        : data.feats.firstWhere((item) => item.id == _savedHumanFeatId);

    final featIncrease = feat?.abilityScoreIncrease;

    final featBonuses = <String, int>{};

    if (featIncrease != null && _humanFeatAbility != null) {
      featBonuses[_humanFeatAbility!] = featIncrease.amount;
    }

    return {
      for (final ability in Ability.all)
        ability.key:
            (_savedAbilityScores[ability.key] ?? 8) +
            (bonuses[ability.key] ?? 0) +
            (featBonuses[ability.key] ?? 0),
    };
  }

  Widget _buildRaceStep(_CreationData data) {
    final selectedRace = _raceId == null
        ? null
        : data.races.firstWhere((item) => item.id == _raceId);
    final selectedHumanFeat = _humanFeatId == null
        ? null
        : data.feats.firstWhere((feat) => feat.id == _humanFeatId);

    final featAbilityIncrease = selectedHumanFeat?.abilityScoreIncrease;

    return _stepContent(
      title: 'Шаг 2. Раса',
      description:
          'Выбери расу и заполни все дополнительные расовые параметры.',
      children: [
        DropdownButtonFormField<String>(
          initialValue: _raceId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Раса',
            border: OutlineInputBorder(),
          ),
          items: data.races.map((race) {
            return DropdownMenuItem(value: race.id, child: Text(race.name));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _raceId = value;
              _subraceId = null;
              _draconicAncestry = null;
              _humanVariant = 'standard';
              _humanAbility1 = null;
              _humanAbility2 = null;
              _humanSkill = null;
              _humanFeatId = null;
              _raceAbilityChoices.clear();
            });
          },
        ),
        if (selectedRace != null) ...[
          const SizedBox(height: 12),
          _DescriptionCard(text: selectedRace.description),
        ],
        if (selectedRace != null && selectedRace.subraces.isNotEmpty) ...[
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _subraceId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Подраса',
              border: OutlineInputBorder(),
            ),
            items: selectedRace.subraces.map((item) {
              return DropdownMenuItem(value: item.id, child: Text(item.name));
            }).toList(),
            onChanged: (value) {
              setState(() => _subraceId = value);
            },
          ),
          if (_subraceId != null) ...[
            const SizedBox(height: 8),
            _DescriptionCard(
              text: selectedRace.subraces
                  .firstWhere((item) => item.id == _subraceId)
                  .description,
            ),
          ],
        ],
        if (selectedRace != null &&
            selectedRace.id != 'human' &&
            _raceAbilityChoiceDefinition(selectedRace) != null) ...[
          const SizedBox(height: 20),
          ..._buildRaceAbilityChoiceFields(selectedRace),
        ],
        if (selectedRace?.id == 'dragonborn') ...[
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _draconicAncestry,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Драконье наследие',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'black', child: Text('Чёрный — кислота')),
              DropdownMenuItem(
                value: 'blue',
                child: Text('Синий — электричество'),
              ),
              DropdownMenuItem(value: 'brass', child: Text('Латунный — огонь')),
              DropdownMenuItem(
                value: 'bronze',
                child: Text('Бронзовый — электричество'),
              ),
              DropdownMenuItem(
                value: 'copper',
                child: Text('Медный — кислота'),
              ),
              DropdownMenuItem(value: 'gold', child: Text('Золотой — огонь')),
              DropdownMenuItem(value: 'green', child: Text('Зелёный — яд')),
              DropdownMenuItem(value: 'red', child: Text('Красный — огонь')),
              DropdownMenuItem(
                value: 'silver',
                child: Text('Серебряный — холод'),
              ),
              DropdownMenuItem(value: 'white', child: Text('Белый — холод')),
            ],
            onChanged: (value) {
              setState(() => _draconicAncestry = value);
            },
          ),
        ],
        if (selectedRace?.id == 'human') ...[
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _humanVariant,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Вариант человека',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'standard',
                child: Text('Обычный человек'),
              ),
              DropdownMenuItem(
                value: 'variant-human',
                child: Text('Альтернативный человек'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _humanVariant = value ?? 'standard';
                _humanAbility1 = null;
                _humanAbility2 = null;
                _humanSkill = null;
                _humanFeatId = null;
              });
            },
          ),
          const SizedBox(height: 8),
          _DescriptionCard(
            text: _humanVariant == 'standard'
                ? 'Увеличь все шесть характеристик на 1.'
                : 'Выбери две разные характеристики для увеличения на 1, один навык и одну черту.',
          ),
          if (_humanVariant == 'variant-human') ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _humanAbility1,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Первая характеристика (+1)',
                border: OutlineInputBorder(),
              ),
              items: _abilityNames.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _humanAbility1 = value;
                  if (_humanAbility2 == value) {
                    _humanAbility2 = null;
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _humanAbility2,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Вторая характеристика (+1)',
                border: OutlineInputBorder(),
              ),
              items: _abilityNames.entries
                  .where((entry) => entry.key != _humanAbility1)
                  .map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  })
                  .toList(),
              onChanged: (value) {
                setState(() => _humanAbility2 = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _humanSkill,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Навык (владение)',
                border: OutlineInputBorder(),
              ),
              items: _skills.map((skill) {
                return DropdownMenuItem(value: skill, child: Text(skill));
              }).toList(),
              onChanged: (value) {
                setState(() => _humanSkill = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _humanFeatId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Черта',
                border: OutlineInputBorder(),
              ),
              items: data.feats
                  .where(
                    (feat) =>
                        feat.prerequisite == null ||
                        feat.prerequisite!.trim().isEmpty,
                  )
                  .map((feat) {
                    return DropdownMenuItem(
                      value: feat.id,
                      child: Text(feat.name),
                    );
                  })
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _humanFeatId = value;
                  _humanFeatAbility = null;

                  if (value != null) {
                    final feat = data.feats.firstWhere(
                      (feat) => feat.id == value,
                    );

                    final increase = feat.abilityScoreIncrease;

                    if (increase != null) {
                      if (increase.abilities.length == 1) {
                        _humanFeatAbility = increase.abilities.first;
                      }
                    }
                  }
                });
              },
            ),
            if (_humanFeatId != null) ...[
              const SizedBox(height: 8),
              _DescriptionCard(text: selectedHumanFeat!.description),

              if (featAbilityIncrease != null &&
                  featAbilityIncrease.abilities.length > 1) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _humanFeatAbility,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText:
                        'Характеристика от черты (+${featAbilityIncrease.amount})',
                    border: const OutlineInputBorder(),
                  ),
                  items: featAbilityIncrease.abilities.map((ability) {
                    return DropdownMenuItem(
                      value: ability,
                      child: Text(_abilityNames[ability] ?? ability),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _humanFeatAbility = value;
                    });
                  },
                ),
              ],
            ],
          ],
        ],
      ],
    );
  }

  Widget _buildClassStep(_CreationData data) {
    final selectedClass = _classId == null
        ? null
        : data.classes.firstWhere((item) => item.id == _classId);

    return _stepContent(
      title: 'Шаг 3. Класс',
      description: 'Выбери класс и подкласс своего персонажа.',
      children: [
        DropdownButtonFormField<String>(
          initialValue: _classId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Класс',
            border: OutlineInputBorder(),
          ),
          items: data.classes.map((item) {
            return DropdownMenuItem(value: item.id, child: Text(item.name));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _classId = value;
              _subclassId = null;
              _warlockGenieKind = null;
              _circleOfLandTerrain = null;
              _classSkillProficiencies.clear();
              _wizardStartingSpellIds.clear();
              _wizardCantripIds.clear();
              _warlockStartingSpellIds.clear();
              _warlockCantripIds.clear();
              _bardStartingSpellIds.clear();
              _bardCantripIds.clear();
              _sorcererStartingSpellIds.clear();
              _sorcererCantripIds.clear();
            });
          },
        ),
        if (selectedClass != null) ...[
          const SizedBox(height: 12),
          _DescriptionCard(text: selectedClass.description),
        ],
        if (selectedClass?.id == 'wizard') ...[
          const SizedBox(height: 16),
          _buildWizardStartingMagic(data, selectedClass!),
        ],
        if (selectedClass?.id == 'bard') ...[
          const SizedBox(height: 16),
          _buildBardStartingMagic(data, selectedClass!),
        ],
        if (selectedClass?.id == 'sorcerer') ...[
          const SizedBox(height: 16),
          _buildSorcererStartingMagic(data, selectedClass!),
        ],
        if (selectedClass != null && selectedClass.subclasses.isNotEmpty) ...[
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _subclassId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Подкласс',
              border: OutlineInputBorder(),
            ),
            items: selectedClass.subclasses.map((item) {
              return DropdownMenuItem(value: item.id, child: Text(item.name));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _subclassId = value;
                _warlockGenieKind = null;
                _warlockStartingSpellIds.clear();
                _warlockCantripIds.clear();
                if (value != 'circle_of_land') {
                  _circleOfLandTerrain = null;
                }
              });
            },
          ),
          if (selectedClass.id == 'warlock' && _subclassId == 'genie') ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _warlockGenieKind,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Вид джинна',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'dao', child: Text('Dao')),
                DropdownMenuItem(value: 'djinni', child: Text('Djinni')),
                DropdownMenuItem(value: 'efreeti', child: Text('Efreeti')),
                DropdownMenuItem(value: 'marid', child: Text('Marid')),
              ],
              onChanged: (value) {
                setState(() {
                  _warlockGenieKind = value;
                  _warlockStartingSpellIds.clear();
                });
              },
            ),
          ],
          if (selectedClass.id == 'druid' &&
              _subclassId == 'circle_of_land') ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _circleOfLandTerrain,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Выбор местности',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'arctic',
                  child: Text('Arctic — Арктика'),
                ),
                DropdownMenuItem(
                  value: 'coast',
                  child: Text('Coast — Побережье'),
                ),
                DropdownMenuItem(
                  value: 'desert',
                  child: Text('Desert — Пустыня'),
                ),
                DropdownMenuItem(value: 'forest', child: Text('Forest — Лес')),
                DropdownMenuItem(
                  value: 'grassland',
                  child: Text('Grassland — Луга'),
                ),
                DropdownMenuItem(
                  value: 'mountain',
                  child: Text('Mountain — Горы'),
                ),
                DropdownMenuItem(value: 'swamp', child: Text('Swamp — Болото')),
                DropdownMenuItem(
                  value: 'underdark',
                  child: Text('Underdark — Подземье'),
                ),
              ],
              onChanged: (value) {
                setState(() => _circleOfLandTerrain = value);
              },
            ),
          ],
          if (selectedClass.id == 'warlock' &&
              _subclassId != null &&
              (_subclassId != 'genie' || _warlockGenieKind != null)) ...[
            const SizedBox(height: 16),
            _buildWarlockStartingMagic(data, selectedClass, _subclassId!),
          ],
          if (_subclassId != null) ...[
            const SizedBox(height: 8),
            _DescriptionCard(
              text: selectedClass.subclasses
                  .firstWhere((item) => item.id == _subclassId)
                  .description,
            ),
          ],
        ],
      ],
    );
  }

  bool _isWizardSpell(SpellData spell, DndClassData wizard) {
    return spell.classes.any((name) {
      final normalized = name.trim().toLowerCase();
      return normalized == wizard.id.toLowerCase() ||
          normalized == wizard.name.trim().toLowerCase() ||
          normalized == wizard.englishName.trim().toLowerCase();
    });
  }

  bool _isWarlockSpell(SpellData spell, DndClassData warlock, String patronId) {
    final classSpell = spell.classes.any((name) {
      final normalized = name.trim().toLowerCase();
      return normalized == warlock.id ||
          normalized == warlock.name.trim().toLowerCase() ||
          normalized == warlock.englishName.trim().toLowerCase();
    });
    if (classSpell || spell.subclasses.contains(patronId)) return true;
    return patronId == 'genie' &&
        _warlockGenieKind != null &&
        spell.subclasses.contains('genie_${_warlockGenieKind!}');
  }

  Future<void> _chooseWizardSpells(
    List<SpellData> spells, {
    required int level,
    required int count,
    required String title,
    required List<String> currentIds,
    required ValueChanged<List<String>> onSelected,
  }) async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) => SpellSelectionDialog(
        spells: spells.where((spell) => spell.level == level).toList(),
        selectionCount: count,
        title: title,
        initialSelectedIds: currentIds,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => onSelected(selected));
  }

  bool _isBardSpell(SpellData spell, DndClassData bard) =>
      spell.classes.any((name) {
        final normalized = name.trim().toLowerCase();
        return normalized == bard.id ||
            normalized == bard.name.trim().toLowerCase() ||
            normalized == bard.englishName.trim().toLowerCase();
      });

  Widget _buildBardStartingMagic(_CreationData data, DndClassData bard) {
    final bardSpells = data.spells.where((spell) => _isBardSpell(spell, bard));
    final leveledSpells = bardSpells.where((spell) => spell.level == 1).toList();
    final cantrips = bardSpells.where((spell) => spell.level == 0).toList();
    final knownNames = leveledSpells
        .where((spell) => _bardStartingSpellIds.contains(spell.id))
        .map((spell) => spell.name)
        .toList();
    final cantripNames = cantrips
        .where((spell) => _bardCantripIds.contains(spell.id))
        .map((spell) => spell.name)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Магия барда', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'На 1-м уровне выбери 4 известных заклинания 1-го круга и 2 заговора.',
            ),
            const SizedBox(height: 8),
            Text('Известные заклинания: ${_bardStartingSpellIds.toSet().length}/4'),
            if (knownNames.isNotEmpty) Text(knownNames.join(' · ')),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _chooseWizardSpells(
                  leveledSpells,
                  level: 1,
                  count: 4,
                  title: 'Выбери 4 известных заклинания барда',
                  currentIds: _bardStartingSpellIds,
                  onSelected: (ids) {
                    _bardStartingSpellIds
                      ..clear()
                      ..addAll(ids);
                  },
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Выбрать заклинания'),
              ),
            ),
            const Divider(),
            Text('Заговоры: ${_bardCantripIds.toSet().length}/2'),
            if (cantripNames.isNotEmpty) Text(cantripNames.join(' · ')),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _chooseWizardSpells(
                  cantrips,
                  level: 0,
                  count: 2,
                  title: 'Выбери 2 заговора барда',
                  currentIds: _bardCantripIds,
                  onSelected: (ids) {
                    _bardCantripIds
                      ..clear()
                      ..addAll(ids);
                  },
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Выбрать заговоры'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSorcererSpell(SpellData spell, DndClassData sorcerer) =>
      spell.classes.any((name) {
        final normalized = name.trim().toLowerCase();
        return normalized == sorcerer.id.toLowerCase() ||
            normalized == sorcerer.name.trim().toLowerCase() ||
            normalized == sorcerer.englishName.trim().toLowerCase();
      });

  Widget _buildSorcererStartingMagic(
    _CreationData data,
    DndClassData sorcerer,
  ) {
    final sorcererSpells = data.spells
        .where((spell) => _isSorcererSpell(spell, sorcerer))
        .toList();
    final leveledSpells = sorcererSpells
        .where((spell) => spell.level == 1)
        .toList();
    final cantrips = sorcererSpells
        .where((spell) => spell.level == 0)
        .toList();
    final knownNames = leveledSpells
        .where((spell) => _sorcererStartingSpellIds.contains(spell.id))
        .map((spell) => spell.name)
        .toList();
    final cantripNames = cantrips
        .where((spell) => _sorcererCantripIds.contains(spell.id))
        .map((spell) => spell.name)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Магия чародея',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'На 1-м уровне чародей знает 2 заклинания 1-го круга и 4 заговора.',
            ),
            const SizedBox(height: 8),
            Text(
              'Известные заклинания: ${_sorcererStartingSpellIds.toSet().length}/2',
            ),
            if (knownNames.isNotEmpty) Text(knownNames.join(' · ')),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _chooseWizardSpells(
                  leveledSpells,
                  level: 1,
                  count: 2,
                  title: 'Выбери 2 известных заклинания чародея',
                  currentIds: _sorcererStartingSpellIds,
                  onSelected: (ids) {
                    _sorcererStartingSpellIds
                      ..clear()
                      ..addAll(ids);
                  },
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Выбрать заклинания'),
              ),
            ),
            const Divider(),
            Text('Заговоры: ${_sorcererCantripIds.toSet().length}/4'),
            if (cantripNames.isNotEmpty) Text(cantripNames.join(' · ')),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _chooseWizardSpells(
                  cantrips,
                  level: 0,
                  count: 4,
                  title: 'Выбери 4 заговора чародея',
                  currentIds: _sorcererCantripIds,
                  onSelected: (ids) {
                    _sorcererCantripIds
                      ..clear()
                      ..addAll(ids);
                  },
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Выбрать заговоры'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWizardStartingMagic(_CreationData data, DndClassData wizard) {
    final wizardSpells = data.spells
        .where((spell) => _isWizardSpell(spell, wizard))
        .toList();
    final startingSpells = wizardSpells
        .where((spell) => _wizardStartingSpellIds.contains(spell.id))
        .map((spell) => spell.name)
        .toList();
    final cantrips = wizardSpells
        .where((spell) => _wizardCantripIds.contains(spell.id))
        .map((spell) => spell.name)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Стартовая магия волшебника',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Книга содержит 6 заклинаний 1-го круга; заговоры выбираются отдельно. Выбранные заклинания не подготавливаются автоматически.',
            ),
            const SizedBox(height: 8),
            Text('Книга: ${_wizardStartingSpellIds.toSet().length}/6'),
            if (startingSpells.isNotEmpty) Text(startingSpells.join(' · ')),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _chooseWizardSpells(
                  wizardSpells,
                  level: 1,
                  count: 6,
                  title: 'Выбери 6 заклинаний в книгу',
                  currentIds: _wizardStartingSpellIds,
                  onSelected: (ids) {
                    _wizardStartingSpellIds
                      ..clear()
                      ..addAll(ids);
                  },
                ),
                icon: const Icon(Icons.menu_book),
                label: const Text('Выбрать заклинания книги'),
              ),
            ),
            const Divider(),
            Text('Заговоры: ${_wizardCantripIds.toSet().length}/3'),
            if (cantrips.isNotEmpty) Text(cantrips.join(' · ')),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _chooseWizardSpells(
                  wizardSpells,
                  level: 0,
                  count: 3,
                  title: 'Выбери 3 заговора волшебника',
                  currentIds: _wizardCantripIds,
                  onSelected: (ids) {
                    _wizardCantripIds
                      ..clear()
                      ..addAll(ids);
                  },
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Выбрать заговоры'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarlockStartingMagic(
    _CreationData data,
    DndClassData warlock,
    String patronId,
  ) {
    final availableSpells = data.spells
        .where(
          (spell) =>
              spell.level == 1 && _isWarlockSpell(spell, warlock, patronId),
        )
        .toList();
    final cantrips = data.spells.where((spell) {
      return spell.level == 0 &&
          spell.classes.any((name) {
            final normalized = name.trim().toLowerCase();
            return normalized == warlock.id ||
                normalized == warlock.name.trim().toLowerCase() ||
                normalized == warlock.englishName.trim().toLowerCase();
          });
    }).toList();
    final knownNames = availableSpells
        .where((spell) => _warlockStartingSpellIds.contains(spell.id))
        .map((spell) => spell.name)
        .toList();
    final cantripNames = cantrips
        .where((spell) => _warlockCantripIds.contains(spell.id))
        .map((spell) => spell.name)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Магия колдуна',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Выбери два известных заклинания 1-го круга и два заговора. Заклинания покровителя добавлены к доступным для выбора, но не изучаются автоматически.',
            ),
            const SizedBox(height: 8),
            Text(
              'Известные заклинания: ${_warlockStartingSpellIds.toSet().length}/2',
            ),
            if (knownNames.isNotEmpty) Text(knownNames.join(' · ')),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final selected = await showDialog<List<String>>(
                    context: context,
                    builder: (context) => SpellSelectionDialog(
                      spells: availableSpells,
                      selectionCount: 2,
                      title: 'Выбери 2 известных заклинания колдуна',
                      initialSelectedIds: _warlockStartingSpellIds,
                    ),
                  );
                  if (selected == null || !mounted) return;
                  setState(() {
                    _warlockStartingSpellIds
                      ..clear()
                      ..addAll(selected);
                  });
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Выбрать заклинания'),
              ),
            ),
            const Divider(),
            Text('Заговоры: ${_warlockCantripIds.toSet().length}/2'),
            if (cantripNames.isNotEmpty) Text(cantripNames.join(' · ')),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final selected = await showDialog<List<String>>(
                    context: context,
                    builder: (context) => SpellSelectionDialog(
                      spells: cantrips,
                      selectionCount: 2,
                      title: 'Выбери 2 заговора колдуна',
                      initialSelectedIds: _warlockCantripIds,
                    ),
                  );
                  if (selected == null || !mounted) return;
                  setState(() {
                    _warlockCantripIds
                      ..clear()
                      ..addAll(selected);
                  });
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Выбрать заговоры'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundStep(_CreationData data) {
    final selectedBackground = _backgroundId == null
        ? null
        : data.backgrounds.firstWhere((item) => item.id == _backgroundId);

    final availableSkills = _availableClassSkills(data);
    final requiredSkills = _classSkillChoiceCount(data);

    final backgroundChoices = _backgroundSkillChoices(selectedBackground);

    final automaticBackgroundSkills =
        selectedBackground?.skillProficiencies
            .where((skill) => !skill.startsWith('Один навык на выбор:'))
            .toList() ??
        [];

    return _stepContent(
      title: 'Шаг 4. Предыстория и навыки',
      description: 'Выбери предысторию и навыки, которыми владеет персонаж.',
      children: [
        DropdownButtonFormField<String?>(
          initialValue: _backgroundId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Предыстория',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Не выбрана'),
            ),
            ...data.backgrounds.map((item) {
              return DropdownMenuItem<String?>(
                value: item.id,
                child: Text(item.name),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _backgroundId = value;
              _backgroundChosenSkill = null;

              final allowed = _availableClassSkills(data);
              _classSkillProficiencies.removeWhere(
                (skill) => !allowed.contains(skill),
              );
            });
          },
        ),

        if (selectedBackground != null) ...[
          const SizedBox(height: 12),
          _DescriptionCard(text: selectedBackground.description),
        ],

        const Divider(height: 32),

        const Text(
          'Навыки от предыстории',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        if (selectedBackground == null ||
            selectedBackground.skillProficiencies.isEmpty)
          const Text('Нет навыков от предыстории.')
        else ...[
          ...automaticBackgroundSkills.map(
            (skill) => ListTile(
              dense: true,
              leading: const Icon(Icons.check_circle),
              title: Text(skill),
              subtitle: const Text('Добавляется автоматически'),
            ),
          ),

          if (backgroundChoices.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Выбери один навык:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            ...backgroundChoices.map(
              (skill) => RadioGroup<String>(
                groupValue: _backgroundChosenSkill,
                onChanged: (value) {
                  setState(() {
                    _backgroundChosenSkill = value;

                    final allowed = _availableClassSkills(data);
                    _classSkillProficiencies.removeWhere(
                      (item) => !allowed.contains(item),
                    );
                  });
                },
                child: Column(
                  children: backgroundChoices
                      .map(
                        (skill) => RadioListTile<String>(
                          value: skill,
                          title: Text(skill),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ],

        const Divider(height: 32),

        const Text(
          'Навыки от класса',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        Text('Выбери $requiredSkills навыка из списка своего класса.'),

        const SizedBox(height: 8),

        if (availableSkills.isEmpty)
          const Text('Для этого класса список навыков не найден.')
        else
          ...availableSkills.map((skill) {
            final selected = _classSkillProficiencies.contains(skill);

            return CheckboxListTile(
              value: selected,
              title: Text(skill),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    if (_classSkillProficiencies.length < requiredSkills) {
                      _classSkillProficiencies.add(skill);
                    }
                  } else {
                    _classSkillProficiencies.remove(skill);
                  }
                });
              },
            );
          }),

        const SizedBox(height: 8),

        Text(
          'Выбрано: ${_classSkillProficiencies.length} из $requiredSkills',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        if (_humanVariant == 'variant-human' &&
            _raceId == 'human' &&
            _humanSkill != null) ...[
          const Divider(height: 32),
          const Text(
            'Навык от альтернативного человека',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.check_circle),
            title: Text(_humanSkill!),
            subtitle: const Text('Добавляется автоматически'),
          ),
        ],
      ],
    );
  }

  Widget _buildAbilityStep() {
    return _stepContent(
      title: 'Шаг 5. Характеристики',
      description: 'Выбери способ определения характеристик. В режиме бросков каждая характеристика бросается отдельно и только один раз.',
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'roll',
              label: Text('Броски 4к6'),
              icon: Icon(Icons.casino_outlined),
            ),
            ButtonSegment(
              value: 'buy',
              label: Text('Покупка очков'),
              icon: Icon(Icons.shopping_cart_outlined),
            ),
          ],
          selected: {_abilityMode},
          onSelectionChanged: (selection) {
            setState(() {
              _abilityMode = selection.first;
              _abilityScores.updateAll((key, value) => 8);
              _rolledAbilities.clear();
            });
          },
        ),
        const SizedBox(height: 16),
        if (_abilityMode == 'buy') ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Осталось очков'),
                  Text(
                    '$_remainingPoints / 27',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Начальное значение — 8. До 15 используется стандартная стоимость D&D 5e. Каждое повышение выше 15 стоит 2 очка.',
          ),
        ] else ...[
          const Text(
            'Для каждой характеристики нажми свою кнопку. Бросок: 4к6, наименьший результат отбрасывается. Повторный бросок невозможен.',
          ),
        ],
        const SizedBox(height: 16),
        ..._abilityShortNames.entries.map((entry) {
          final ability = entry.key;
          final score = _abilityScores[ability] ?? 8;
          final rolled = _rolledAbilities.contains(ability);

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Модификатор: ${_modifier(score) >= 0 ? '+' : ''}${_modifier(score)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (_abilityMode == 'roll') ...[
                    Text(
                      '$score',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonal(
                      onPressed: rolled ? null : () => _rollAbility(ability),
                      child: Text(rolled ? 'Готово' : 'Бросить'),
                    ),
                  ] else ...[
                    IconButton(
                      onPressed: score > 8
                          ? () => _changeAbility(ability, -1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '$score',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: _remainingPoints > 0
                          ? () => _changeAbility(ability, 1)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        if (_abilityMode == 'roll') ...[
          const SizedBox(height: 8),
          Text(
            'Выполнено бросков: ${_rolledAbilities.length} из 6',
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryStep(_CreationData data) {
    final race = data.races.firstWhere((item) => item.id == _savedRaceId);

    final characterClass = data.classes.firstWhere(
      (item) => item.id == _savedClassId,
    );

    final subrace = _savedSubraceId == null
        ? null
        : race.subraces.firstWhere((item) => item.id == _savedSubraceId);

    final subclass = _savedSubclassId == null
        ? null
        : characterClass.subclasses.firstWhere(
            (item) => item.id == _savedSubclassId,
          );

    final background = _savedBackgroundId == null
        ? null
        : data.backgrounds.firstWhere((item) => item.id == _savedBackgroundId);

    final automaticBackgroundSkills =
        background?.skillProficiencies
            .where((skill) => !skill.startsWith('Один навык на выбор:'))
            .toList() ??
        [];

    return _stepContent(
      title: 'Шаг 6. Проверка персонажа',
      description: 'Проверь выбранные параметры. Нажми «Создать персонажа», чтобы завершить создание.',
      children: [
        _summaryLine('Имя', _savedName),
        _summaryLine('Раса', race.name),
        if (subrace != null) _summaryLine('Подраса', subrace.name),
        if (_savedDraconicAncestry != null)
          _summaryLine('Драконье наследие', _savedDraconicAncestry!),
        if (race.id == 'human')
          _summaryLine(
            'Вариант человека',
            _savedHumanVariant == 'standard'
                ? 'Обычный человек'
                : 'Альтернативный человек',
          ),
        if (_savedHumanSkill != null)
          _summaryLine('Расовый навык', _savedHumanSkill!),
        if (_savedHumanFeatId != null)
          _summaryLine(
            'Расовая черта',
            data.feats.firstWhere((feat) => feat.id == _savedHumanFeatId).name,
          ),
        _summaryLine('Класс', characterClass.name),
        if (subclass != null) _summaryLine('Подкласс', subclass.name),
        if (_savedClassId == 'wizard') ...[
          _summaryLine(
            'Книга заклинаний',
            _savedWizardStartingSpellIds
                .map(
                  (id) =>
                      data.spells
                          .where((spell) => spell.id == id)
                          .firstOrNull
                          ?.name ??
                      id,
                )
                .join(' · '),
          ),
          _summaryLine(
            'Заговоры',
            _savedWizardCantripIds
                .map(
                  (id) =>
                      data.spells
                          .where((spell) => spell.id == id)
                          .firstOrNull
                          ?.name ??
                      id,
                )
                .join(' · '),
          ),
        ],
        _summaryLine('Предыстория', background?.name ?? 'Не выбрана'),

        const Divider(height: 28),

        Text(
          'Владение навыками',
          style: Theme.of(context).textTheme.titleMedium,
        ),

        const SizedBox(height: 8),

        if (_savedHumanSkill != null &&
            race.id == 'human' &&
            _savedHumanVariant == 'variant-human')
          _summaryLine('От расы', _savedHumanSkill!),

        ...automaticBackgroundSkills.map(
          (skill) => _summaryLine('От предыстории', skill),
        ),

        if (_savedBackgroundChosenSkill != null)
          _summaryLine('От предыстории', _savedBackgroundChosenSkill!),

        ..._savedClassSkillProficiencies.map(
          (skill) => _summaryLine('От класса', skill),
        ),

        const Divider(height: 28),

        Text('Характеристики', style: Theme.of(context).textTheme.titleMedium),

        const SizedBox(height: 8),

        ..._abilityShortNames.entries.map((entry) {
          final score = _effectiveAbilityScores(data)[entry.key] ?? 8;
          final modifier = _modifier(score);

          return _summaryLine(
            entry.value,
            '$score (${modifier >= 0 ? '+' : ''}$modifier)',
          );
        }),

        const SizedBox(height: 20),

        const _DescriptionCard(
          text:
              'Персонаж будет создан 1-го уровня. '
              'После создания его можно будет открыть в списке персонажей.',
        ),
      ],
    );
  }

  Widget _summaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _navigationButtons(_CreationData data) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            if (_step > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _back,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Назад'),
                ),
              ),
            if (_step > 0) const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  if (_step == 5) {
                    _create(data);
                  } else {
                    _next(data);
                  }
                },
                icon: Icon(_step == 5 ? Icons.check : Icons.arrow_forward),
                label: Text(_step == 5 ? 'Создать персонажа' : 'Далее'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreationData {
  final List<RaceData> races;
  final List<DndClassData> classes;
  final List<BackgroundData> backgrounds;
  final List<FeatData> feats;
  final List<SpellData> spells;

  const _CreationData({
    required this.races,
    required this.classes,
    required this.backgrounds,
    required this.feats,
    required this.spells,
  });
}

class _DescriptionCard extends StatelessWidget {
  final String text;

  const _DescriptionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}
