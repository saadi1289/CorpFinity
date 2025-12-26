import 'dart:convert';

class GeneratedChallenge {
  final String title;
  final String description;
  final String duration;
  final String emoji;
  final String? funFact;
  
  const GeneratedChallenge({
    required this.title,
    required this.description,
    required this.duration,
    required this.emoji,
    this.funFact,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'duration': duration,
      'emoji': emoji,
      'funFact': funFact,
    };
  }
  
  factory GeneratedChallenge.fromJson(Map<String, dynamic> json) {
    return GeneratedChallenge(
      title: json['title'] as String,
      description: json['description'] as String,
      duration: json['duration'] as String,
      emoji: json['emoji'] as String,
      funFact: json['funFact'] as String?,
    );
  }
}

class ChallengeHistoryItem extends GeneratedChallenge {
  final String id;
  final String completedAt;
  
  const ChallengeHistoryItem({
    required this.id,
    required this.completedAt,
    required super.title,
    required super.description,
    required super.duration,
    required super.emoji,
    super.funFact,
  });
  
  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'id': id,
      'completedAt': completedAt,
    };
  }
  
  factory ChallengeHistoryItem.fromJson(Map<String, dynamic> json) {
    return ChallengeHistoryItem(
      id: json['id'] as String,
      completedAt: json['completedAt'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      duration: json['duration'] as String,
      emoji: json['emoji'] as String,
      funFact: json['funFact'] as String?,
    );
  }
  
  String toJsonString() => jsonEncode(toJson());
  
  factory ChallengeHistoryItem.fromJsonString(String source) =>
      ChallengeHistoryItem.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
