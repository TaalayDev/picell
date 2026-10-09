import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'error_report_service.dart';

/// Provider errors may be displayed as AsyncError instead of reaching Flutter's
/// uncaught error handlers. Never attach provider arguments or state contents.
class ErrorReportObserver extends ProviderObserver {
  @override
  void providerDidFail(ProviderBase<Object?> provider, Object error,
      StackTrace stackTrace, ProviderContainer container) {
    ErrorReportService.instance.report(error, stackTrace,
        operation: 'provider.${provider.name ?? provider.runtimeType}');
  }
}
