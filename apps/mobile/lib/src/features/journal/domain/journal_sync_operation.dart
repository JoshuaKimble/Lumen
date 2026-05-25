import 'package:flutter/foundation.dart';

import 'journal_entry.dart';

enum JournalSyncOperationType { upsert, delete }

@immutable
class JournalSyncOperation {
  const JournalSyncOperation({
    required this.queueKey,
    required this.userId,
    required this.entryId,
    required this.type,
    required this.enqueuedAt,
    required this.nextAttemptAt,
    required this.attemptCount,
    this.entry,
    this.lastErrorMessage,
  });

  final String queueKey;
  final String userId;
  final String entryId;
  final JournalSyncOperationType type;
  final JournalEntry? entry;
  final DateTime enqueuedAt;
  final DateTime nextAttemptAt;
  final int attemptCount;
  final String? lastErrorMessage;

  bool get isDue => !nextAttemptAt.isAfter(DateTime.now().toUtc());

  JournalSyncOperation copyWith({
    JournalSyncOperationType? type,
    JournalEntry? entry,
    DateTime? enqueuedAt,
    DateTime? nextAttemptAt,
    int? attemptCount,
    String? lastErrorMessage,
    bool clearLastErrorMessage = false,
  }) {
    return JournalSyncOperation(
      queueKey: queueKey,
      userId: userId,
      entryId: entryId,
      type: type ?? this.type,
      entry: entry ?? this.entry,
      enqueuedAt: enqueuedAt ?? this.enqueuedAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastErrorMessage: clearLastErrorMessage
          ? null
          : lastErrorMessage ?? this.lastErrorMessage,
    );
  }

  static String queueKeyFor({required String userId, required String entryId}) {
    return '$userId:$entryId';
  }
}
