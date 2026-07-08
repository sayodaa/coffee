import 'package:flutter/material.dart';

/// Shared design tokens for the Business Intelligence dashboard.
///
/// Values are copied 1:1 from the existing `ReportsPage` palette
/// (`_kCaramel` / `_kWhite` / `_kBgDark` / `_kBgMid`) so the new dashboard
/// content blends into the existing background, header, and typography
/// instead of introducing a second visual language.
class BiColors {
  BiColors._();

  static const caramel = Color(0xFFC68E52);
  static const caramelLight = Color(0xFFE0B583);
  static const white = Colors.white;
  static const bgDark = Color(0xFF1B1512);
  static const bgMid = Color(0xFF2A211C);

  static const success = Color(0xFF6FCF97);
  static const warning = Color(0xFFF2C94C);
  static const critical = Color(0xFFEB5757);
  static const info = Color(0xFF56CCF2);

  /// Category accent palette used across pie/bar charts so the same
  /// category always gets the same color across every chart on the page.
  static const List<Color> categoryPalette = [
    caramel,
    Color(0xFF8D6E63),
    Color(0xFFD7A86E),
    Color(0xFF6FCF97),
    Color(0xFF56CCF2),
    Color(0xFFBB86FC),
    Color(0xFFF2994A),
    Color(0xFFEB5757),
  ];

  static Color categoryColor(int index) =>
      categoryPalette[index % categoryPalette.length];

  static Color severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return critical;
      case 'warning':
        return warning;
      default:
        return info;
    }
  }
}

/// A frosted "glass" card used across the BI dashboard — subtle blur-free
/// glassmorphism (translucent fill + hairline border) that stays cheap to
/// render on long scrolling pages full of charts.
class BiGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const BiGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Money formatting helper shared by every KPI/list widget.
extension BiMoneyFormat on num {
  String toMoney({String symbol = 'EGP'}) {
    final value = toDouble();
    final fixed = value.abs() >= 1000
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    final withCommas = _withThousandsSeparator(fixed);
    return '$withCommas $symbol';
  }

  String toCompactNumber() {
    final value = toDouble();
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  static String _withThousandsSeparator(String number) {
    final isNegative = number.startsWith('-');
    final clean = isNegative ? number.substring(1) : number;
    final parts = clean.split('.');
    final intPart = parts[0];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final posFromEnd = intPart.length - i;
      buffer.write(intPart[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write(',');
    }
    final result = parts.length > 1 ? '${buffer.toString()}.${parts[1]}' : buffer.toString();
    return isNegative ? '-$result' : result;
  }
}
