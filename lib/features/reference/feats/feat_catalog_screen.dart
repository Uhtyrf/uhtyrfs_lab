import 'package:flutter/material.dart';

import '../../../data/loaders/feat_loader.dart';
import '../../../models/feat_data.dart';
import 'feat_detail_screen.dart';

class FeatCatalogScreen extends StatefulWidget {
  const FeatCatalogScreen({super.key});

  @override
  State<FeatCatalogScreen> createState() => _FeatCatalogScreenState();
}

class _FeatCatalogScreenState extends State<FeatCatalogScreen> {
  final TextEditingController searchController = TextEditingController();

  late Future<List<FeatData>> featsFuture;

  @override
  void initState() {
    super.initState();
    featsFuture = loadFeats();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.toLowerCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Черты'), centerTitle: true),
      body: FutureBuilder<List<FeatData>>(
        future: featsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Ошибка загрузки черт:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final feats = snapshot.data ?? [];

          final filteredFeats = feats.where((feat) {
            return feat.name.toLowerCase().contains(query) ||
                feat.englishName.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Поиск черты',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
              ),
              Expanded(
                child: filteredFeats.isEmpty
                    ? const Center(child: Text('Черты не найдены'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredFeats.length,
                        itemBuilder: (context, index) {
                          final feat = filteredFeats[index];

                          return Card(
                            child: ListTile(
                              title: Text(
                                feat.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(feat.source),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FeatDetailScreen(feat: feat),
                                  ),
                                );
                              },
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
