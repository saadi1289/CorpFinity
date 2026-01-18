import 'dart:convert';

class GeneratedChallenge {
  final String title;
  final String description;
  final String duration;
  final String emoji;
  final String? funFact;
  final String? goalCategory;
  final String? energyLevel;
  
  const GeneratedChallenge({
    required this.title,
    required this.description,
    required this.duration,
    required this.emoji,
    this.funFact,
    this.goalCategory,
    this.energyLevel,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'duration': duration,
      'emoji': emoji,
      'funFact': funFact,
      'goalCategory': goalCategory,
      'energyLevel': energyLevel,
    };
  }
  
  factory GeneratedChallenge.fromJson(Map<String, dynamic> json) {
    return GeneratedChallenge(
      title: json['title'] as String,
      description: json['description'] as String,
      duration: json['duration'] as String,
      emoji: json['emoji'] as String,
      funFact: json['funFact'] as String?,
      goalCategory: json['goalCategory'] as String?,
      energyLevel: json['energyLevel'] as String?,
    );
  }
}

class ChallengeHistoryItem extends GeneratedChallenge {
  final String id;
  final DateTime completedAt;
  
  const ChallengeHistoryItem({
    required this.id,
    required this.completedAt,
    required super.title,
    required super.duration,
    required super.emoji,
    super.description = '',
    super.funFact,
    super.goalCategory,
    super.energyLevel,
  });
  
  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'id': id,
      'completedAt': completedAt.toIso8601String(),
    };
  }
  
  factory ChallengeHistoryItem.fromJson(Map<String, dynamic> json) {
    return ChallengeHistoryItem(
      id: json['id'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      duration: json['duration'] as String,
      emoji: json['emoji'] as String,
      funFact: json['funFact'] as String?,
      goalCategory: json['goalCategory'] as String?,
      energyLevel: json['energyLevel'] as String?,
    );
  }
  
  String toJsonString() => jsonEncode(toJson());
  
  factory ChallengeHistoryItem.fromJsonString(String source) =>
      ChallengeHistoryItem.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
