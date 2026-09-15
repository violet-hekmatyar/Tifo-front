import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

String normalizeSearchKeyword(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ');

final searchHistoryProvider = ChangeNotifierProvider<SearchHistoryStore>(
  (ref) => SearchHistoryStore(),
);

/// In-memory history for one app session. It intentionally never touches
/// token or preference storage.
final class SearchHistoryStore extends ChangeNotifier {
  SearchHistoryStore({this.maxEntries = 10});

  final int maxEntries;
  List<String> _items = const [];

  List<String> get items => _items;

  void add(String value) {
    final keyword = normalizeSearchKeyword(value);
    if (keyword.isEmpty) return;
    _items = [
      keyword,
      ..._items.where((item) => item != keyword),
    ].take(maxEntries).toList(growable: false);
    notifyListeners();
  }

  void remove(String value) {
    final next = _items.where((item) => item != value).toList(growable: false);
    if (next.length == _items.length) return;
    _items = next;
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items = const [];
    notifyListeners();
  }
}
