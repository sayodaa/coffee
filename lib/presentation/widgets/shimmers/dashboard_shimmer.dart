import 'package:coffee_app/presentation/widgets/shimmers/base_shimmer.dart';
import 'package:coffee_app/core/localization/json_localizations.dart';
import 'package:coffee_app/core/localization/lang_keys.dart';
import 'package:flutter/material.dart';

class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2x2 Grid of Stat Cards Shimmer
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(
            4,
            (index) => const StatCardShimmer(),
          ),
        ),
        const SizedBox(height: 32),

        // Charts Section Shimmer
        Text(
          context.tr(LangKeys.analytics_overview),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        const ChartShimmer(),
        const SizedBox(height: 24),
        const ChartShimmer(),
        const SizedBox(height: 32),

        // Stock Overview Section Shimmer
        Text(
          context.tr(LangKeys.stock_overview),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        const StockOverviewShimmer(),
      ],
    );
  }
}

class StatCardShimmer extends StatelessWidget {
  const StatCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      height: 100,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
              width: 80,
              height: 14,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 8),
            // Value placeholder
            Container(
              width: 60,
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
      height: 200,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart title placeholder
            Container(
              width: 120,
              height: 16,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            // Chart area placeholder
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StockOverviewShimmer extends StatelessWidget {
  const StockOverviewShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      height: 120,
      child: ListView.builder(
        itemCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                // Item icon placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item name
                      Container(
                        width: 120,
                        height: 16,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      const SizedBox(height: 4),
                      // Item quantity
                      Container(
                        width: 80,
                        height: 12,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ],
                  ),
                ),
                // Price placeholder
                Container(
                  width: 60,
                  height: 16,
                  color: Colors.white.withOpacity(0.1),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}