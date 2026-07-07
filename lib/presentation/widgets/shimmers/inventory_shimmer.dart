import 'package:coffee_app/presentation/widgets/shimmers/base_shimmer.dart';
import 'package:flutter/material.dart';

class InventoryShimmer extends StatelessWidget {
  const InventoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: 8, // Show 8 shimmer items
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InventoryCardShimmer(),
        );
      },
    );
  }
}

class InventoryCardShimmer extends StatelessWidget {
  const InventoryCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      height: 100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Item image placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Item name
                  Container(
                    width: 140,
                    height: 18,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  const SizedBox(height: 6),
                  // Item category
                  Container(
                    width: 80,
                    height: 12,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  const SizedBox(height: 8),
                  // Quantity and price row
                  Row(
                    children: [
                      // Quantity
                      Container(
                        width: 60,
                        height: 14,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      const SizedBox(width: 16),
                      // Price
                      Container(
                        width: 50,
                        height: 14,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Stock indicator placeholder
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}