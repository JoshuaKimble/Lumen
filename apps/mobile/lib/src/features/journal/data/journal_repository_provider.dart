import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/supabase_config.dart';
import '../../auth/data/auth_session_controller.dart';
import '../domain/journal_repository.dart';
import 'hybrid_journal_repository.dart';
import 'journal_hydration_controller.dart';
import 'journal_sync_coordinator.dart';
import 'journal_sync_diagnostics_controller.dart';
import 'journal_repository_refresh_controller.dart';
import 'shared_preferences_journal_repository.dart';
import 'shared_preferences_journal_sync_queue_store.dart';
import 'supabase_journal_cloud_store.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final preferences = SharedPreferencesAsync();
  final supabaseConfig = ref.watch(supabaseClientConfigProvider);
  final userId = ref.watch(
    authSessionControllerProvider.select(
      (value) => value.asData?.value?.userId,
    ),
  );
  final localStore = SharedPreferencesJournalRepository(
    preferences: preferences,
  );

  if (!supabaseConfig.enabled) {
    return HybridJournalRepository(localStore: localStore);
  }

  final cloudStore = SupabaseJournalCloudStore(
    client: Supabase.instance.client,
  );
  final queueStore = SharedPreferencesJournalSyncQueueStore(
    preferences: preferences,
  );

  final syncCoordinator = JournalSyncCoordinator(
    queueStore: queueStore,
    cloudStore: cloudStore,
    currentUserId: () => userId,
    diagnosticsSink: ref.read(journalSyncDiagnosticsProvider.notifier),
  );
  final repository = HybridJournalRepository(
    localStore: localStore,
    cloudStore: cloudStore,
    syncCoordinator: syncCoordinator,
    hydrationController: JournalHydrationController(
      localStore: localStore,
      cloudStore: cloudStore,
      queueStore: queueStore,
      currentUserId: () => userId,
      onDataChanged: () {
        ref.read(journalRepositoryRefreshProvider.notifier).bump();
      },
    ),
  );
  unawaited(syncCoordinator.flushPendingWrites());
  unawaited(repository.hydrateFromCloud());
  return repository;
});
