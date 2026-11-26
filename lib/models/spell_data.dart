// МОДЕЛЬ ЗАКЛИНАНИЯ

class SpellData {
  final String id;
  final String name;
  final String englishName;
  final int level;
  final String school;
  final String castingTime;
  final String range;
  final List<String> components;
  final String material;
  final String duration;
  final bool concentration;
  final bool ritual;
  final List<String> classes;
  final List<String> subclasses;
  final String description;
  final String higherLevels;
  final List<String> sources;

  const SpellData({
    required this.id,
    required this.name,
    required this.englishName,
    required this.level,
    required this.school,
    required this.castingTime,
    required this.range,
    required this.components,
    this.material = '',
    required this.duration,
    this.concentration = false,
    this.ritual = false,
    required this.classes,
    this.subclasses = const [],
    required this.description,
    this.higherLevels = '',
    required this.sources,
  });

  factory SpellData.fromJson(Map<String, dynamic> json) {
    return SpellData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      englishName: json['englishName'] ?? '',
      level: json['level'] ?? 0,
      school: json['school'] ?? '',
      castingTime: json['castingTime'] ?? '',
      range: json['range'] ?? '',
      components: List<String>.from(json['components'] ?? []),
      material: json['material'] ?? '',
      duration: json['duration'] ?? '',
      concentration: json['concentration'] ?? false,
      ritual: json['ritual'] ?? false,
      classes: List<String>.from(json['classes'] ?? []),
      subclasses: List<String>.from(json['subclasses'] ?? []),
      description: json['description'] ?? '',
      higherLevels: json['higherLevels'] ?? '',
      sources: List<String>.from(json['sources'] ?? []),
    );
  }
}
