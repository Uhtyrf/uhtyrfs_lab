import 'package:flutter/material.dart';

import '../../../data/loaders/background_loader.dart';
import '../../../models/background_data.dart';
import 'background_detail_screen.dart';

class BackgroundCatalogScreen extends StatefulWidget {
  const BackgroundCatalogScreen({super.key});

  @override
  State<BackgroundCatalogScreen> createState() =>
      _BackgroundCatalogScreenState();
}

class _BackgroundCatalogScreenState extends State<BackgroundCatalogScreen> {
  final TextEditingController searchController = TextEditingController();

  late Future<List<BackgroundData>> backgroundsFuture;

  @override
  void initState() {
    super.initState();
    backgroundsFuture = loadBackgrounds();
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
      appBar: AppBar(title: const Text('Предыстории'), centerTitle: true),
      body: FutureBuilder<List<BackgroundData>>(
        future: backgroundsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Ошибка загрузки предысторий:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final backgrounds = snapshot.data ?? [];

          final filteredBackgrounds = backgrounds.where((background) {
            return background.name.toLowerCase().contains(query) ||
                background.englishName.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Поиск предыстории',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
              ),
              Expanded(
                child: filteredBackgrounds.isEmpty
                    ? const Center(child: Text('Предыстории не найдены'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredBackgrounds.length,
                        itemBuilder: (context, index) {
                          final background = filteredBackgrounds[index];

                          return Card(
                            child: ListTile(
                              title: Text(
                                background.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(background.source),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BackgroundDetailScreen(
                                          background: background,
                                        ),
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
