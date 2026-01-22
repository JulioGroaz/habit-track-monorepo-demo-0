// Repository contract for applications to keep UI independent from storage.
// This exists to define CRUD and filter operations in one place.
// It fits in the app by powering the Applications screen.
import 'application.dart';

abstract class ApplicationRepository {
  Future<List<Application>> fetchApplications({
    ApplicationStatus? status,
    ApplicationSource? source,
    bool includeDeleted = false,
  });

  Future<Application?> fetchApplicationById(String id);

  Future<void> upsertApplication(Application application);

  Future<void> markApplicationDeleted(String id);
}
