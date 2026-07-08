import 'package:coffee_app/new_data/business_report.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'bi_theme.dart';

/// Category revenue distribution as a donut chart, with a legend that also
/// surfaces orders and profit per category (tap a legend row to see it
/// highlighted — kept simple with a selected-index state).
class BiCategoryPieChart extends StatefulWidget {
  final List<CategoryStat> categoryStats;

  const BiCategoryPieChart({super.key, required this.categoryStats});

  @override
  State<BiCategoryPieChart> createState() => _BiCategoryPieChartState();
}

class _BiCategoryPieChartState extends State<BiCategoryPieChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final stats = widget.categoryStats;
    if (stats.isEmpty) {
      return const BiGlassCard(
        child: SizedBox(
          height: 160,
          child: Center(
            child: Text('No category data yet',
                style: TextStyle(color: BiColors.white)),
          ),
        ),
      );
    }

    final totalRevenue = stats.fold<double>(0, (sum, c) => sum + c.revenue);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 700;

    final chart = SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 52,
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              if (!event.isInterestedForInteractions ||
                  response?.touchedSection == null) {
                setState(() => _selectedIndex = null);
                return;
              }
              setState(() => _selectedIndex =
                  response!.touchedSection!.touchedSectionIndex);
            },
          ),
          sections: [
            for (int i = 0; i < stats.length; i++)
              PieChartSectionData(
                value: stats[i].revenue,
                color: BiColors.categoryColor(i),
                radius: _selectedIndex == i ? 46 : 40,
                showTitle: false,
              ),
          ],
        ),
      ),
    );

    final legend = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < stats.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: _LegendRow(
              color: BiColors.categoryColor(i),
              stat: stats[i],
              sharePct: totalRevenue == 0
                  ? 0
                  : (stats[i].revenue / totalRevenue) * 100,
              selected: _selectedIndex == i,
              onTap: () => setState(
                  () => _selectedIndex = _selectedIndex == i ? null : i),
            ),
          ),
      ],
    );

    return BiGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue by Category',
            style: TextStyle(
              color: BiColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 4, child: chart),
                    const SizedBox(width: 16),
                    Expanded(flex: 5, child: legend),
                  ],
                )
              : Column(
                  children: [
                    chart,
                    const SizedBox(height: 14),
                    legend,
                  ],
                ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final CategoryStat stat;
  final double sharePct;
  final bool selected;
  final VoidCallback onTap;

  const _LegendRow({
    required this.color,
    required this.stat,
    required this.sharePct,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.06) : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                stat.categoryName,
                style: const TextStyle(
                  color: BiColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${sharePct.toStringAsFixed(0)}%',
              style: TextStyle(
                color: BiColors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              stat.revenue.toMoney(),
              style: const TextStyle(
                color: BiColors.caramelLight,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
