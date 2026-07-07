import 'package:coffee_app/core/theme/app_colors.dart';
import 'package:coffee_app/core/widgets/premium_card.dart';
import 'package:flutter/material.dart';

class ReportsDateFilter extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?) onDateSelected;

  const ReportsDateFilter({
    super.key,
    this.startDate,
    this.endDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String dateText = startDate != null && endDate != null
        ? '${_formatDate(startDate!)} - ${_formatDate(endDate!)}'
        : 'Select Date Range';

    return PremiumCard(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () async {
        final result = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: startDate != null && endDate != null
              ? DateTimeRange(start: startDate!, end: endDate!)
              : null,
          builder: (context, child) {
            return Theme(
              data: theme.copyWith(
                colorScheme: theme.colorScheme.copyWith(
                  primary: AppColors.cream,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );

        if (result != null) {
          onDateSelected(result.start, result.end);
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_outlined,
                  color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Time Period',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    dateText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (startDate != null || endDate != null)
            IconButton(
              icon: Icon(Icons.close,
                  color: theme.iconTheme.color?.withOpacity(0.5), size: 20),
              onPressed: () => onDateSelected(null, null),
            )
          else
            Icon(Icons.arrow_drop_down,
                color: theme.iconTheme.color?.withOpacity(0.5)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
