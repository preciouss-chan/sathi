import 'share_card_data.dart';

class WeeklyCheckinEntry {
  WeeklyCheckinEntry({
    required this.id,
    required this.createdAt,
    required this.homesickIntensity,
    required this.socialConnectionStruggle,
    required this.workloadOverwhelm,
    required this.dailyFunctionImpact,
    required this.culturalFriction,
    required this.moodDrain,
    required this.supportDifficulty,
    required this.shareCard,
  });

  final String id;
  final DateTime createdAt;
  final double homesickIntensity;
  final double socialConnectionStruggle;
  final double workloadOverwhelm;
  final double dailyFunctionImpact;
  final double culturalFriction;
  final double moodDrain;
  final double supportDifficulty;
  final ShareCardData shareCard;

  List<double> get responses => [
        homesickIntensity,
        socialConnectionStruggle,
        workloadOverwhelm,
        dailyFunctionImpact,
        culturalFriction,
        moodDrain,
        supportDifficulty,
      ];

  double get totalScore => responses.fold(0, (sum, value) => sum + value);
}
