import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/app_settings.dart';
import '../provider/clipboard_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<ClipboardProvider>(
      builder: (context, provider, _) {
        final settings = provider.settings;
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          children: [
            _Section(
              title: 'Storage Limit',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${settings.maxItems} items',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: Slider(
                          value: settings.maxItems.clamp(10, 500).toDouble(),
                          min: 10,
                          max: 500,
                          divisions: 49,
                          onChanged: (value) => provider.setMaxItems(
                            value.round(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Automatically deletes oldest items when maximum capacity is exceeded.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Smart Clean Up',
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Auto purge',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<CleanupInterval>(
                      value: settings.cleanupInterval,
                      items: const [
                        DropdownMenuItem(
                          value: CleanupInterval.never,
                          child: Text('Never'),
                        ),
                        DropdownMenuItem(
                          value: CleanupInterval.daily,
                          child: Text('Every Day'),
                        ),
                        DropdownMenuItem(
                          value: CleanupInterval.weekly,
                          child: Text('Every Week'),
                        ),
                        DropdownMenuItem(
                          value: CleanupInterval.monthly,
                          child: Text('Every Month'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        provider.setCleanupInterval(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Theme Customization',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accent palette',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: provider.accentPalettes.map((palette) {
                      final selected =
                          settings.accentSeedColorValue == palette.seedColorValue;
                      return _ColorChip(
                        name: palette.name,
                        color: Color(palette.seedColorValue),
                        selected: selected,
                        onTap: () => provider.setAccentSeedColor(
                          palette.seedColorValue,
                        ),
                      );
                    }).toList(growable: false),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(
          theme.brightness == Brightness.dark ? 0.28 : 0.5,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.85),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.95),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.name,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(
            theme.brightness == Brightness.dark ? 0.35 : 0.65,
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withOpacity(0.7)
                : theme.colorScheme.outlineVariant.withOpacity(0.85),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    color: color.withOpacity(0.25),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
