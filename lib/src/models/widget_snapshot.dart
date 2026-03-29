class WidgetSnapshot {
  const WidgetSnapshot({required this.generatedAt, required this.friends});

  final DateTime generatedAt;
  final List<WidgetFriendSnapshot> friends;

  Map<String, dynamic> toJson() => {
        'version': 1,
        'generatedAt': generatedAt.toIso8601String(),
        'friends': friends.map((friend) => friend.toJson()).toList(),
      };
}

class WidgetFriendSnapshot {
  const WidgetFriendSnapshot({
    required this.uid,
    required this.displayName,
    required this.updatedAt,
    this.scoreLabel,
    this.statusLabel,
    this.photoPath,
    this.voiceKeywords = const [],
    this.supportSuggestion,
    this.deepLink,
  });

  final String uid;
  final String displayName;
  final DateTime updatedAt;
  final String? scoreLabel;
  final String? statusLabel;
  final String? photoPath;
  final List<String> voiceKeywords;
  final String? supportSuggestion;
  final String? deepLink;

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'updatedAt': updatedAt.toIso8601String(),
        'scoreLabel': scoreLabel,
        'statusLabel': statusLabel,
        'photoPath': photoPath,
        'voiceKeywords': voiceKeywords,
        'supportSuggestion': supportSuggestion,
        'deepLink': deepLink,
      };
}
