import 'package:flutter/material.dart';

import '../../../models/class_data.dart';
import '../../magic/widgets/class_spells_widget.dart';

class ClassDetailScreen extends StatefulWidget {
  final DndClassData classData;

  const ClassDetailScreen({super.key, required this.classData});
  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  late final DndClassData classData = widget.classData;

  final Map<String, GlobalKey> _subclassKeys = {};
  void _scrollToActiveSubclass() {
    final context = _activeSubclassKey?.currentContext;

    if (context == null) return;

    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0,
    );
  }

  GlobalKey? _activeSubclassKey;
  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spellcasting = classData.spellcasting;

    return Scaffold(
      appBar: AppBar(title: Text(classData.name), centerTitle: true),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        children: [
          Text(
            classData.name,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          Text(
            classData.englishName,
            style: const TextStyle(fontSize: 18, color: Colors.deepPurple),
          ),
          const Divider(height: 30),

          sectionTitle('Основные характеристики'),
          infoRow('Кость хитов', 'D${classData.hitDie}'),
          infoRow(
            'Главные характеристики',
            classData.primaryAbilities.join(', '),
          ),
          infoRow('Спасброски', classData.savingThrows.join(', ')),
          infoRow('Источник', classData.source),

          if (classData.startingEquipment.isNotEmpty) ...[
            sectionTitle('Стартовое снаряжение'),
            ...classData.startingEquipment.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('• $item'),
              ),
            ),
          ],

          if (spellcasting != null) ...[
            sectionTitle('Использование заклинаний'),
            infoRow(
              'Тип',
              spellcasting['type'] == 'prepared'
                  ? 'Подготовка заклинаний'
                  : 'Известные заклинания',
            ),
            infoRow('Характеристика', '${spellcasting['ability']}'),
            if (spellcasting['focus'] != null)
              infoRow('Фокус', '${spellcasting['focus']}'),
            if (spellcasting['preparedFormula'] != null)
              infoRow('Подготовка', '${spellcasting['preparedFormula']}'),
          ],
          ClassSpellsWidget(className: classData.name),
          if (classData.subclasses.isNotEmpty) ...[
            sectionTitle('Подклассы'),
            ...classData.subclasses.map((subclass) {
              final subclassKey = _subclassKeys.putIfAbsent(
                subclass.id,
                () => GlobalKey(),
              );

              return Card(
                child: ExpansionTile(
                  key: subclassKey,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      if (expanded) {
                        _activeSubclassKey = subclassKey;
                      } else if (identical(_activeSubclassKey, subclassKey)) {
                        _activeSubclassKey = null;
                      }
                    });
                  },
                  title: Text(
                    subclass.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Уровни особенностей: '
                    '${subclass.featureLevels.join(', ')}',
                  ),

                  children: [
                    ClassSpellsWidget(
                      key: ValueKey(subclass.id),
                      className: classData.name,
                      subclassId: subclass.id,
                      spellcasting: subclass.spellcasting,
                      alwaysPreparedSpells: subclass.alwaysPreparedSpells,
                    ),
                    if (subclass.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(subclass.description),
                      ),

                    // Объединяем особенности класса и подкласса.
                    ...(() {
                      final allFeatures = [
                        ...classData.features.map(
                          (feature) => {
                            'level': feature.level,
                            'name': feature.name,
                            'description': feature.description,
                          },
                        ),
                        ...subclass.features.map(
                          (feature) => {
                            'level': feature.level,
                            'name': feature.name,
                            'description': feature.description,
                          },
                        ),
                      ];

                      allFeatures.sort(
                        (a, b) =>
                            (a['level'] as int).compareTo(b['level'] as int),
                      );

                      return [
                        const Divider(),
                        const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text(
                            'Прогрессия класса и подкласса',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...allFeatures.map(
                          (feature) => ListTile(
                            title: Text(feature['name'] as String),
                            subtitle: Text(feature['description'] as String),
                            leading: CircleAvatar(
                              child: Text('${feature['level']}'),
                            ),
                          ),
                        ),
                      ];
                    })(),

                    // Специальная таблица дикой магии остаётся отдельно.
                    if (subclass.wildSurge.isNotEmpty) ...[
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.all(14),
                        child: Text(
                          'Таблица всплеска дикой магии (к8)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...subclass.wildSurge.map(
                        (result) => ListTile(
                          leading: CircleAvatar(child: Text('${result.roll}')),
                          title: Text('Результат ${result.roll}'),
                          subtitle: Text(result.description),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),

      floatingActionButton: _activeSubclassKey == null
          ? null
          : FloatingActionButton(
              onPressed: _scrollToActiveSubclass,
              tooltip: 'К началу подкласса',
              child: const Icon(Icons.keyboard_arrow_up),
            ),
    );
  }
}
