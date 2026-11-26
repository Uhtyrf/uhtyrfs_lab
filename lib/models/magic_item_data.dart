// МОДЕЛЬ МАГИЧЕСКОГО ПРЕДМЕТА

class MagicItemData {
  final String id;
  final String name;
  final String englishName;
  final String source;
  final String? sourceCode;
  final String category;
  final String rarity;
  final bool requiresAttunement;
  final String? attunementRequirements;
  final String description;
  final List<Map<String, dynamic>> effects;
  final Map<String, dynamic>? charges;
  final String? displayCharges;
  final List<String> properties;
  final String automationStatus;
  final Map<String, dynamic> price;

  const MagicItemData({
    required this.id,
    required this.name,
    required this.englishName,
    required this.source,
    this.sourceCode,
    required this.category,
    required this.rarity,
    required this.requiresAttunement,
    this.attunementRequirements,
    required this.description,
    required this.effects,
    this.charges,
    this.displayCharges,
    required this.properties,
    required this.automationStatus,
    required this.price,
  });

  factory MagicItemData.fromJson(Map<String, dynamic> json) {
    final rawCharges = json['charges'];
    final rawPrice = json['price'];
    return MagicItemData(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      englishName: json['englishName']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      sourceCode: json['sourceCode']?.toString(),
      category: json['category']?.toString() ?? '',
      rarity: json['rarity']?.toString() ?? '',
      requiresAttunement: json['requiresAttunement'] == true,
      attunementRequirements: json['attunementRequirements']?.toString(),
      description: json['description']?.toString() ?? '',
      effects: (json['effects'] as List? ?? [])
          .whereType<Map>()
          .map((effect) => Map<String, dynamic>.from(effect))
          .toList(),
      charges: rawCharges is Map ? Map<String, dynamic>.from(rawCharges) : null,
      displayCharges: json['displayCharges']?.toString(),
      properties: (json['properties'] as List? ?? [])
          .map((value) => value.toString())
          .toList(),
      automationStatus: json['automationStatus']?.toString() ?? '',
      price: rawPrice is Map
          ? Map<String, dynamic>.from(rawPrice)
          : <String, dynamic>{},
    );
  }
}
