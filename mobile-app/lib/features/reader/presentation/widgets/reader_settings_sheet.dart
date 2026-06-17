import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/theme/reader_theme.dart';
import 'package:akuko/features/reader/presentation/controllers/reader_settings_controller.dart';

/// Bottom sheet exposing reader typography + theme controls. Changes are
/// applied live and persisted via [ReaderSettingsController].
class ReaderSettingsSheet extends ConsumerWidget {
  const ReaderSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const ReaderSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readerSettingsProvider);
    final controller = ref.read(readerSettingsProvider.notifier);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Display settings', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),

            // Theme selector.
            Text('Theme', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<ReaderThemeMode>(
              segments: ReaderThemeMode.values
                  .map(
                    (m) => ButtonSegment(value: m, label: Text(m.label)),
                  )
                  .toList(),
              selected: {settings.themeMode},
              onSelectionChanged: (sel) =>
                  controller.setThemeMode(sel.first),
            ),
            const SizedBox(height: 20),

            // Font size.
            _SliderRow(
              label: 'Font size',
              value: settings.fontSize,
              min: ReaderSettings.minFontSize,
              max: ReaderSettings.maxFontSize,
              divisions: 20,
              valueLabel: settings.fontSize.toStringAsFixed(0),
              onChanged: controller.setFontSize,
            ),

            // Line spacing.
            _SliderRow(
              label: 'Line spacing',
              value: settings.lineSpacing,
              min: ReaderSettings.minLineSpacing,
              max: ReaderSettings.maxLineSpacing,
              divisions: 14,
              valueLabel: settings.lineSpacing.toStringAsFixed(1),
              onChanged: controller.setLineSpacing,
            ),
            const SizedBox(height: 12),

            // Font family.
            Text('Font', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ReaderSettings.availableFonts
                  .map(
                    (f) => ChoiceChip(
                      label: Text(f),
                      selected: settings.fontFamily == f,
                      onSelected: (_) => controller.setFontFamily(f),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            Text(valueLabel, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
