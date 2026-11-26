import 'package:flutter/material.dart';
import 'magic_item_catalog_screen.dart';
import 'spell_catalog_screen.dart';

// ЭКРАН МАГИИ
class MagicScreen extends StatelessWidget {
  const MagicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Магия')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ЗАГОВОРЫ
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const SpellCatalogScreen(title: 'Заговоры', level: 0),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Заговоры'),
              ),
            ),

            const SizedBox(height: 12),

            // ЗАКЛИНАНИЯ
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const SpellCatalogScreen(title: 'Заклинания'),
                    ),
                  );
                },
                icon: const Icon(Icons.menu_book),
                label: const Text('Заклинания'),
              ),
            ),

            const SizedBox(height: 12),
            const SizedBox(height: 12),

// МАГИЧЕСКИЕ ПРЕДМЕТЫ
SizedBox(
  width: double.infinity,
  child: FilledButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MagicItemCatalogScreen(),
        ),
      );
    },
    icon: const Icon(Icons.diamond),
    label: const Text('Магические предметы'),
  ),
),
          ],
        ),
      ),
    );
  }
}
