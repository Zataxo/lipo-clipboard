import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../db/clipboard_item.dart';
import '../../db/database_service.dart';

class ClipboardProvider extends ChangeNotifier {
  ClipboardProvider({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  final List<ClipboardItem> _items = [];
  String _searchQuery = '';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Timer? _pollTimer;
  String? _lastClipboardText;
  bool _pollInFlight = false;

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
    await refresh();
    _startClipboardPolling();
    _isInitialized = true;
    notifyListeners();
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
