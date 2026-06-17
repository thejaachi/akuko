import 'package:flutter/material.dart';

/// Consistent vertical gap between home sections.
class SectionSpacer extends StatelessWidget {
  const SectionSpacer({this.height = 24, super.key});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}
