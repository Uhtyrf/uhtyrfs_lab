class BackgroundData {
  final String id;
  final String name;
  final String englishName;
  final String source;
  final String description;
  final List<String> skillProficiencies;
  final List<String> toolProficiencies;
  final String languages;
  final List<String> equipment;
  final String featureName;
  final String featureDescription;

  BackgroundData({
    required this.id,
    required this.name,
    required this.englishName,
    required this.source,
    required this.description,
    required this.skillProficiencies,
    required this.toolProficiencies,
    required this.languages,
    required this.equipment,
    required this.featureName,
    required this.featureDescription,
  });

  factory BackgroundData.fromJson(Map<String, dynamic> json) {
    return BackgroundData(
      id: json['id'],
      name: json['name'],
      englishName: json['englishName'],
      source: json['source'],
      description: json['description'],
      skillProficiencies: List<String>.from(json['skillProficiencies']),
      toolProficiencies: List<String>.from(json['toolProficiencies']),
      languages: json['languages'],
      equipment: List<String>.from(json['equipment']),
      featureName: json['featureName'],
      featureDescription: json['featureDescription'],
    );
  }
}
