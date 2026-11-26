import 'package:flutter/material.dart';

import '../data/character_repository.dart';
import '../models/character.dart';

/// Боевой экран персонажа. Все значения хранятся в общей модели Character.
class CombatScreen extends StatefulWidget {
  final Character character;

  const CombatScreen({super.key, required this.character});

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> {
  final CharacterRepository _repository = CharacterRepository();

  Character get character => widget.character;

  static const Map<String, String> _conditionNames = {
    'blinded': 'Ослеплён',
    'charmed': 'Очарован',
    'deafened': 'Оглох',
    'frightened': 'Испуган',
    'grappled': 'Схвачен',
    'incapacitated': 'Недееспособен',
    'invisible': 'Невидим',
    'paralyzed': 'Парализован',
    'petrified': 'Окаменел',
    'poisoned': 'Отравлен',
    'prone': 'Сбит с ног',
    'restrained': 'Опутан',
    'stunned': 'Ошеломлён',
    'unconscious': 'Без сознания',
  };

  Future<void> _save() async {
    character.updatedAt = DateTime.now();
    await _repository.saveCharacter(character);
    if (!mounted) return;
    setState(() {});
  }

  Future<int?> _askForAmount({
    required String title,
    required String label,
    int minimum = 1,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
          onSubmitted: (_) {
            final value = int.tryParse(controller.text.trim());
            if (value != null && value >= minimum) {
              Navigator.of(dialogContext).pop(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value != null && value >= minimum) {
                Navigator.of(dialogContext).pop(value);
              }
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _applyDamage() async {
    final amount = await _askForAmount(
      title: 'Получить урон',
      label: 'Количество урона',
    );
    if (amount == null || !mounted) return;

    var remainingDamage = amount;
    final absorbed = remainingDamage < character.temporaryHitPoints
        ? remainingDamage
        : character.temporaryHitPoints;
    character.temporaryHitPoints -= absorbed;
    remainingDamage -= absorbed;

    if (remainingDamage > 0) {
      character.currentHitPoints =
          (character.currentHitPoints - remainingDamage)
              .clamp(0, character.maxHitPoints)
              .toInt();
    }
    await _save();
  }

  Future<void> _heal() async {
    final amount = await _askForAmount(
      title: 'Восстановить здоровье',
      label: 'Количество HP',
    );
    if (amount == null || !mounted) return;

    final oldHp = character.currentHitPoints;
    character.currentHitPoints =
        (character.currentHitPoints + amount)
            .clamp(0, character.maxHitPoints)
            .toInt();

    // По правилам 5e восстановление хотя бы 1 HP выводит из состояния при 0 HP
    // и сбрасывает накопленные отметки спасбросков от смерти.
    if (oldHp == 0 && character.currentHitPoints > 0) {
      character.deathSaveSuccesses = 0;
      character.deathSaveFailures = 0;
    }
    await _save();
  }

  Future<void> _setTemporaryHitPoints() async {
    final amount = await _askForAmount(
      title: 'Временные HP',
      label: 'Новое значение (0 — убрать)',
      minimum: 0,
    );
    if (amount == null || !mounted) return;

    // Временные HP не складываются: новое значение заменяет старое,
    // только если оно больше текущего.
    if (amount > character.temporaryHitPoints) {
      character.temporaryHitPoints = amount;
      await _save();
    } else if (amount == 0 && character.temporaryHitPoints > 0) {
      character.temporaryHitPoints = 0;
      await _save();
    }
  }

  Future<void> _changeDeathSave({required bool success}) async {
    if (character.currentHitPoints > 0) return;
    if (character.deathSaveSuccesses >= 3 || character.deathSaveFailures >= 3) {
      return;
    }

    if (success) {
      character.deathSaveSuccesses =
          (character.deathSaveSuccesses + 1).clamp(0, 3).toInt();
    } else {
      character.deathSaveFailures =
          (character.deathSaveFailures + 1).clamp(0, 3).toInt();
    }
    await _save();
  }

  Future<void> _resetDeathSaves() async {
    character.deathSaveSuccesses = 0;
    character.deathSaveFailures = 0;
    await _save();
  }

  Future<void> _changeExhaustion(int change) async {
    final next = (character.exhaustionLevel + change).clamp(0, 6).toInt();
    if (next == character.exhaustionLevel) return;
    character.exhaustionLevel = next;
    await _save();
  }

  Future<void> _toggleCondition(String id, bool selected) async {
    if (selected) {
      if (!character.conditions.contains(id)) character.conditions.add(id);
    } else {
      character.conditions.remove(id);
    }
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentHp = character.currentHitPoints;
    final maxHp = character.maxHitPoints;
    final availableHitDice =
        (character.hitDiceTotal - character.hitDiceUsed)
            .clamp(0, character.hitDiceTotal);
    final deathSaveComplete =
        character.deathSaveSuccesses >= 3 || character.deathSaveFailures >= 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Боевой экран'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(character.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      '${character.race} · ${character.characterClass} · '
                      '${character.subclassName.isEmpty ? 'Уровень ${character.level}' : '${character.subclassName}, ур. ${character.level}'}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            _section(
              context,
              title: 'Здоровье',
              icon: Icons.favorite_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: _valueTile(context, label: 'Текущие HP', value: '$currentHp')),
                      Expanded(child: _valueTile(context, label: 'Максимум HP', value: '$maxHp')),
                      Expanded(child: _valueTile(context, label: 'Временные HP', value: '${character.temporaryHitPoints}')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: maxHp > 0 ? (currentHp / maxHp).clamp(0.0, 1.0) : 0,
                      minHeight: 9,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _applyDamage,
                          icon: const Icon(Icons.bolt),
                          label: const Text('Получить урон'),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _heal,
                          icon: const Icon(Icons.healing),
                          label: const Text('Лечение'),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _setTemporaryHitPoints,
                      icon: const Icon(Icons.shield_outlined),
                      label: const Text('Установить временные HP'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _section(
              context,
              title: 'Кости хитов',
              icon: Icons.casino_outlined,
              child: _valueTile(context, label: 'Доступно', value: '$availableHitDice / ${character.hitDiceTotal}'),
            ),
            const SizedBox(height: 8),
            _section(
              context,
              title: 'Спасброски от смерти',
              icon: Icons.health_and_safety_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    currentHp > 0
                        ? 'Спасброски понадобятся, когда HP опустятся до 0.'
                        : character.deathSaveFailures >= 3
                            ? 'Три провала — персонаж погиб.'
                            : character.deathSaveSuccesses >= 3
                                ? 'Три успеха — персонаж стабилизирован.'
                                : 'Отмечай результат каждого спасброска от смерти.',
                  ),
                  const SizedBox(height: 10),
                  _deathSaveTrack('Успехи', character.deathSaveSuccesses, theme.colorScheme.primary),
                  const SizedBox(height: 8),
                  _deathSaveTrack('Провалы', character.deathSaveFailures, theme.colorScheme.error),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: currentHp == 0 && !deathSaveComplete
                              ? () => _changeDeathSave(success: true)
                              : null,
                          child: const Text('+ Успех'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: currentHp == 0 && !deathSaveComplete
                              ? () => _changeDeathSave(success: false)
                              : null,
                          child: const Text('+ Провал'),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Сбросить отметки',
                        onPressed: _resetDeathSaves,
                        icon: const Icon(Icons.restart_alt),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _section(
              context,
              title: 'Состояния',
              icon: Icons.warning_amber_outlined,
              child: Wrap(
                spacing: 6,
                runSpacing: 2,
                children: _conditionNames.entries.map((entry) {
                  final selected = character.conditions.contains(entry.key);
                  return FilterChip(
                    label: Text(entry.value),
                    selected: selected,
                    onSelected: (value) => _toggleCondition(entry.key, value),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            _section(
              context,
              title: 'Истощение',
              icon: Icons.battery_alert_outlined,
              child: Row(
                children: [
                  IconButton(
                    onPressed: character.exhaustionLevel > 0 ? () => _changeExhaustion(-1) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '${character.exhaustionLevel} / 6',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: character.exhaustionLevel < 6 ? () => _changeExhaustion(1) : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _section(
              context,
              title: 'Боевые показатели',
              icon: Icons.shield_outlined,
              child: const Text('Здесь появятся КД, инициатива, скорость и атаки.'),
            ),
            const SizedBox(height: 8),
            _section(
              context,
              title: 'Ресурсы класса',
              icon: Icons.bolt_outlined,
              child: const Text('Здесь будут отображаться ресурсы с учётом класса, подкласса и уровня.'),
            ),
            const SizedBox(height: 8),
            _section(
              context,
              title: 'Отдых',
              icon: Icons.bedtime_outlined,
              child: const Text('Короткий и продолжительный отдых с восстановлением ресурсов подключим отдельным этапом.'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deathSaveTrack(String label, int count, Color color) {
    return Row(
      children: [
        SizedBox(width: 72, child: Text(label)),
        for (var i = 0; i < 3; i++) ...[
          Icon(
            count > i ? Icons.circle : Icons.circle_outlined,
            color: count > i ? color : null,
            size: 22,
          ),
          if (i < 2) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 19, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _valueTile(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
