import '../domain/resource_suggestion_service.dart';

abstract interface class ResourceFeedbackRepository {
  Future<Map<String, ResourceFeedbackAction>> loadAll();

  Future<void> save({
    required String resourceId,
    required ResourceFeedbackAction action,
  });
}
