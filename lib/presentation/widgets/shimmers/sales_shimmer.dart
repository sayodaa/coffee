import 'package:coffee_app/presentation/widgets/shimmers/base_shimmer.dart';
import 'package:flutter/material.dart';

class SalesShimmer extends StatelessWidget {
  const SalesShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    return Column(
      children: [
        // Stat Cards Shimmer
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: const Row(
            children: [
              Expanded(child: SalesStatCardShimmer()),
              SizedBox(width: 16),
              Expanded(child: SalesStatCardShimmer()),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // Recent Sales Header Shimmer
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              BaseShimmer(
                width: 36,
                height: 36,
                borderRadius: BorderRadius.circular(8),
                child: Container(),
              ),
              const SizedBox(width: 12),
              BaseShimmer(
                width: 120,
                height: 20,
                borderRadius: BorderRadius.circular(4),
                child: Container(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Sales List Shimmer
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5, // Show 5 shimmer items
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 12),
              child: const SalesCardShimmer(),
            );
          },
        ),
      ],
    );
  }
}

class SalesStatCardShimmer extends StatelessWidget {
  const SalesStatCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      height: 80,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon placeholder
            Container(
              width: 24,
              height: 24,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 8),
            // Title placeholder
            Container(
              width: 100,
              height: 14,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 4),
            // Value placeholder
            Container(
              width: 80,
              height: 20,
              color: Colors.white.withOpacity(0.1),
            ),
          ],
        ),
      ),
    );
  }
}

class SalesCardShimmer extends StatelessWidget {
  const SalesCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      height: 80,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Drink icon placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            // Drink details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Drink name
                  Container(
                    width: 120,
                    height: 16,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  const SizedBox(height: 4),
                  // Drink category
                  Container(
                    width: 80,
                    height: 12,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ],
              ),
            ),
            // Price and quantity
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Price
                Container(
                  width: 60,
                  height: 16,
                  color: Colors.white.withOpacity(0.1),
                ),
                const SizedBox(height: 4),
                // Quantity
                Container(
                  width: 40,
                  height: 12,
                  color: Colors.white.withOpacity(0.1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}