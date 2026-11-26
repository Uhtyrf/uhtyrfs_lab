import 'package:flutter/material.dart';

import '../../../models/spell_data.dart';
import '../data/character_repository.dart';
import '../models/character.dart';
import 'spell_selection_dialog.dart';

class WizardSpellbookScreen extends StatefulWidget {
  final Character character;
  final List<SpellData> allSpells;
  final List<SpellData> eligibleWizardSpells;

  const WizardSpellbookScreen({
    super.key,
    required this.character,
    required this.allSpells,
    required this.eligibleWizardSpells,
  });

  @override
  State<WizardSpellbookScreen> createState() => _WizardSpellbookScreenState();
}

class _WizardSpellbookScreenState extends State<WizardSpellbookScreen> {
  final _repository = CharacterRepository();
  final _searchController = TextEditingController();
  int? _selectedLevel;
  String? _selectedSchool;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Set<String> get _bookIds => {
    ...widget.character.spellbookSpellIds,
    // Older wizard saves stored book entries in knownSpellIds.
    ...widget.character.knownSpellIds,
  };

  List<SpellData> _bookSpells(List<SpellData> allSpells) {
    final bookIds = _bookIds;
    return allSpells
        .where((spell) => spell.level > 0 && bookIds.contains(spell.id))
        .toList()
      ..sort((a, b) {
        final level = a.level.compareTo(b.level);
        return level != 0 ? level : a.name.compareTo(b.name);
      });
  }

  Future<void> _addSpell() async {
    final currentIds = _bookIds;
    final available = widget.eligibleWizardSpells
        .where((spell) => spell.level > 0 && !currentIds.contains(spell.id))
        .toList();
    final selected = await showDialog<SpellData>(
      context: context,
      builder: (context) => SpellSelectionDialog(
        spells: available,
        selectionCount: 1,
        title: 'Добавить заклинание в книгу',
      ),
    );
    if (selected == null || !mounted) return;
    if (_bookIds.contains(selected.id)) return;

    widget.character.spellbookSpellIds.add(selected.id);
    await _repository.saveCharacter(widget.character);
    if (mounted) setState(() {});
  }

  Future<void> _removeSpell(SpellData spell) async {
    widget.character.spellbookSpellIds.removeWhere((id) => id == spell.id);
    widget.character.knownSpellIds.removeWhere((id) => id == spell.id);
    widget.character.preparedSpellIds.removeWhere((id) => id == spell.id);
    widget.character.spellMasterySpellIds.removeWhere((id) => id == spell.id);
    widget.character.signatureSpellIds.removeWhere((id) => id == spell.id);
    await _repository.saveCharacter(widget.character);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Книга заклинаний'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${_bookIds.length} заклинаний · заговоры хранятся отдельно',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Поиск в книге',
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
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      initialValue: _selectedLevel,
                      decoration: const InputDecoration(
                        labelText: 'Круг',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Все круги'),
                        ),
                        for (var level = 1; level <= 9; level++)
                          DropdownMenuItem<int?>(
                            value: level,
                            child: Text('$level круг'),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedLevel = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final schools = _bookSpells(
                          widget.allSpells,
                        ).map((spell) => spell.school).toSet().toList()..sort();
                        final selectedSchool = schools.contains(_selectedSchool)
                            ? _selectedSchool
                            : null;
                        return DropdownButtonFormField<String?>(
                          initialValue: selectedSchool,
                          decoration: const InputDecoration(
                            labelText: 'Школа',
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Все школы'),
                            ),
                            for (final school in schools)
                              DropdownMenuItem<String?>(
                                value: school,
                                child: Text(
                                  school,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedSchool = value),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final availableSchools = _bookSpells(widget.allSpells)
                        .map((spell) => spell.school)
                        .toSet();
                    final activeSchool =
                        availableSchools.contains(_selectedSchool)
                        ? _selectedSchool
                        : null;
                    final query = _searchController.text.trim().toLowerCase();
                    final bookSpells = _bookSpells(widget.allSpells).where((
                      spell,
                    ) {
                      final matchesQuery =
                          query.isEmpty ||
                          spell.name.toLowerCase().contains(query) ||
                          spell.englishName.toLowerCase().contains(query);
                      final matchesLevel =
                          _selectedLevel == null ||
                          spell.level == _selectedLevel;
                      final matchesSchool =
                          activeSchool == null || spell.school == activeSchool;
                      return matchesQuery && matchesLevel && matchesSchool;
                    }).toList();
                    final levels =
                        bookSpells.map((spell) => spell.level).toSet().toList()
                          ..sort();

                    if (bookSpells.isEmpty) {
                      return Center(
                        child: Text(
                          _bookIds.isEmpty
                              ? 'Книга пока пуста. Добавь заклинания кнопкой ниже.'
                              : 'По выбранным фильтрам ничего не найдено.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView(
                      children: [
                        for (final level in levels) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                            child: Text(
                              '$level круг',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          for (final spell in bookSpells.where(
                            (spell) => spell.level == level,
                          ))
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(spell.name),
                              subtitle: Text(
                                [
                                  spell.school,
                                  if (widget.character.preparedSpellIds
                                      .contains(spell.id))
                                    'Подготовлено',
                                  if (widget.character.spellMasterySpellIds
                                      .contains(spell.id))
                                    'Spell Mastery',
                                  if (widget.character.signatureSpellIds
                                      .contains(spell.id))
                                    'Signature Spell',
                                ].join(' · '),
                              ),
                              trailing: IconButton(
                                tooltip: 'Удалить из книги и снять подготовку',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeSpell(spell),
                              ),
                            ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSpell,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }
}
