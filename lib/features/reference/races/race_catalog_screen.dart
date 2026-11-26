import 'package:flutter/material.dart';

import '../../../data/loaders/race_loader.dart';
import '../../../models/race_data.dart';
import 'race_detail_screen.dart';

class RaceCatalogScreen extends StatefulWidget {
  const RaceCatalogScreen({super.key});

  @override
  State<RaceCatalogScreen> createState() => _RaceCatalogScreenState();
}

class _RaceCatalogScreenState extends State<RaceCatalogScreen> {
  final TextEditingController searchController = TextEditingController();

  late Future<List<RaceData>> racesFuture;

  @override
  void initState() {
    super.initState();
    racesFuture = loadRaces();
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
      appBar: AppBar(title: const Text('Расы'), centerTitle: true),
      body: FutureBuilder<List<RaceData>>(
        future: racesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Ошибка загрузки рас:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final races = snapshot.data ?? [];

          final filteredRaces = races.where((race) {
            return race.name.toLowerCase().contains(query) ||
                race.englishName.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Поиск расы',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
              ),
              Expanded(
                child: filteredRaces.isEmpty
                    ? const Center(child: Text('Расы не найдены'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredRaces.length,
                        itemBuilder: (context, index) {
                          final race = filteredRaces[index];

                          return Card(
                            child: ListTile(
                              title: Text(
                                race.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(race.source),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RaceDetailScreen(race: race),
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
