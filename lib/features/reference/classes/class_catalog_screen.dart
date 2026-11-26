import 'package:flutter/material.dart';

import '../../../data/loaders/class_loader.dart';
import '../../../models/class_data.dart';
import 'class_detail_screen.dart';

class ClassCatalogScreen extends StatefulWidget {
  const ClassCatalogScreen({super.key});

  @override
  State<ClassCatalogScreen> createState() => _ClassCatalogScreenState();
}

class _ClassCatalogScreenState extends State<ClassCatalogScreen> {
  final TextEditingController searchController = TextEditingController();

  late Future<List<DndClassData>> classesFuture;

  @override
  void initState() {
    super.initState();
    classesFuture = loadClasses();
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
      appBar: AppBar(title: const Text('Классы'), centerTitle: true),
      body: FutureBuilder<List<DndClassData>>(
        future: classesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Ошибка загрузки классов:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final classes = snapshot.data ?? [];

          final filteredClasses = classes.where((classData) {
            return classData.name.toLowerCase().contains(query) ||
                classData.englishName.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Поиск класса',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
              ),
              Expanded(
                child: filteredClasses.isEmpty
                    ? const Center(child: Text('Классы не найдены'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredClasses.length,
                        itemBuilder: (context, index) {
                          final classData = filteredClasses[index];

                          return Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.shield,
                                color: Colors.deepPurple,
                                size: 30,
                              ),
                              title: Text(
                                classData.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${classData.englishName} · '
                                'Кость хитов: D${classData.hitDie}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ClassDetailScreen(classData: classData),
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
