import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

//Welcome to Lip
//Versio 1.3.5
//New Setting page
//Theme configuration
//Auto Purge and data cleanup
//New limit configuration
//
const _appName = 'Lipo';
final Future<PackageInfo> _packageInfoFuture = PackageInfo.fromPlatform();

PreferredSizeWidget buildPremiumAppBar(
  BuildContext context, {
  required VoidCallback onSettingsPressed,
}) {
  final theme = Theme.of(context);

  return PreferredSize(
    preferredSize: const Size.fromHeight(52),

    child: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),

        child: Container(
          height: 52,
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: theme.brightness == Brightness.dark
                  ? const [
                      Color(0xFF0B1C26),
                      Color(0xFF0E0F16),
                      Color(0xFF0C1220),
                    ]
                  : const [
                      Color(0xFFF6FAFF),
                      Color(0xFFF4F7FF),
                      Color(0xFFFFFFFF),
                    ],
            ),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withOpacity(
                  theme.brightness == Brightness.dark ? 0.40 : 0.70,
                ),
                width: 1,
              ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primary.withOpacity(0.95),
                                theme.colorScheme.primary.withOpacity(0.55),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _appName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(
                              theme.brightness == Brightness.dark ? 0.30 : 0.55,
                            ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withOpacity(
                            theme.brightness == Brightness.dark ? 0.45 : 0.75,
                          ),
                        ),
                      ),
                      child: FutureBuilder<PackageInfo>(
                        future: _packageInfoFuture,
                        builder: (context, snapshot) {
                          final version = snapshot.data?.version ?? '';
                          return Text(
                            version.isEmpty ? 'v' : 'v$version',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.9),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Tooltip(
                      message: 'Preferences',
                      child: InkResponse(
                        onTap: onSettingsPressed,
                        radius: 18,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withOpacity(
                                  theme.brightness == Brightness.dark
                                      ? 0.28
                                      : 0.55,
                                ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withOpacity(
                                    theme.brightness == Brightness.dark
                                        ? 0.45
                                        : 0.75,
                                  ),
                            ),
                          ),
                          child: Icon(
                            Icons.settings_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.9),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
