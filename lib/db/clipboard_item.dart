import 'package:isar_community/isar.dart';

part 'clipboard_item.g.dart';

@collection
class ClipboardItem {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.hash)
  late String content;

  @Index()
  late DateTime createdAt;
}
