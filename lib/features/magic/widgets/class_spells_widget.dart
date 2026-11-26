import 'package:flutter/material.dart';

import '../../../data/loaders/spell_loader.dart';
import '../../../models/spell_data.dart';
import 'spell_detail_content.dart';

// КАРТОЧКА ЗАКЛИНАНИЯ

class ClassSpellsWidget extends StatefulWidget {
  final String className;
  final String? subclassId;
  final Map<String, dynamic>? spellcasting;
  final List<String> alwaysPreparedSpells;

  const ClassSpellsWidget({
    super.key,
    required this.className,
    this.subclassId,
    this.spellcasting,
    this.alwaysPreparedSpells = const [],
  });

  @override
  State<ClassSpellsWidget> createState() => _ClassSpellsWidgetState();
}

class _ClassSpellsWidgetState extends State<ClassSpellsWidget> {
  late Future<List<SpellData>> spellsFuture;

  String searchQuery = '';
  int selectedLevel = -1;

  @override
  void initState() {
    super.initState();
    spellsFuture = loadSpells();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SpellData>>(
      future: spellsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Ошибка загрузки заклинаний: ${snapshot.error}'),
          );
        }

        final allSpells = snapshot.data ?? [];

        // Для класса проверяем поле classes.
        // Для подкласса проверяем его уникальный ID.

        final spellcasting = widget.spellcasting;
        final spellcastingClass = spellcasting?['class'] as String?;
        final maxSpellLevel = spellcasting?['maxSpellLevel'] as int?;

        final availableSpells = allSpells.where((spell) {
          // Обычные заклинания базового класса.
          final isClassSpell = spell.classes.contains(widget.className);

          // Заклинания, отдельно отмеченные для подкласса.
          final isSubclassSpell =
              widget.subclassId != null &&
              spell.subclasses.contains(widget.subclassId);

          // Заклинания, которые специализация всегда держит подготовленными.
          final isAlwaysPrepared = widget.alwaysPreparedSpells.contains(
            spell.id,
          );

          // Заклинания из списка другого класса,
          // указанного в настройках подкласса.
          final isSpellcastingSpell =
              spellcastingClass != null &&
              spell.classes.contains(spellcastingClass) &&
              (maxSpellLevel == null || spell.level <= maxSpellLevel);

          if (widget.subclassId != null) {
            return isSubclassSpell || isSpellcastingSpell || isAlwaysPrepared;
          }

          return isClassSpell;
        }).toList();
        if (availableSpells.isEmpty) {
          return const SizedBox.shrink();
        }

        final query = searchQuery.trim().toLowerCase();

        final filteredSpells = availableSpells.where((spell) {
          final matchesSearch =
              query.isEmpty ||
              spell.name.toLowerCase().contains(query) ||
              spell.englishName.toLowerCase().contains(query);

          final matchesLevel =
              selectedLevel == -1 || spell.level == selectedLevel;

          return matchesSearch && matchesLevel;
        }).toList();

        return Card(
          child: ExpansionTile(
            title: Text(
              widget.subclassId == null
                  ? 'Заклинания класса'
                  : 'Дополнительные заклинания',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Доступно заклинаний: ${availableSpells.length}'),
            children: [
              if (widget.spellcasting != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Список заклинаний: ${widget.spellcasting!['class'] ?? '—'}.\n'
                    'Основные школы: ${(widget.spellcasting!['schools'] as List? ?? []).join(', ')}.\n'
                    'Заклинания других школ доступны для особого выбора на уровнях: '
                    '${(widget.spellcasting!['anySchoolAtLevels'] as List? ?? []).join(', ')}.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Поиск заклинания...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<int>(
                  initialValue: selectedLevel,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Уровень заклинания',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: -1,
                      child: Text('Все уровни'),
                    ),
                    ...List.generate(10, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Text(index == 0 ? 'Заговоры' : '$index уровень'),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedLevel = value;
                      });
                    }
                  },
                ),
              ),

              const SizedBox(height: 10),

              if (filteredSpells.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Ничего не найдено'),
                )
              else
                ...filteredSpells.map((spell) {
                  final spellcastingClass =
                      widget.spellcasting?['class'] as String?;

                  final schools =
                      (widget.spellcasting?['schools'] as List?)
                          ?.cast<String>() ??
                      [];

                  final isSpecialChoice =
                      spell.level > 0 &&
                      spellcastingClass != null &&
                      spell.classes.contains(spellcastingClass) &&
                      schools.isNotEmpty &&
                      !schools.contains(spell.school);

                  return Card(
                    child: ExpansionTile(
                      title: Text(spell.name),
                      subtitle: Text(
                        '${spell.level == 0 ? 'Заговор' : '${spell.level} уровень'} · ${spell.school}'
                        '${isSpecialChoice ? ' · Особый выбор' : ''}'
                        '${widget.alwaysPreparedSpells.contains(spell.id) ? ' · Всегда подготовлено' : ''}',
                      ),
                      children: [SpellDetailContent(spell: spell)],
                    ),
                  );
                }),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
