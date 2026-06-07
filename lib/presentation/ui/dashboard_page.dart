import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lipo/presentation/ui/app_bar_widget.dart';
import 'package:provider/provider.dart';

import '../provider/clipboard_provider.dart';
import 'settings_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchFocusNode = FocusNode();
  bool _hotKeyDialogOpen = false;
  int _lastOverlayToken = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ClipboardProvider>();
    if (provider.overlayShowToken != _lastOverlayToken) {
      _lastOverlayToken = provider.overlayShowToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          provider.closeSettings();
          _searchFocusNode.requestFocus();
        }
      });
    }
    if (provider.shouldShowHotKeyDialog && !_hotKeyDialogOpen) {
      _hotKeyDialogOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const _HotKeySetupDialog(),
        );
        if (mounted) {
          setState(() {
            _hotKeyDialogOpen = false;
          });
        }
      });
    }

    return Scaffold(
      // appBar: buildPremiumAppBar(context),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.dark
                ? const [
                    Color(0xFF0C1220),
                    Color(0xFF0B1C26),
                    Color(0xFF0E0F16),
                  ]
                : const [
                    Color(0xFFF4F7FF),
                    Color(0xFFF6FAFF),
                    Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(
                      theme.brightness == Brightness.dark ? 0.55 : 0.75,
                    ),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(
                        theme.brightness == Brightness.dark ? 0.55 : 0.8,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        provider.showSettings
                            ? _PreferencesHeader(onBack: provider.closeSettings)
                            : buildPremiumAppBar(
                                context,
                                onSettingsPressed: provider.openSettings,
                              ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) {
                              final offsetTween = Tween<Offset>(
                                begin: const Offset(0.02, 0),
                                end: Offset.zero,
                              );
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: animation.drive(offsetTween),
                                  child: child,
                                ),
                              );
                            },
                            child: provider.showSettings
                                ? const SettingsPage()
                                : Column(
                                    key: const ValueKey('dashboard'),
                                    children: [
                                      _Header(
                                        controller: _searchController,
                                        focusNode: _searchFocusNode,
                                        onChanged: (value) => context
                                            .read<ClipboardProvider>()
                                            .setSearchQuery(value),
                                      ),
                                      const SizedBox(height: 10),
                                      Expanded(
                                        child: _Body(
                                          scrollController: _scrollController,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const _StatusBar(),
                                    ],
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
      ),
    );
  }
}

