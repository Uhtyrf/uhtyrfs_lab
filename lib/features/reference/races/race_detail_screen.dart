import 'package:flutter/material.dart';

import '../../../models/race_data.dart';

class RaceDetailScreen extends StatelessWidget {
  final RaceData race;

  const RaceDetailScreen({super.key, required this.race});

  String abilityName(String key) {
    const names = {
      'strength': 'Сила',
      'dexterity': 'Ловкость',
      'constitution': 'Телосложение',
      'intelligence': 'Интеллект',
      'wisdom': 'Мудрость',
      'charisma': 'Харизма',
    };

    return names[key] ?? key;
  }

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
            width: 115,
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
    return Scaffold(
      appBar: AppBar(title: Text(race.name), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            race.name,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            race.englishName,
            style: const TextStyle(fontSize: 18, color: Colors.deepPurple),
          ),

          const Divider(height: 30),

          sectionTitle('Описание'),
          Text(race.description, style: const TextStyle(fontSize: 16)),

          sectionTitle('Источник'),
          Text(race.source),

          if (race.size.isNotEmpty ||
              race.speed > 0 ||
              race.age.isNotEmpty ||
              race.alignment.isNotEmpty) ...[
            sectionTitle('Основные характеристики'),

            if (race.size.isNotEmpty) infoRow('Размер', race.size),

            if (race.speed > 0) infoRow('Скорость', '${race.speed} футов'),

            if (race.age.isNotEmpty) infoRow('Возраст', race.age),

            if (race.alignment.isNotEmpty)
              infoRow('Мировоззрение', race.alignment),
          ],

          if (race.abilityBonuses.isNotEmpty) ...[
            sectionTitle('Бонусы характеристик'),

            ...race.abilityBonuses.entries.map(
              (entry) => infoRow(abilityName(entry.key), '+${entry.value}'),
            ),
          ],

          if (race.languages.isNotEmpty) ...[
            sectionTitle('Языки'),
            Text(race.languages.join(', ')),
          ],

          if (race.traits.isNotEmpty) ...[
            sectionTitle('Расовые особенности'),

            ...race.traits.map(
              (trait) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trait.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        trait.description,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          if (race.subraces.isNotEmpty) ...[
            sectionTitle('Подрасы'),

            ...race.subraces.map(
              (subrace) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subrace.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subrace.description,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
