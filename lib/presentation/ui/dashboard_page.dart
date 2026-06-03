import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/clipboard_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
                        _Header(
                          controller: _searchController,
                          onChanged: (value) => context
                              .read<ClipboardProvider>()
                              .setSearchQuery(value),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: _Body(scrollController: _scrollController),
                        ),
                        const SizedBox(height: 10),
                        const _StatusBar(),
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

class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
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
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
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
                            key: const ValueKey('copied'),
                            label: 'Copied',
                            background: theme.colorScheme.primary,
                            foreground: theme.colorScheme.onPrimary,
                            icon: Icons.check_rounded,
                          )
                        : _hovered
                        ? Row(
                            key: const ValueKey('hover-actions'),
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
                        : const SizedBox(
                            key: ValueKey('idle'),
                            width: 0,
                            height: 0,
                          ),
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
