import 'package:coffee_app/presentation/widgets/shimmers/base_shimmer.dart';
import 'package:coffee_app/core/localization/json_localizations.dart';
import 'package:coffee_app/core/localization/lang_keys.dart';
import 'package:flutter/material.dart';

class ReportsShimmer extends StatelessWidget {
  const ReportsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards Shimmer
        const Row(
          children: [
            Expanded(child: SummaryCardShimmer()),
            SizedBox(width: 16),
            Expanded(child: SummaryCardShimmer()),
          ],
        ),
        const SizedBox(height: 32),

        // Consumption Trend Chart Shimmer
        Text(
          context.tr(LangKeys.consumption_trend),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        const ChartShimmer(),
        const SizedBox(height: 32),

        // Waste Analysis Chart Shimmer
        Text(
          context.tr(LangKeys.waste_analysis),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        const ChartShimmer(),
      ],
    );
  }
}

class SummaryCardShimmer extends StatelessWidget {
  const SummaryCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      height: 100,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon placeholder
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            // Title placeholder
            Container(
              width: 120,
              height: 14,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 4),
            // Value placeholder
            Container(
              width: 80,
              height: 24,
              color: Colors.white.withOpacity(0.1),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartShimmer extends StatelessWidget {
  const ChartShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      height: 250,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart area placeholder with grid-like pattern
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomPaint(
                  painter: GridPainter(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += size.width / 6) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += size.height / 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}