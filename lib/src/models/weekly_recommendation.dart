class WeeklyRecommendationAction {
  const WeeklyRecommendationAction({
    required this.title,
    required this.text,
    this.resourceName,
  });

  final String title;
  final String text;
  final String? resourceName;

  factory WeeklyRecommendationAction.fromJson(Map<String, dynamic> json) {
    return WeeklyRecommendationAction(
      title: json['title'] as String? ?? '',
      text: json['text'] as String? ?? '',
      resourceName: json['resourceName'] as String?,
    );
  }
}

class WeeklyRecommendation {
  const WeeklyRecommendation({
    required this.acknowledgement,
    required this.actions,
    this.safetyNote,
  });

  final String acknowledgement;
  final List<WeeklyRecommendationAction> actions;
  final String? safetyNote;

  factory WeeklyRecommendation.fromJson(Map<String, dynamic> json) {
    final rawActions = (json['actions'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(WeeklyRecommendationAction.fromJson)
        .toList();

    return WeeklyRecommendation(
      acknowledgement: json['acknowledgement'] as String? ?? '',
      actions: rawActions,
      safetyNote: json['safetyNote'] as String?,
    );
  }
}

class WeeklyRecommendationTriage {
  const WeeklyRecommendationTriage({
    required this.status,
    this.priorityFlag,
    this.severityScore,
    this.trend,
    this.message,
  });

  final String status;
  final String? priorityFlag;
  final int? severityScore;
  final String? trend;
  final String? message;

  factory WeeklyRecommendationTriage.fromJson(Map<String, dynamic> json) {
    return WeeklyRecommendationTriage(
      status: json['status'] as String? ?? 'unknown',
      priorityFlag: json['priorityFlag'] as String?,
      severityScore: (json['severityScore'] as num?)?.toInt(),
      trend: json['trend'] as String?,
      message: json['message'] as String?,
    );
  }
}

class WeeklyRecommendationResult {
  const WeeklyRecommendationResult({
    required this.triage,
    required this.recommendation,
    this.warning,
  });

  final WeeklyRecommendationTriage triage;
  final WeeklyRecommendation recommendation;
  final String? warning;

  factory WeeklyRecommendationResult.fromJson(Map<String, dynamic> json) {
    return WeeklyRecommendationResult(
      triage: WeeklyRecommendationTriage.fromJson(
        json['triage'] as Map<String, dynamic>? ?? const {},
      ),
      recommendation: WeeklyRecommendation.fromJson(
        json['recommendation'] as Map<String, dynamic>? ?? const {},
      ),
      warning: json['warning'] as String?,
    );
  }
}
