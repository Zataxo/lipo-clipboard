import 'package:isar_community/isar.dart';

part 'app_settings.g.dart';

enum CleanupInterval {
  never,
  daily,
  weekly,
  monthly,
}

@collection
class AppSettings {
  Id id = 0;

  int maxItems = 100;

  @enumerated
  CleanupInterval cleanupInterval = CleanupInterval.never;

  int accentSeedColorValue = 0xFF4F8CFF;

  DateTime updatedAt = DateTime.fromMillisecondsSinceEpoch(0);
}
