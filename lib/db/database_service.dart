import 'dart:async';

import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'clipboard_item.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  late final Isar _isar;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    _isar = await Isar.open(
      [ClipboardItemSchema],
      directory: dir.path,
      name: 'lipo',
    );
    _isInitialized = true;
  }

  Future<List<ClipboardItem>> getAllItems() async {
    _ensureInitialized();
    return _isar.clipboardItems.where().sortByCreatedAtDesc().findAll();
  }

  Future<ClipboardItem?> saveItem(String text) async {
    _ensureInitialized();
    final normalized = text.trim();
    if (normalized.isEmpty) return null;

    return _isar.writeTxn(() async {
      final existing = await _isar.clipboardItems
          .filter()
          .contentEqualTo(normalized)
          .findFirst();

      if (existing != null) {
        existing.createdAt = DateTime.now();
        await _isar.clipboardItems.put(existing);
        return existing;
      }

      final item = ClipboardItem()
        ..content = normalized
        ..createdAt = DateTime.now();
      await _isar.clipboardItems.put(item);
      return item;
    });
  }

  Future<void> deleteItem(int id) async {
    _ensureInitialized();
    await _isar.writeTxn(() async {
      await _isar.clipboardItems.delete(id);
    });
  }

  Future<void> clearAll() async {
    _ensureInitialized();
    await _isar.writeTxn(() async {
      await _isar.clear();
    });
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('DatabaseService.init() must be called before use.');
    }
  }
}
