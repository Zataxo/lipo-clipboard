import 'dart:async';

import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'app_settings.dart';
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
      [ClipboardItemSchema, AppSettingsSchema],
      directory: dir.path,
      name: 'lipo',
    );
    _isInitialized = true;
  }

  Future<AppSettings> getSettings() async {
    _ensureInitialized();
    final existing = await _isar.appSettings.get(0);
    if (existing != null) return existing;

    final settings = AppSettings()..updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.appSettings.put(settings);
    });
    return settings;
  }

  Future<AppSettings> upsertSettings(AppSettings settings) async {
    _ensureInitialized();
    settings.id = 0;
    settings.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.appSettings.put(settings);
    });
    return settings;
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

  Future<void> clearHistory() async {
    _ensureInitialized();
    await _isar.writeTxn(() async {
      await _isar.clipboardItems.clear();
    });
  }

  Future<void> enforceStorageLimit(int maxItems) async {
    _ensureInitialized();
    if (maxItems <= 0) return;

    final count = await _isar.clipboardItems.count();
    if (count <= maxItems) return;

    final toDelete = count - maxItems;
    final oldest = await _isar.clipboardItems
        .where()
        .sortByCreatedAt()
        .limit(toDelete)
        .findAll();
    if (oldest.isEmpty) return;

    final ids = oldest.map((e) => e.id).toList(growable: false);
    await _isar.writeTxn(() async {
      await _isar.clipboardItems.deleteAll(ids);
    });
  }

  Future<void> purgeItemsOlderThan(DateTime cutoff) async {
    _ensureInitialized();
    final items = await _isar.clipboardItems
        .filter()
        .createdAtLessThan(cutoff)
        .findAll();
    if (items.isEmpty) return;
    final ids = items.map((e) => e.id).toList(growable: false);
    await _isar.writeTxn(() async {
      await _isar.clipboardItems.deleteAll(ids);
    });
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('DatabaseService.init() must be called before use.');
    }
  }
}
