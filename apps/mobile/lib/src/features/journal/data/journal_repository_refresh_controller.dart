import 'package:flutter_riverpod/flutter_riverpod.dart';

final journalRepositoryRefreshProvider =
    NotifierProvider<JournalRepositoryRefreshController, int>(
      JournalRepositoryRefreshController.new,
    );

class JournalRepositoryRefreshController extends Notifier<int> {
  @override
  int build() => 0;

  void bump() {
    state = state + 1;
  }
}
