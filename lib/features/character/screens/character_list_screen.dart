import 'package:flutter/material.dart';

import '../data/character_repository.dart';
import '../models/character.dart';
import 'character_creation_screen.dart';
import 'character_sheet_screen.dart';

class CharacterListScreen extends StatefulWidget {
  const CharacterListScreen({super.key});

  @override
  State<CharacterListScreen> createState() => _CharacterListScreenState();
}

class _CharacterListScreenState extends State<CharacterListScreen> {
  final CharacterRepository _repository = CharacterRepository();
  List<Character> _characters = [];
  List<String?> _quickSlots = List<String?>.filled(5, null);
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final characters = await _repository.getCharacters();
      final slots = await _repository.getQuickSlots();
      if (!mounted) return;
      setState(() {
        _characters = characters;
        _quickSlots = slots;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Не удалось загрузить персонажей: $error';
      });
    }
  }

  Future<void> _createCharacter() async {
    final character = await Navigator.of(context).push<Character>(
      MaterialPageRoute(builder: (_) => const CharacterCreationScreen()),
    );
    if (character == null) return;
    try {
      await _repository.saveCharacter(character);
      await _loadData();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось сохранить персонажа: $error')),
      );
    }
  }

  Future<void> _toggleQuickSlot(Character character) async {
    final currentSlot = _quickSlots.indexOf(character.id);
    if (currentSlot >= 0) {
      await _repository.setQuickSlot(currentSlot, null);
      await _loadData();
      return;
    }

    final emptySlot = _quickSlots.indexOf(null);
    final slot = emptySlot >= 0
        ? emptySlot
        : await showDialog<int>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Быстрые слоты заполнены'),
              content: const Text('Выбери слот, который нужно заменить.'),
              actions: [
                for (var i = 0; i < 5; i++)
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, i),
                    child: Text('Слот ${i + 1}'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Отмена'),
                ),
              ],
            ),
          );

    if (slot == null) return;
    await _repository.setQuickSlot(slot, character.id);
    await _loadData();
  }

  Future<void> _deleteCharacter(Character character) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить персонажа?'),
        content: Text(
          'Персонаж «${character.name}» будет удалён с устройства.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.deleteCharacter(character.id);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Персонажи'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCharacter,
        icon: const Icon(Icons.person_add),
        label: const Text('Создать'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loadData,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  _buildQuickSlots(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'Все персонажи',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Text(
                        '${_characters.length}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_characters.isEmpty)
                    _buildEmptyState()
                  else
                    ..._characters.map(_buildCharacterCard),
                ],
              ),
            ),
    );
  }

  Character? _findCharacter(String id) {
    for (final character in _characters) {
      if (character.id == id) return character;
    }
    return null;
  }

  Widget _buildQuickSlots() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Быстрые слоты',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (index) {
                final id = _quickSlots[index];
                final character = id == null ? null : _findCharacter(id);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index == 4 ? 0 : 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: character == null
                          ? _createCharacter
                          : () => _showCharacterInfo(character),
                      onLongPress: character == null
                          ? null
                          : () => _showQuickSlotMenu(character, index),
                      child: Container(
                        height: 76,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              character == null ? Icons.add : Icons.person,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              character?.name ?? 'Слот ${index + 1}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showQuickSlotMenu(Character character, int slotIndex) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(character.name),
              subtitle: Text('Быстрый слот ${slotIndex + 1}'),
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Убрать из слота'),
              onTap: () => Navigator.pop(sheetContext, 'remove'),
            ),
          ],
        ),
      ),
    );

    if (action == 'remove') {
      await _repository.setQuickSlot(slotIndex, null);
      await _loadData();
    }
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Column(
          children: [
            Icon(
              Icons.groups_outlined,
              size: 54,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Пока нет персонажей',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Создай первого героя — его данные будут сохранены на устройстве.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterCard(Character character) {
    final isPinned = _quickSlots.contains(character.id);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.person,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(character.name),
        subtitle: Text(
          [
            if (character.race.isNotEmpty) character.race,
            if (character.characterClass.isNotEmpty) character.characterClass,
            if (character.background.isNotEmpty) character.background,
            'Уровень ${character.level}',
          ].join(' • '),
        ),
        onTap: () => _showCharacterInfo(character),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'pin') _toggleQuickSlot(character);
            if (value == 'delete') _deleteCharacter(character);
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'pin',
              child: Text(
                isPinned
                    ? 'Убрать из быстрых слотов'
                    : 'Закрепить в быстром слоте',
              ),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Удалить')),
          ],
        ),
      ),
    );
  }

  void _showCharacterInfo(Character character) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CharacterSheetScreen(character: character),
      ),
    );
  }
}
