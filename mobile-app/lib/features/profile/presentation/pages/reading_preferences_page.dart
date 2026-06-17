import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/features/auth/presentation/controllers/auth_controller.dart';
import 'package:akuko/features/books/data/curated_home_content.dart';
import 'package:akuko/features/profile/presentation/controllers/profile_providers.dart';
import 'package:akuko/features/reader/presentation/controllers/reader_interaction_preferences.dart';
import 'package:akuko/features/reader/presentation/widgets/reader_settings_sheet.dart';

/// Reading preferences — display, interaction, and genre onboarding.
class ReadingPreferencesPage extends ConsumerStatefulWidget {
  const ReadingPreferencesPage({super.key});

  @override
  ConsumerState<ReadingPreferencesPage> createState() =>
      _ReadingPreferencesPageState();
}

class _ReadingPreferencesPageState extends ConsumerState<ReadingPreferencesPage> {
  final Set<String> _selectedGenres = {};
  bool _savingGenres = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGenres());
  }

  void _loadGenres() {
    final prefs =
        ref.read(currentProfileProvider).valueOrNull?.readingPreferences;
    final genres = prefs?['favorite_genres'];
    if (genres is List) {
      _selectedGenres
        ..clear()
        ..addAll(genres.map((e) => e.toString()));
      setState(() {});
    }
  }

  Future<void> _saveGenres() async {
    if (_selectedGenres.length < 5) {
      context.showSnack('Select at least 5 favorite genres');
      return;
    }
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;

    setState(() => _savingGenres = true);
    try {
      final existing = Map<String, dynamic>.from(
        ref.read(currentProfileProvider).valueOrNull?.readingPreferences ??
            const {},
      );
      existing['favorite_genres'] = _selectedGenres.toList();
      final result = await ref
          .read(profileRepositoryProvider)
          .updateReadingPreferences(userId, existing);
      result.fold(
        (f) {
          if (mounted) context.showSnack(f.message);
        },
        (_) {
          ref.invalidate(currentProfileProvider);
          if (mounted) context.showSnack('Genre preferences saved');
        },
      );
    } finally {
      if (mounted) setState(() => _savingGenres = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final interaction = ref.watch(readerInteractionPreferencesProvider);
    final interactionCtrl =
        ref.read(readerInteractionPreferencesProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Reading Preferences')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Display settings'),
            subtitle: const Text('Font, spacing, and reader theme'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ReaderSettingsSheet.show(context),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Volume keys page turn'),
            subtitle: const Text('Use device volume up/down to turn pages'),
            value: interaction.volumeKeysEnabled,
            activeColor: AppColors.forestGreen,
            onChanged: interactionCtrl.setVolumeKeysEnabled,
          ),
          SwitchListTile(
            title: const Text('Touch boundary page turn'),
            subtitle: const Text('Tap left/right screen edges to turn pages'),
            value: interaction.touchTurnEnabled,
            activeColor: AppColors.forestGreen,
            onChanged: interactionCtrl.setTouchTurnEnabled,
          ),
          const SizedBox(height: 16),
          Text(
            'Favorite genres (min 5)',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CuratedHomeContent.curatedGenres.map((genre) {
              final selected = _selectedGenres.contains(genre.name);
              return FilterChip(
                label: Text(genre.name),
                selected: selected,
                selectedColor: AppColors.burntSienna.withOpacity(0.25),
                checkmarkColor: AppColors.burntSienna,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedGenres.add(genre.name);
                    } else {
                      _selectedGenres.remove(genre.name);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _savingGenres ? null : _saveGenres,
            child: _savingGenres
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Save genres (${_selectedGenres.length}/5+)'),
          ),
        ],
      ),
    );
  }
}
