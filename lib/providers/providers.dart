import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/config/constants.dart';
import 'package:picell/data/auth_interceptor.dart';

import '../core.dart';
import '../core/utils/api_client.dart';
import '../core/services/in_app_review_service.dart';
import '../data.dart';
import '../data/repo/auth_api_repo.dart';
import '../data/repo/project_api_repo.dart';
import '../data/repo/template_api_repo.dart';
import '../pixel/services/template_service.dart';

final analyticsProvider = Provider((ref) => FirebaseAnalytics.instance);
final databaseProvider = Provider((ref) => AppDatabase());
final queueManagerProvider = Provider((ref) => QueueManager());
final projectRepo = Provider<ProjectRepo>((ref) => ProjectLocalRepo(
      ref.read(databaseProvider),
      ref.read(queueManagerProvider),
    ));

final inAppReviewProvider = Provider<InAppReviewService>((ref) {
  return InAppReviewService();
});

final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    Constants.baseUrl,
    storage: ref.read(localStorageProvider),
    interceptors: [AuthInterceptor(ref.read(localStorageProvider))],
  );
});

final authAPIRepoProvider = Provider<AuthAPIRepo>((ref) {
  return AuthAPIRepo(
    ref.read(apiClientProvider),
    ref.read(localStorageProvider),
  );
});

final projectAPIRepoProvider = Provider<ProjectAPIRepo>((ref) {
  return ProjectAPIRepo(ref.read(apiClientProvider));
});

final templateAPIRepoProvider = Provider<TemplateAPIRepo>((ref) {
  return TemplateAPIRepo(ref.read(apiClientProvider));
});

final templateServiceProvider = Provider<TemplateService>((ref) {
  return TemplateService(ref.read(templateAPIRepoProvider));
});
