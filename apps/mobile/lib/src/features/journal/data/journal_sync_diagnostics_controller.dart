import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/journal_sync_diagnostics.dart';
import 'journal_sync_diagnostics_sink.dart';

final journalSyncDiagnosticsProvider =
    NotifierProvider<JournalSyncDiagnosticsController, JournalSyncDiagnostics>(
      JournalSyncDiagnosticsController.new,
    );

class JournalSyncDiagnosticsController extends Notifier<JournalSyncDiagnostics>
    implements JournalSyncDiagnosticsSink {
  @override
  JournalSyncDiagnostics build() {
    return const JournalSyncDiagnostics.idle();
  }

  @override
  JournalSyncDiagnostics get currentDiagnostics => state;

  @override
  void updateDiagnostics(JournalSyncDiagnostics diagnostics) {
    state = diagnostics;
  }
}
