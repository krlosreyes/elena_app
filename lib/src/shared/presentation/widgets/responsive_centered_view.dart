import 'package:flutter/material.dart';

class ResponsiveCenteredView extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenteredView({
    super.key,
    required this.child,
    this.maxWidth = 600, // Default width suitable for most forms/dashboards
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
