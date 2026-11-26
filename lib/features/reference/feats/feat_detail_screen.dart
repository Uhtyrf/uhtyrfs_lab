import 'package:flutter/material.dart';

import '../../../models/feat_data.dart';

class FeatDetailScreen extends StatelessWidget {
  final FeatData feat;

  const FeatDetailScreen({super.key, required this.feat});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(feat.name), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            feat.name,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            feat.englishName,
            style: const TextStyle(fontSize: 18, color: Colors.deepPurple),
          ),

          const Divider(height: 30),

          sectionTitle('Описание'),
          Text(feat.description, style: const TextStyle(fontSize: 16)),

          if (feat.prerequisite != null && feat.prerequisite!.isNotEmpty) ...[
            sectionTitle('Предварительные требования'),
            Text(feat.prerequisite!, style: const TextStyle(fontSize: 16)),
          ],

          if (feat.benefits.isNotEmpty) ...[
            sectionTitle('Преимущества'),
            ...feat.benefits.map(
              (benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(
                      child: Text(
                        benefit,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          sectionTitle('Источник'),
          Text(feat.source),
        ],
      ),
    );
  }
}
