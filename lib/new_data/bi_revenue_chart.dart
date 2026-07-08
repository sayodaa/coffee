import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'bi_theme.dart';

/// Monthly revenue as a bar chart, with a line-chart trend overlay toggle.
///
/// Assumes `fl_chart` is already a project dependency — the existing
/// `ReportsBarChart` / `ReportsPieChart` widgets referenced in `ReportsPage`
/// strongly imply it already is. If the pubspec uses a different charting
/// package, swap the internals of this widget only; its public API
/// (`revenueByMonth`) stays the same.
class BiRevenueChart extends StatefulWidget {
  final Map<String, double> revenueByMonth;

  const BiRevenueChart({super.key, required this.revenueByMonth});

  @override
  State<BiRevenueChart> createState() => _BiRevenueChartState();
}

class _BiRevenueChartState extends State<BiRevenueChart> {
  bool _showAsLine = false;

  @override
  Widget build(BuildContext context) {
    final entries = widget.revenueByMonth.entries.toList();

    if (entries.isEmpty) {
      return const BiGlassCard(
        child: SizedBox(
          height: 160,
          child: Center(
            child: Text('No revenue data yet',
                style: TextStyle(color: BiColors.white)),
          ),
        ),
      );
    }

    final maxRevenue =
        entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final interval = maxRevenue <= 0 ? 1.0 : maxRevenue / 4;

    return BiGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Monthly Revenue',
                  style: TextStyle(
                    color: BiColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _ChartToggle(
                isLine: _showAsLine,
                onChanged: (v) => setState(() => _showAsLine = v),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: _showAsLine
                ? _buildLineChart(entries, interval)
                : _buildBarChart(entries, interval, maxRevenue),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
    List<MapEntry<String, double>> entries,
    double interval,
    double maxRevenue,
  ) {
    return BarChart(
      BarChartData(
        maxY: maxRevenue * 1.2,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _shortMonthLabel(entries[i].key),
                    style: TextStyle(
                      color: BiColors.white.withOpacity(0.6),
                      fontSize: 10.5,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              rod.toY.toMoney(),
              const TextStyle(color: BiColors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < entries.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entries[i].value,
                  color: BiColors.caramel,
                  width: 16,
                  borderRadius: BorderRadius.circular(6),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxRevenue * 1.2,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLineChart(
    List<MapEntry<String, double>> entries,
    double interval,
  ) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _shortMonthLabel(entries[i].key),
                    style: TextStyle(
                      color: BiColors.white.withOpacity(0.6),
                      fontSize: 10.5,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      s.y.toMoney(),
                      const TextStyle(color: BiColors.white, fontWeight: FontWeight.w700),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (int i = 0; i < entries.length; i++)
                FlSpot(i.toDouble(), entries[i].value),
            ],
            isCurved: true,
            color: BiColors.caramel,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: BiColors.caramel.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }

  static String _shortMonthLabel(String yyyyMm) {
    final parts = yyyyMm.split('-');
    if (parts.length != 2) return yyyyMm;
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final monthIndex = int.tryParse(parts[1]);
    if (monthIndex == null || monthIndex < 1 || monthIndex > 12) return yyyyMm;
    return '${names[monthIndex - 1]} ${parts[0].substring(2)}';
  }
}

class _ChartToggle extends StatelessWidget {
  final bool isLine;
  final ValueChanged<bool> onChanged;

  const _ChartToggle({required this.isLine, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleIcon(
            icon: Icons.bar_chart_rounded,
            selected: !isLine,
            onTap: () => onChanged(false),
          ),
          _ToggleIcon(
            icon: Icons.show_chart_rounded,
            selected: isLine,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? BiColors.caramel.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: selected ? BiColors.caramel : BiColors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}
