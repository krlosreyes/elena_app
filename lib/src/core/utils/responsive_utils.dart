import 'package:flutter/material.dart';

double getAdaptiveSize(BuildContext context, double baseMobile,
    {double? baseWeb}) {
  final width = MediaQuery.of(context).size.width;

  // Base widths for interpolation
  const double mobileWidth = 375.0;
  const double webWidth = 600.0;

  // Default to a 1.25x scaling factor if baseWeb is not provided
  final double targetWeb = baseWeb ?? (baseMobile * 1.25);

  if (width <= mobileWidth) return baseMobile;
  if (width >= webWidth) return targetWeb;

  // Linear interpolation between mobile and web
  final double t = (width - mobileWidth) / (webWidth - mobileWidth);
  return baseMobile + (targetWeb - baseMobile) * t;
}

double getRelativeHeight(BuildContext context, double percentage) {
  return MediaQuery.of(context).size.height * percentage;
}

double getRelativeWidth(BuildContext context, double percentage) {
  return MediaQuery.of(context).size.width * percentage;
}
