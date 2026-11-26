import 'package:flutter/material.dart';

import '../../../models/background_data.dart';

class BackgroundDetailScreen extends StatelessWidget {
  final BackgroundData background;

  const BackgroundDetailScreen({super.key, required this.background});

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

  Widget bulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(
                    child: Text(item, style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(background.name), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            background.name,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            background.englishName,
            style: const TextStyle(fontSize: 18, color: Colors.deepPurple),
          ),

          const Divider(height: 30),

          sectionTitle('Описание'),
          Text(background.description, style: const TextStyle(fontSize: 16)),

          sectionTitle('Владение навыками'),
          bulletList(background.skillProficiencies),

          if (background.toolProficiencies.isNotEmpty) ...[
            sectionTitle('Владение инструментами'),
            bulletList(background.toolProficiencies),
          ],

          sectionTitle('Языки'),
          Text(background.languages, style: const TextStyle(fontSize: 16)),

          sectionTitle('Снаряжение'),
          bulletList(background.equipment),

          sectionTitle('Особенность: ${background.featureName}'),
          Text(
            background.featureDescription,
            style: const TextStyle(fontSize: 16),
          ),

          sectionTitle('Источник'),
          Text(background.source),
        ],
      ),
    );
  }
}
