import 'package:flutter/material.dart';

import '../../../data/loaders/spell_loader.dart';
import '../../../models/spell_data.dart';
import '../widgets/spell_detail_content.dart';

// КАТАЛОГ ЗАКЛИНАНИЙ
class SpellCatalogScreen extends StatefulWidget {
  final String title;
  final int? level;

  const SpellCatalogScreen({super.key, required this.title, this.level});

  @override
  State<SpellCatalogScreen> createState() => _SpellCatalogScreenState();
}

class _SpellCatalogScreenState extends State<SpellCatalogScreen> {
  late Future<List<SpellData>> spellsFuture;

  String searchQuery = '';
  String selectedSchool = 'Все школы';
  String selectedClass = 'Все классы';

  @override
  void initState() {
    super.initState();
    spellsFuture = loadSpells();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<SpellData>>(
        future: spellsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
          }

          final allSpells = snapshot.data ?? [];

          // Список школ магии
          final schools =
              allSpells
                  .where((spell) {
                    return widget.level == 0
                        ? spell.level == 0
                        : spell.level > 0;
                  })
                  .map((spell) => spell.school)
                  .where((school) => school.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();

          // Список классов персонажей
          final classes =
              allSpells
                  .where((spell) {
                    return widget.level == 0
                        ? spell.level == 0
                        : spell.level > 0;
                  })
                  .expand((spell) => spell.classes)
                  .where((className) => className.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();

          // Фильтрация заклинаний
          final spells = allSpells.where((spell) {
            final matchesLevel = widget.level == 0
                ? spell.level == 0
                : spell.level > 0;

            final query = searchQuery.trim().toLowerCase();

            final matchesSearch =
                query.isEmpty ||
                spell.name.toLowerCase().contains(query) ||
                spell.englishName.toLowerCase().contains(query);

            final matchesSchool =
                selectedSchool == 'Все школы' || spell.school == selectedSchool;

            final matchesClass =
                selectedClass == 'Все классы' ||
                spell.classes.contains(selectedClass);

            return matchesLevel &&
                matchesSearch &&
                matchesSchool &&
                matchesClass;
          }).toList();

          return Column(
            children: [
              // ПОИСК
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

              // ФИЛЬТР ШКОЛ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  initialValue: selectedSchool,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Школа магии',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'Все школы',
                      child: Text('Все школы'),
                    ),
                    ...schools.map(
                      (school) =>
                          DropdownMenuItem(value: school, child: Text(school)),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedSchool = value;
                      });
                    }
                  },
                ),
              ),

              const SizedBox(height: 10),

              // ФИЛЬТР КЛАССОВ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  initialValue: selectedClass,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Класс персонажа',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'Все классы',
                      child: Text('Все классы'),
                    ),
                    ...classes.map(
                      (className) => DropdownMenuItem(
                        value: className,
                        child: Text(className),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedClass = value;
                      });
                    }
                  },
                ),
              ),

              const SizedBox(height: 10),

              // СПИСОК ЗАКЛИНАНИЙ
              Expanded(
                child: spells.isEmpty
                    ? Center(
                        child: Text(
                          searchQuery.isEmpty
                              ? 'В этом разделе пока нет записей'
                              : 'Ничего не найдено',
                        ),
                      )
                    : ListView.builder(
                        itemCount: spells.length,
                        itemBuilder: (context, index) {
                          final spell = spells[index];

                          return Card(
                            child: ExpansionTile(
                              title: Row(
                                children: [
                                  Expanded(child: Text(spell.name)),
                                  IconButton(
                                    tooltip: 'Информация о заклинании',
                                    icon: const Icon(Icons.info_outline),
                                    onPressed: () {
                                      showModalBottomSheet<void>(
                                        context: context,
                                        isScrollControlled: true,
                                        useSafeArea: true,
                                        builder: (context) {
                                          return DraggableScrollableSheet(
                                            expand: false,
                                            initialChildSize: 0.85,
                                            minChildSize: 0.5,
                                            maxChildSize: 0.95,
                                            builder: (context, scrollController) {
                                              return SingleChildScrollView(
                                                controller: scrollController,
                                                child: SpellDetailContent(
                                                  spell: spell,
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '${spell.level == 0 ? 'Заговор' : '${spell.level} уровень'} · ${spell.school}',
                              ),
                              children: [SpellDetailContent(spell: spell)],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
