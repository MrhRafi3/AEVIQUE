import 'dart:typed_data';
import '../core/models/edit_state.dart';

class RecentEditItem {
  final String id;
  final String name;
  final Uint8List imageBytes;
  final EditState state;
  final DateTime updatedAt;

  RecentEditItem({
    required this.id,
    required this.name,
    required this.imageBytes,
    required this.state,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();
}

abstract class RecentEditsRepository {
  List<RecentEditItem> getRecentEdits();
  void addEdit(RecentEditItem item);
  void clear();
}

class InMemoryRecentEditsRepository implements RecentEditsRepository {
  static final InMemoryRecentEditsRepository _instance =
      InMemoryRecentEditsRepository._internal();
  factory InMemoryRecentEditsRepository() => _instance;
  InMemoryRecentEditsRepository._internal();

  final List<RecentEditItem> _edits = [];

  @override
  List<RecentEditItem> getRecentEdits() => List.unmodifiable(_edits);

  @override
  void addEdit(RecentEditItem item) {
    _edits.removeWhere((e) => e.id == item.id);
    _edits.insert(0, item);
    if (_edits.length > 10) {
      _edits.removeLast();
    }
  }

  @override
  void clear() {
    _edits.clear();
  }
}
