import 'package:flutter/material.dart';

import '../../../data/loaders/magic_item_loader.dart';
import '../../../models/magic_item_data.dart';

// КАТАЛОГ МАГИЧЕСКИХ ПРЕДМЕТОВ

class MagicItemCatalogScreen extends StatefulWidget {
  const MagicItemCatalogScreen({super.key});

  @override
  State<MagicItemCatalogScreen> createState() => _MagicItemCatalogScreenState();
}

class _MagicItemCatalogScreenState extends State<MagicItemCatalogScreen> {
  final TextEditingController searchController = TextEditingController();
  late Future<List<MagicItemData>> itemsFuture;
  String selectedRarity = 'all';
  String selectedCategory = 'all';
  String selectedAttunement = 'all';

  @override
  void initState() {
    super.initState();
    itemsFuture = loadMagicItems();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String rarityLabel(String rarity) {
    const labels = {
      'common': 'Обычный',
      'uncommon': 'Необычный',
      'rare': 'Редкий',
      'very_rare': 'Очень редкий',
      'legendary': 'Легендарный',
      'artifact': 'Артефакт',
      'varies': 'Разная',
    };
    return labels[rarity] ?? rarity;
  }

  String categoryLabel(String category) {
    const labels = {
      'weapon': 'Оружие',
      'armor': 'Доспех',
      'shield': 'Щит',
      'wondrous_item': 'Чудесный предмет',
      'potion': 'Зелье',
      'ring': 'Кольцо',
      'wand': 'Жезл',
      'staff': 'Посох',
      'rod': 'Скипетр',
      'ammunition': 'Боеприпасы',
      'scroll': 'Свиток',
    };
    return labels[category] ?? category;
  }

  String priceLabel(Map<String, dynamic> price) {
    if (price.isEmpty) return 'Не указана';

    final min = price['min'];
    final max = price['max'];
    final currency = price['currency']?.toString() ?? 'gp';

    if (min == null && max == null) return 'Не указана';

    if (min != null && max != null && min != max) {
      return '$min–$max $currency';
    }

    return '${min ?? max} $currency';
  }

  Widget infoLine(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Магические предметы'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<MagicItemData>>(
        future: itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Ошибка загрузки магических предметов:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final items = snapshot.data ?? const <MagicItemData>[];
          final categories = items.map((item) => item.category).toSet().toList()
            ..sort();
          final rarities = items.map((item) => item.rarity).toSet().toList()
            ..sort();
          final filteredItems = items.where((item) {
            final matchesSearch =
                item.name.toLowerCase().contains(query) ||
                item.englishName.toLowerCase().contains(query) ||
                item.description.toLowerCase().contains(query);
            final matchesRarity =
                selectedRarity == 'all' || item.rarity == selectedRarity;
            final matchesCategory =
                selectedCategory == 'all' || item.category == selectedCategory;
            final matchesAttunement =
                selectedAttunement == 'all' ||
                (selectedAttunement == 'yes' && item.requiresAttunement) ||
                (selectedAttunement == 'no' && !item.requiresAttunement);
            return matchesSearch &&
                matchesRarity &&
                matchesCategory &&
                matchesAttunement;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Поиск предмета',
                    hintText: 'Русское или английское название',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              setState(() {});
                            },
                          ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedRarity,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Редкость',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('Все редкости'),
                          ),
                          ...rarities.map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(rarityLabel(value)),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          selectedRarity = value ?? 'all';
                        }),
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Тип',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('Все типы'),
                          ),
                          ...categories.map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(categoryLabel(value)),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          selectedCategory = value ?? 'all';
                        }),
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedAttunement,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Настройка',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Любая')),
                          DropdownMenuItem(
                            value: 'yes',
                            child: Text('Требуется'),
                          ),
                          DropdownMenuItem(
                            value: 'no',
                            child: Text('Не требуется'),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          selectedAttunement = value ?? 'all';
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Найдено: ${filteredItems.length} из ${items.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              Expanded(
                child: filteredItems.isEmpty
                    ? const Center(child: Text('Предметы не найдены'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return Card(
                            child: ExpansionTile(
                              leading: const Icon(
                                Icons.diamond,
                                color: Colors.deepPurple,
                              ),
                              title: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${rarityLabel(item.rarity)} · '
                                '${categoryLabel(item.category)}',
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                16,
                              ),
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      infoLine('Название', item.englishName),
                                      infoLine('Источник', item.source),
                                      infoLine(
                                        'Настройка',
                                        item.requiresAttunement
                                            ? (item.attunementRequirements ==
                                                      null
                                                  ? 'Требуется'
                                                  : 'Требуется: ${item.attunementRequirements}')
                                            : 'Не требуется',
                                      ),
                                      infoLine('Цена', priceLabel(item.price)),
                                      if (item.description
                                          .trim()
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Описание',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(item.description),
                                      ] else ...[
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Описание для этого предмета пока не заполнено.',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                      if (item.displayCharges != null &&
                                          item.displayCharges!.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        infoLine(
                                          'Заряды',
                                          item.displayCharges!,
                                        ),
                                      ],
                                      if (item.properties.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Особые свойства',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        ...item.properties.map(
                                          (property) => Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text('• $property'),
                                          ),
                                        ),
                                      ],
                                      if (item.effects.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Структурированные эффекты',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        ...item.effects.map((effect) {
                                          final type =
                                              effect['displayType']
                                                  ?.toString() ??
                                              effect['type']?.toString() ??
                                              '';
                                          final target =
                                              effect['displayTarget']
                                                  ?.toString() ??
                                              effect['target']?.toString() ??
                                              '';
                                          final operation =
                                              effect['displayOperation']
                                                  ?.toString() ??
                                              effect['operation']?.toString() ??
                                              '';
                                          final value =
                                              effect['displayValue']
                                                  ?.toString() ??
                                              effect['value']?.toString() ??
                                              '';
                                          final condition =
                                              effect['displayCondition']
                                                  ?.toString() ??
                                              effect['condition']?.toString() ??
                                              '';
                                          final parts = [
                                            type,
                                            if (target.isNotEmpty) target,
                                            if (operation.isNotEmpty) operation,
                                            if (value.isNotEmpty) value,
                                            if (condition.isNotEmpty) condition,
                                          ];
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 5,
                                            ),
                                            child: Text(
                                              '• ${parts.join(' — ')}',
                                            ),
                                          );
                                        }),
                                      ],
                                      if (item.automationStatus.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          'Статус автоматизации: ${item.automationStatus}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
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
