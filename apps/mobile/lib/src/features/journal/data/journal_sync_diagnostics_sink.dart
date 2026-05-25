import '../domain/journal_sync_diagnostics.dart';

abstract interface class JournalSyncDiagnosticsSink {
  JournalSyncDiagnostics get currentDiagnostics;

  void updateDiagnostics(JournalSyncDiagnostics diagnostics);
}
