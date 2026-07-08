import 'package:flutter/material.dart';

import 'business_report.dart';
import 'bi_theme.dart';

/// Heat-map-style peak hours view — four horizontal bars (Morning /
/// Afternoon / Evening / Night) sized by revenue share, colored by
/// intensity so the busiest period is immediately obvious.
class BiPeakHoursChart extends StatelessWidget {
  final List<PeakHourBucket> peakHours;

  const BiPeakHoursChart({super.key, required this.peakHours});

  @override
  Widget build(BuildContext context) {
    if (peakHours.isEmpty) {
      return const BiGlassCard(
        child: SizedBox(
          height: 100,
          child: Center(
            child: Text('No peak-hour data yet',
                style: TextStyle(color: BiColors.white)),
          ),
        ),
      );
    }

    final maxRevenue =
        peakHours.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);

    return BiGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule_rounded, color: BiColors.caramel, size: 18),
              SizedBox(width: 8),
              Text(
                'Peak Hours',
                style: TextStyle(
                  color: BiColors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final bucket in peakHours)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _PeakHourRow(
                bucket: bucket,
                intensity: maxRevenue == 0 ? 0 : bucket.revenue / maxRevenue,
              ),
            ),
        ],
      ),
    );
  }
}

class _PeakHourRow extends StatelessWidget {
  final PeakHourBucket bucket;
  final double intensity;

  const _PeakHourRow({required this.bucket, required this.intensity});

  Color get _color {
    if (intensity >= 0.75) return BiColors.critical;
    if (intensity >= 0.45) return BiColors.warning;
    return BiColors.info;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                bucket.label,
                style: const TextStyle(
                  color: BiColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${bucket.orders} orders',
              style: TextStyle(
                color: BiColors.white.withOpacity(0.55),
                fontSize: 11.5,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              bucket.revenue.toMoney(),
              style: TextStyle(
                color: _color,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: intensity.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation(_color),
          ),
        ),
      ],
    );
  }
}
