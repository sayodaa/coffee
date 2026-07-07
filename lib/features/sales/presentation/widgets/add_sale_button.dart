import 'package:coffee_app/core/localization/json_localizations.dart';
import 'package:coffee_app/core/localization/lang_keys.dart';
import 'package:coffee_app/core/theme/app_colors.dart';
import 'package:coffee_app/features/sales/presentation/widgets/add_sale_bottom_sheet.dart';
import 'package:flutter/material.dart';

class AddSaleButton extends StatelessWidget {
  const AddSaleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const AddSaleBottomSheet(),
        );
      },
      child: Container(
        height: 56,
        constraints: const BoxConstraints(minWidth: 140),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradientDark,
          borderRadius: BorderRadius.circular(28), // Capsule shape
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryIndigo.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  context.tr(LangKeys.add_sale),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
