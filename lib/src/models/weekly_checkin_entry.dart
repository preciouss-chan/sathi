import 'share_card_data.dart';

class WeeklyCheckinEntry {
  WeeklyCheckinEntry({
    required this.id,
    required this.createdAt,
    required this.lonely,
    required this.familyTalk,
    required this.stress,
    required this.sleep,
    required this.trend,
    required this.shareCard,
  });

  final String id;
  final DateTime createdAt;
  final double lonely;
  final double familyTalk;
  final double stress;
  final double sleep;
  final String trend;
  final ShareCardData shareCard;
}
