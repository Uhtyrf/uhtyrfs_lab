import 'package:flutter/material.dart';

import 'features/reference/backgrounds/background_catalog_screen.dart';
import 'features/reference/classes/class_catalog_screen.dart';
import 'features/reference/feats/feat_catalog_screen.dart';
import 'features/reference/races/race_catalog_screen.dart';
import 'features/dice/dice_screen.dart';
import 'features/magic/screens/magic_screen.dart';
import 'features/character/screens/character_list_screen.dart';

void main() {
  runApp(const UhtyrfsLabApp());
}

class UhtyrfsLabApp extends StatelessWidget {
  const UhtyrfsLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uhtyrf’s Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
// КЭШИРОВАНИЕ И ЗАГРУЗКА JSON-ДАННЫХ
// Каждый JSON-файл читается один раз за время работы приложения.
// При повторном открытии каталога данные берутся из памяти.

// ГЛАВНОЕ МЕНЮ
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uhtyrf’s Lab'), centerTitle: true),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.casino, size: 90, color: Colors.deepPurple),
                const SizedBox(height: 20),
                const Text(
                  'Лаборатория Ухтюрфа',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Инструменты для Dungeons & Dragons',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DiceScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.casino),
                    label: const Text('Бросить кубики'),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CharacterListScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person),
                    label: const Text('Персонаж'),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MagicScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Магия'),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReferenceScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Справочник'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// СПРАВОЧНИК

class ReferenceScreen extends StatelessWidget {
  const ReferenceScreen({super.key});

  static const sections = [
    ReferenceSection('Расы', Icons.groups),
    ReferenceSection('Классы', Icons.shield),
    ReferenceSection('Черты', Icons.star),
    ReferenceSection('Предыстории', Icons.history_edu),
    ReferenceSection('Предметы', Icons.backpack),
    ReferenceSection('Правила', Icons.menu_book),
    ReferenceSection('Заклинания', Icons.auto_awesome),
    ReferenceSection('Снаряжение', Icons.shield),
    ReferenceSection('Состояния', Icons.warning_amber),
    ReferenceSection('Существа', Icons.pets),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Справочник'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'D&D 5 редакция',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text('Основная база правил: 2014 год'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          ...sections.map((section) {
            return Card(
              child: ListTile(
                leading: Icon(section.icon, color: Colors.deepPurple, size: 30),
                title: Text(
                  section.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ReferenceSectionScreen(section: section),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class ReferenceSection {
  final String name;
  final IconData icon;

  const ReferenceSection(this.name, this.icon);
}
// ОТДЕЛЬНЫЙ РАЗДЕЛ СПРАВОЧНИКА

class ReferenceSectionScreen extends StatelessWidget {
  final ReferenceSection section;

  const ReferenceSectionScreen({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    // Если выбран раздел «Расы», открываем каталог рас
    if (section.name == 'Расы') {
      return const RaceCatalogScreen();
    }

    if (section.name == 'Классы') {
      return const ClassCatalogScreen();
    }
    if (section.name == 'Черты') {
      return const FeatCatalogScreen();
    }
    if (section.name == 'Предыстории') {
      return const BackgroundCatalogScreen();
    }
    // Остальные разделы пока оставляем заглушками
    return Scaffold(
      appBar: AppBar(title: Text(section.name), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(section.icon, size: 70, color: Colors.deepPurple),
              const SizedBox(height: 20),
              Text(
                section.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Раздел справочника.\n'
                'Здесь будет размещена база данных D&D 5e (2014).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
