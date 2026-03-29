import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/weekly_analysis.dart';
import 'app_cards.dart';

class WeeklyScoreBarChart extends StatelessWidget {
  const WeeklyScoreBarChart({
    super.key,
    required this.points,
  });

  final List<WeeklyThemePoint> points;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Theme intensity', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BarRow(point: point),
            ),
          ),
        ],
      ),
    );
  }
}

class WeeklyThemePieChart extends StatelessWidget {
  const WeeklyThemePieChart({
    super.key,
    required this.points,
  });

  final List<WeeklyThemePoint> points;

  @override
  Widget build(BuildContext context) {
    final total = points.fold<double>(0, (sum, point) => sum + point.score);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Where this week felt heaviest', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _PiePainter(points),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: points
                      .map(
                        (point) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _colorForIndex(points.indexOf(point)),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(point.label)),
                              Text('${((point.score / total) * 100).round()}%'),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WeeklyComparisonCard extends StatelessWidget {
  const WeeklyComparisonCard({
    super.key,
    required this.deltas,
    required this.comparisonMessage,
    required this.recurringThemes,
  });

  final List<WeeklyThemeDelta> deltas;
  final String comparisonMessage;
  final List<String> recurringThemes;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Compared with last week', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(comparisonMessage),
          if (deltas.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...deltas.map(
              (delta) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(child: Text(delta.label)),
                    Text(_deltaLabel(delta.delta)),
                  ],
                ),
              ),
            ),
          ],
          if (recurringThemes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Recurring themes: ${recurringThemes.join(', ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  String _deltaLabel(double delta) {
    if (delta >= 1) return '+${delta.toStringAsFixed(0)} worse';
    if (delta <= -1) return '${delta.toStringAsFixed(0)} better';
    return 'No change';
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.point});

  final WeeklyThemePoint point;

  @override
  Widget build(BuildContext context) {
    final widthFactor = (point.score / 5).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(point.label)),
            Text(point.score.toStringAsFixed(0)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: widthFactor,
            minHeight: 12,
            backgroundColor: AppTheme.background,
            color: _barColor(point.score),
          ),
        ),
      ],
    );
  }

  Color _barColor(double score) {
    if (score >= 4) return const Color(0xFFE07A5F);
    if (score >= 3) return const Color(0xFFF2A65A);
    return const Color(0xFF6AB187);
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter(this.points);

  final List<WeeklyThemePoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final total = points.fold<double>(0, (sum, point) => sum + point.score);
    if (total == 0) {
      return;
    }

    final rect = Offset.zero & size;
    final paint = Paint()..style = PaintingStyle.fill;
    var startAngle = -math.pi / 2;

    for (var index = 0; index < points.length; index++) {
      final sweep = (points[index].score / total) * math.pi * 2;
      paint.color = _colorForIndex(index);
      canvas.drawArc(rect, startAngle, sweep, true, paint);
      startAngle += sweep;
    }

    final holePaint = Paint()..color = Colors.white;
    canvas.drawCircle(rect.center, size.width * 0.22, holePaint);
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) => oldDelegate.points != points;
}

Color _colorForIndex(int index) {
  const palette = [
    Color(0xFFE07A5F),
    Color(0xFFF2A65A),
    Color(0xFF81B29A),
    Color(0xFF6D597A),
    Color(0xFF4D908E),
    Color(0xFFC8553D),
    Color(0xFF577590),
  ];
  return palette[index % palette.length];
}
