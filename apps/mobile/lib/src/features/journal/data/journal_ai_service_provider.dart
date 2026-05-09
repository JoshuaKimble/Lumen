import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/journal_ai_service.dart';
import 'mock_journal_ai_service.dart';

final journalAiServiceProvider = Provider<JournalAiService>((ref) {
  return const MockJournalAiService();
});
