import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../db/clipboard_item.dart';
import '../../db/database_service.dart';

class HotKeyConfig {
  const HotKeyConfig({
    required this.keyCode,
    required this.cmd,
    required this.alt,
    required this.ctrl,
    required this.shift,
    required this.display,
  });

  final int keyCode;
  final bool cmd;
  final bool alt;
  final bool ctrl;
  final bool shift;
  final String display;
}

class ClipboardProvider extends ChangeNotifier {
  ClipboardProvider({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;
  static const MethodChannel _hotKeyChannel = MethodChannel('lipo/hotkey');
  static const MethodChannel _windowChannel = MethodChannel('lipo/window');

  final List<ClipboardItem> _items = [];
  String _searchQuery = '';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Timer? _pollTimer;
  String? _lastClipboardText;
  bool _pollInFlight = false;

  HotKeyConfig? _hotKey;
  HotKeyConfig? get hotKey => _hotKey;

  bool _shouldShowHotKeyDialog = false;
  bool get shouldShowHotKeyDialog => _shouldShowHotKeyDialog;

  int? _recentlyCopiedItemId;
  DateTime? _recentlyCopiedUntil;
  int? get recentlyCopiedItemId =>
      (_recentlyCopiedUntil != null &&
          DateTime.now().isBefore(_recentlyCopiedUntil!))
      ? _recentlyCopiedItemId
      : null;

  List<ClipboardItem> get items => List.unmodifiable(_items);

  String get searchQuery => _searchQuery;

  List<ClipboardItem> get filteredItems {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return items;
    return _items
        .where((e) => e.content.toLowerCase().contains(query))
        .toList(growable: false);
  }

  int get totalCount => _items.length;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _databaseService.init();
    await _loadHotKey();
    await refresh();
    _startClipboardPolling();
    _isInitialized = true;
    notifyListeners();
  }

  void requestHotKeySetup() {
    _shouldShowHotKeyDialog = true;
    notifyListeners();
  }

  Future<bool> saveHotKey(HotKeyConfig config) async {
    if (!(config.cmd || config.alt || config.ctrl || config.shift)) {
      return false;
    }

    bool ok = false;
    try {
      ok =
          await _hotKeyChannel.invokeMethod<bool>('set', <String, dynamic>{
            'keyCode': config.keyCode,
            'cmd': config.cmd,
            'alt': config.alt,
            'ctrl': config.ctrl,
            'shift': config.shift,
          }) ==
          true;
    } catch (_) {
      ok = false;
    }
    if (!ok) return false;

    _hotKey = config;
    _shouldShowHotKeyDialog = false;
    notifyListeners();

    try {
      await _windowChannel.invokeMethod<void>('hide');
    } catch (_) {}
    return true;
  }

  Future<void> _loadHotKey() async {
    try {
      final result = await _hotKeyChannel.invokeMethod<Map>('get');
      if (result == null) {
        _hotKey = null;
        _shouldShowHotKeyDialog = true;
        return;
      }

      final keyCode = result['keyCode'];
      final modifiers = result['modifiers'];
      if (keyCode is! int || modifiers is! int) {
        _hotKey = null;
        _shouldShowHotKeyDialog = true;
        return;
      }

      const cmdKey = 1 << 8;
      const shiftKey = 1 << 9;
      const optionKey = 1 << 11;
      const controlKey = 1 << 12;

      final cmd = (modifiers & cmdKey) != 0;
      final shift = (modifiers & shiftKey) != 0;
      final alt = (modifiers & optionKey) != 0;
      final ctrl = (modifiers & controlKey) != 0;

      _hotKey = HotKeyConfig(
        keyCode: keyCode,
        cmd: cmd,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
        display: _formatHotKeyDisplay(
          cmd: cmd,
          alt: alt,
          ctrl: ctrl,
          shift: shift,
          keyLabel: 'KeyCode $keyCode',
        ),
      );
      _shouldShowHotKeyDialog = false;
    } catch (_) {
      _hotKey = null;
      _shouldShowHotKeyDialog = true;
    }
  }

  static String _formatHotKeyDisplay({
    required bool cmd,
    required bool alt,
    required bool ctrl,
    required bool shift,
    required String keyLabel,
  }) {
    final parts = <String>[];
    if (cmd) parts.add('⌘');
    if (ctrl) parts.add('⌃');
    if (alt) parts.add('⌥');
    if (shift) parts.add('⇧');
    parts.add(keyLabel);
    return parts.join(' + ');
  }

  Future<void> refresh() async {
    final all = await _databaseService.getAllItems();
    _items
      ..clear()
      ..addAll(all);
    notifyListeners();
  }

  void setSearchQuery(String value) {
    final next = value;
    if (next == _searchQuery) return;
    _searchQuery = next;
    notifyListeners();
  }

  Future<void> copyToClipboard(String text, {int? itemId}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (itemId != null) {
      _recentlyCopiedItemId = itemId;
      _recentlyCopiedUntil = DateTime.now().add(const Duration(seconds: 2));
      notifyListeners();
      Future<void>.delayed(const Duration(seconds: 2), () {
        notifyListeners();
      });
    }
  }

  Future<void> deleteItem(int id) async {
    await _databaseService.deleteItem(id);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _databaseService.clearAll();
    _items.clear();
    notifyListeners();
  }

  void _startClipboardPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_pollInFlight) return;
      _pollInFlight = true;
      try {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        final text = data?.text?.trim() ?? '';
        if (text.isEmpty) return;
        if (text == _lastClipboardText) return;
        _lastClipboardText = text;
        final saved = await _databaseService.saveItem(text);
        if (saved == null) return;
        _items.removeWhere((e) => e.id == saved.id);
        _items.insert(0, saved);
        notifyListeners();
      } catch (_) {
      } finally {
        _pollInFlight = false;
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
