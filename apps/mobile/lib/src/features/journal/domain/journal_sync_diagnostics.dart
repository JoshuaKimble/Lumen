import 'package:flutter/foundation.dart';

@immutable
class JournalSyncDiagnostics {
  const JournalSyncDiagnostics({
    required this.pendingOperationCount,
    required this.isSyncInProgress,
    this.lastAttemptedAt,
    this.lastSuccessfulSyncAt,
    this.lastFailureAt,
    this.lastFailureMessage,
    this.nextScheduledRetryAt,
  });

  const JournalSyncDiagnostics.idle()
    : pendingOperationCount = 0,
      isSyncInProgress = false,
      lastAttemptedAt = null,
      lastSuccessfulSyncAt = null,
      lastFailureAt = null,
      lastFailureMessage = null,
      nextScheduledRetryAt = null;

  final int pendingOperationCount;
  final bool isSyncInProgress;
  final DateTime? lastAttemptedAt;
  final DateTime? lastSuccessfulSyncAt;
  final DateTime? lastFailureAt;
  final String? lastFailureMessage;
  final DateTime? nextScheduledRetryAt;

  JournalSyncDiagnostics copyWith({
    int? pendingOperationCount,
    bool? isSyncInProgress,
    DateTime? lastAttemptedAt,
    DateTime? lastSuccessfulSyncAt,
    DateTime? lastFailureAt,
    String? lastFailureMessage,
    DateTime? nextScheduledRetryAt,
    bool clearLastSuccessfulSyncAt = false,
    bool clearLastFailure = false,
    bool clearNextScheduledRetryAt = false,
  }) {
    return JournalSyncDiagnostics(
      pendingOperationCount:
          pendingOperationCount ?? this.pendingOperationCount,
      isSyncInProgress: isSyncInProgress ?? this.isSyncInProgress,
      lastAttemptedAt: lastAttemptedAt ?? this.lastAttemptedAt,
      lastSuccessfulSyncAt: clearLastSuccessfulSyncAt
          ? null
          : lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      lastFailureAt: clearLastFailure
          ? null
          : lastFailureAt ?? this.lastFailureAt,
      lastFailureMessage: clearLastFailure
          ? null
          : lastFailureMessage ?? this.lastFailureMessage,
      nextScheduledRetryAt: clearNextScheduledRetryAt
          ? null
          : nextScheduledRetryAt ?? this.nextScheduledRetryAt,
    );
  }
}
