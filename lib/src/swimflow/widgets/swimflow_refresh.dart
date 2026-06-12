import 'package:flutter/material.dart';

class SwimflowRefreshableScroll extends StatelessWidget {
  const SwimflowRefreshableScroll({
    required this.onRefresh,
    required this.child,
    this.color,
    super.key,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: color,
      onRefresh: onRefresh,
      child: child,
    );
  }
}
