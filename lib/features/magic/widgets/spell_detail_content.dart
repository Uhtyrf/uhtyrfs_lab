import 'package:flutter/material.dart';

import '../../../models/spell_data.dart';

// СОДЕРЖИМОЕ КАРТОЧКИ ЗАКЛИНАНИЯ

class SpellDetailContent extends StatelessWidget {
  final SpellData spell;

  const SpellDetailContent({super.key, required this.spell});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            spell.englishName,
            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),

          const Divider(height: 28),

          Text('Уровень: ${spell.level == 0 ? 'Заговор' : spell.level}'),
          Text('Школа: ${spell.school}'),
          Text('Время накладывания: ${spell.castingTime}'),
          Text('Дистанция: ${spell.range}'),
          Text('Компоненты: ${spell.components.join(', ')}'),

          if (spell.material.isNotEmpty)
            Text('Материальный компонент: ${spell.material}'),

          Text('Длительность: ${spell.duration}'),
          Text('Концентрация: ${spell.concentration ? 'Да' : 'Нет'}'),
          Text('Ритуал: ${spell.ritual ? 'Да' : 'Нет'}'),
          Text('Классы: ${spell.classes.join(', ')}'),

          const SizedBox(height: 20),

          const Text(
            'Описание',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            spell.description,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),

          if (spell.higherLevels.isNotEmpty) ...[
            const SizedBox(height: 20),

            const Text(
              'На более высоких уровнях',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              spell.higherLevels,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],

          const SizedBox(height: 20),

          Text('Источники: ${spell.sources.join(', ')}'),
        ],
      ),
    );
  }
}
