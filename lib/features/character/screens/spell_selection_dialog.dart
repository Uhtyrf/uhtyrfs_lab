import 'package:flutter/material.dart';

import '../../../models/spell_data.dart';

class SpellSelectionDialog extends StatefulWidget {
  final List<SpellData> spells;
  final int selectionCount;
  final String title;
  final List<String> initialSelectedIds;

  const SpellSelectionDialog({
    super.key,
    required this.spells,
    required this.selectionCount,
    required this.title,
    this.initialSelectedIds = const [],
  });

  @override
  State<SpellSelectionDialog> createState() => _SpellSelectionDialogState();
}

class _SpellSelectionDialogState extends State<SpellSelectionDialog> {
  final _searchController = TextEditingController();
  final Set<String> _selectedIds = {};
  int? _selectedLevel;
  String? _selectedSchool;

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initialSelectedIds.take(widget.selectionCount));
  }

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
              _selectedSchool == null || spell.school == _selectedSchool;
          return matchesQuery && matchesLevel && matchesSchool;
        }).toList()..sort((a, b) {
          final level = a.level.compareTo(b.level);
          return level != 0 ? level : a.name.compareTo(b.name);
        });
    final levels = widget.spells.map((spell) => spell.level).toSet().toList()
      ..sort();
    final schools =
        widget.spells
            .map((spell) => spell.school)
            .where((school) => school.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight;
          final dialogHeight = maxHeight.isFinite
              ? (maxHeight < 560 ? maxHeight : 560.0)
              : 520.0;
          return SizedBox(
            width: double.maxFinite,
            height: dialogHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                      softWrap: true,
                    ),
                  ),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Поиск заклинания',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    isExpanded: true,
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
                      for (final level in levels)
                        DropdownMenuItem<int?>(
                          value: level,
                          child: Text(level == 0 ? 'Заговоры' : '$level круг'),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedLevel = value),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
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
                      for (final school in schools)
                        DropdownMenuItem<String?>(
                          value: school,
                          child: Text(school, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedSchool = value),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Выбрано: ${_selectedIds.length} из ${widget.selectionCount}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('Ничего не найдено'))
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final spell = filtered[index];
                              final isSelected = _selectedIds.contains(
                                spell.id,
                              );
                              final isDisabled =
                                  !isSelected &&
                                  _selectedIds.length >= widget.selectionCount;
                              final onToggle = isDisabled
                                  ? null
                                  : () => setState(() {
                                      if (isSelected) {
                                        _selectedIds.remove(spell.id);
                                      } else {
                                        _selectedIds.add(spell.id);
                                      }
                                    });
                              return InkWell(
                                onTap: onToggle,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: onToggle == null
                                            ? null
                                            : (_) => onToggle(),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              spell.name,
                                              softWrap: true,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${spell.level == 0 ? 'Заговор' : '${spell.level} круг'} · ${spell.school}',
                                              softWrap: true,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Отмена'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed:
                              _selectedIds.length == widget.selectionCount
                              ? () =>
                                    Navigator.of(context)
                                        .pop(_selectedIds.toList())
                              : null,
                          child: const Text('Подтвердить'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
