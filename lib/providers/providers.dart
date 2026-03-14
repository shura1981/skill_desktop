import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_helper.dart';
import '../models/person.dart';

/// Provides the full list of persons from SQLite.
/// Invalidate this provider after any mutation to force a reload.
final personsProvider = FutureProvider<List<Person>>((ref) async {
  return DatabaseHelper.instance.fetchAll();
});

/// Notifier that tracks which window title each secondary view should display.
/// Key = viewId, Value = window label (e.g. 'Ventana 1').
class WindowTitleNotifier extends Notifier<Map<int, String>> {
  @override
  Map<int, String> build() => {};

  void register(int viewId, String title) {
    state = {...state, viewId: title};
  }

  void unregister(int viewId) {
    state = Map.of(state)..remove(viewId);
  }

  String titleFor(int viewId) => state[viewId] ?? 'Ventana';
}

final windowTitleProvider =
    NotifierProvider<WindowTitleNotifier, Map<int, String>>(
      WindowTitleNotifier.new,
    );