class _PreferencesHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const _PreferencesHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 52,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(
              theme.brightness == Brightness.dark ? 0.18 : 0.6,
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
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: onBack,
                ),
                Text(
                  'Preferences',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HotKeySetupDialog extends StatefulWidget {
  const _HotKeySetupDialog();

  @override
  State<_HotKeySetupDialog> createState() => _HotKeySetupDialogState();
}

class _HotKeySetupDialogState extends State<_HotKeySetupDialog> {
  final FocusNode _focusNode = FocusNode();

  int? _keyCode;
  bool _cmd = false;
  bool _alt = false;
  bool _ctrl = false;
  bool _shift = false;
  String _keyLabel = '';
  String? _error;

  bool get _hasValidSelection {
    if (_keyCode == null) return false;
    if (!(_cmd || _alt || _ctrl || _shift)) return false;
    if (_keyLabel.trim().isEmpty) return false;
    return true;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = _hasValidSelection ? _formatDisplay() : 'Press shortcut…';
    final canClose = context.read<ClipboardProvider>().hotKey != null;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      title: Row(
        children: [
          const Expanded(child: Text('Set Global Shortcut')),
          if (canClose)
            IconButton(
              tooltip: 'Close',
              onPressed: () {
                context.read<ClipboardProvider>().dismissHotKeySetup();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
      content: RawKeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKey: _onKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose the shortcut that will open Lipo from the menu bar.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    theme.brightness == Brightness.dark ? 0.30 : 0.55,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.85),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.keyboard_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        content,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tip: Use at least one modifier (⌘, ⌃, ⌥, ⇧).',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _hasValidSelection ? _save : null,
          child: const Text('Save Shortcut'),
        ),
      ],
    );
  }

  void _onKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;
    final data = event.data;
    if (data is! RawKeyEventDataMacOs) return;

    if (_isModifierOnly(event.logicalKey)) return;

    final cmd = event.isMetaPressed;
    final alt = event.isAltPressed;
    final ctrl = event.isControlPressed;
    final shift = event.isShiftPressed;

    final rawLabel = event.logicalKey.keyLabel;
    final label = rawLabel.isNotEmpty
        ? rawLabel.toUpperCase()
        : (event.logicalKey.debugName ?? 'KeyCode ${data.keyCode}');

    setState(() {
      _keyCode = data.keyCode;
      _cmd = cmd;
      _alt = alt;
      _ctrl = ctrl;
      _shift = shift;
      _keyLabel = label;
      _error = null;
      if (!(_cmd || _alt || _ctrl || _shift)) {
        _error = 'Please include at least one modifier.';
      }
    });
  }

  bool _isModifierOnly(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight;
  }

  String _formatDisplay() {
    final parts = <String>[];
    if (_cmd) parts.add('⌘');
    if (_ctrl) parts.add('⌃');
    if (_alt) parts.add('⌥');
    if (_shift) parts.add('⇧');
    parts.add(_keyLabel);
    return parts.join(' + ');
  }

  Future<void> _save() async {
    final keyCode = _keyCode;
    if (keyCode == null) return;

    final config = HotKeyConfig(
      keyCode: keyCode,
      cmd: _cmd,
      alt: _alt,
      ctrl: _ctrl,
      shift: _shift,
      display: _formatDisplay(),
    );

    final ok = await context.read<ClipboardProvider>().saveHotKey(config);
    if (!ok) {
      if (mounted) {
        setState(() {
          _error =
              'That shortcut could not be registered. Try a different one.';
        });
      }
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search clipboard history…',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Consumer<ClipboardProvider>(
      builder: (context, provider, _) {
        if (!provider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = provider.filteredItems;
        if (items.isEmpty) {
          return _EmptyState(hasQuery: provider.searchQuery.trim().isNotEmpty);
        }

        return Scrollbar(
          controller: scrollController,
          child: ListView.separated(
            // physics: ClampingScrollPhysics(),
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final wasCopied = provider.recentlyCopiedItemId == item.id;
              return _ClipboardRow(
                itemId: item.id,
                content: item.content,
                createdAt: item.createdAt,
                showCopied: wasCopied,
                onCopy: () => context.read<ClipboardProvider>().copyToClipboard(
                  item.content,
                  itemId: item.id,
                ),
                onDelete: () =>
                    context.read<ClipboardProvider>().deleteItem(item.id),
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasQuery ? Icons.search_off_rounded : Icons.content_paste_rounded,
              size: 42,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            const SizedBox(height: 10),
            Text(
              hasQuery ? 'No matches' : 'No clips yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery
                  ? 'Try a different search.'
                  : 'Copy something and it will show up here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.85),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClipboardRow extends StatefulWidget {
  const _ClipboardRow({
    required this.itemId,
    required this.content,
    required this.createdAt,
    required this.onCopy,
    required this.onDelete,
    required this.showCopied,
  });

  final int itemId;
  final String content;
  final DateTime createdAt;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final bool showCopied;

  @override
  State<_ClipboardRow> createState() => _ClipboardRowState();
}

class _ClipboardRowState extends State<_ClipboardRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surfaceContainerHighest.withOpacity(
      theme.brightness == Brightness.dark ? 0.35 : 0.55,
    );
    final surfaceHover = theme.colorScheme.surfaceContainerHighest.withOpacity(
      theme.brightness == Brightness.dark ? 0.48 : 0.67,
    );
    final border = theme.colorScheme.outlineVariant.withOpacity(
      theme.brightness == Brightness.dark ? 0.55 : 0.85,
    );

    return MouseRegion(
      onEnter: (_) {
        if (!mounted) return;
        if (_hovered) return;
        setState(() => _hovered = true);
      },
      onExit: (_) {
        if (!mounted) return;
        if (!_hovered) return;
        setState(() => _hovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _hovered ? surfaceHover : surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? theme.colorScheme.primary.withOpacity(0.45)
                : border,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: _hovered ? 20 : 10,
              offset: const Offset(0, 8),
              color: Colors.black.withOpacity(_hovered ? 0.16 : 0.10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onCopy,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _relativeTime(widget.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 140),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: widget.showCopied
                        ? _Badge(
                            label: 'Copied',
                            background: theme.colorScheme.primary,
                            foreground: theme.colorScheme.onPrimary,
                            icon: Icons.check_rounded,
                          )
                        : _hovered
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _Badge(
                                label: 'Copy',
                                background: theme.colorScheme.surface,
                                foreground: theme.colorScheme.onSurface,
                                icon: Icons.content_copy_rounded,
                                border: border,
                              ),
                              const SizedBox(width: 8),
                              _IconAction(
                                tooltip: 'Delete',
                                icon: Icons.delete_outline_rounded,
                                onPressed: widget.onDelete,
                              ),
                            ],
                          )
                        : const SizedBox(width: 0, height: 0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 18,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.85),
            ),
          ),
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
    this.border,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<ClipboardProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(
              theme.brightness == Brightness.dark ? 0.28 : 0.5,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.85),
            ),
          ),
          child: Row(
            children: [
              Text(
                '${provider.totalCount} saved',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: provider.totalCount == 0 ? null : provider.clearAll,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Clear All History'),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _relativeTime(DateTime input) {
  final now = DateTime.now();
  final diff = now.difference(input);

  if (diff.inSeconds < 10) return 'just now';
  if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

  final weeks = (diff.inDays / 7).floor();
  if (weeks < 4) return '${weeks}w ago';

  final months = (diff.inDays / 30).floor();
  if (months < 12) return '${months}mo ago';

  final years = (diff.inDays / 365).floor();
  return '${years}y ago';
}
