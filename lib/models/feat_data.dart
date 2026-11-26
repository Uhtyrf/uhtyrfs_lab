
class FeatData {
  final String id;
  final String name;
  final String englishName;
  final String source;
  final String? prerequisite;
  final String description;
  final List<String> benefits;
  final List<FeatChoice> choices;
  final AbilityScoreIncrease? abilityScoreIncrease;

  FeatData({
    required this.id,
    required this.name,
    required this.englishName,
    required this.source,
    this.prerequisite,
    required this.description,
    required this.benefits,
    this.choices = const [],
    this.abilityScoreIncrease,
  });

  factory FeatData.fromJson(Map<String, dynamic> json) {
    return FeatData(
      id: json['id'],
      name: json['name'],
      englishName: json['englishName'],
      source: json['source'],
      prerequisite: json['prerequisite'],
      description: json['description'],
      benefits: List<String>.from(json['benefits'] ?? []),
      choices: (json['choices'] as List<dynamic>? ?? [])
          .map((item) => FeatChoice.fromJson(item))
          .toList(),
      abilityScoreIncrease: json['abilityScoreIncrease'] != null
          ? AbilityScoreIncrease.fromJson(
              json['abilityScoreIncrease'],
            )
          : null,
    );
  }
}

class FeatChoice {
  final String category;
  final int count;
  final String instruction;
  final List<String> options;
  final String? sourceField;

  FeatChoice({
    required this.category,
    required this.count,
    required this.instruction,
    required this.options,
    this.sourceField,
  });

  factory FeatChoice.fromJson(Map<String, dynamic> json) {
    return FeatChoice(
      category: json['category'] ?? '',
      count: json['count'] ?? 1,
      instruction: json['instruction'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      sourceField: json['sourceField'],
    );
  }
}

class AbilityScoreIncrease {
  final int amount;
  final List<String> abilities;

  AbilityScoreIncrease({
    required this.amount,
    required this.abilities,
  });

  factory AbilityScoreIncrease.fromJson(Map<String, dynamic> json) {
    return AbilityScoreIncrease(
      amount: json['amount'] ?? 1,
      abilities: List<String>.from(json['abilities'] ?? []),
    );
  }
}
