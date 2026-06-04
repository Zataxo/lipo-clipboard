import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

const _appName = 'Lipo';
const _appVersion = '1.2.4';
PreferredSizeWidget buildPremiumAppBar(BuildContext context) {
  final theme = Theme.of(context);

  return PreferredSize(
    preferredSize: const Size.fromHeight(52),

    child: ClipRect(
      child: BackdropFilter(
        // Blurs whatever content scrolls underneath the header
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
            borderRadius: BorderRadius.circular(8),
            // border: Border(
            //   bottom: BorderSide(
            //     color: theme.colorScheme.outlineVariant.withOpacity(
            //       theme.brightness == Brightness.dark ? 0.40 : 0.70,
            //     ),
            //     width: 1,
            //   ),
            // ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      //Welcome to Lipo
                      //Light weight Clipboard Manager
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
                    child: Text(
                      'v$_appVersion',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.9,
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
  );
}
