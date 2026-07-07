import 'package:flutter/material.dart';

/// A delegate for SliverPersistentHeader that allows custom min/max extent.
///
/// Use this to create sticky headers, collapsing app bars, and
/// persistent UI elements in CustomScrollView.
class SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

/// A variant that supports opacity transitions
class FadingSliverDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;
  final Widget? collapsedChild;

  FadingSliverDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
    this.collapsedChild,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = shrinkOffset / (maxExtent - minExtent);
    final clampedProgress = progress.clamp(0.0, 1.0);

    if (collapsedChild == null) {
      return Opacity(
        opacity: 1 - clampedProgress,
        child: SizedBox.expand(child: child),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(opacity: 1 - clampedProgress, child: child),
        Opacity(opacity: clampedProgress, child: collapsedChild),
      ],
    );
  }

  @override
  bool shouldRebuild(FadingSliverDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child ||
        collapsedChild != oldDelegate.collapsedChild;
  }
}
