import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoadingNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void start() => state = state + 1;
  void stop() => state = state > 0 ? state - 1 : 0;
  bool get isLoading => state > 0;
}

final loadingProvider = NotifierProvider<LoadingNotifier, int>(
  () => LoadingNotifier(),
);

/// Optional text under the global loader ("Logging out…").
class LoadingMessageNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? message) => state = message;
}

final loadingMessageProvider =
    NotifierProvider<LoadingMessageNotifier, String?>(
      LoadingMessageNotifier.new,
    );

extension LoadingControllerExtension on WidgetRef {
  void startLoading() => read(loadingProvider.notifier).start();
  void stopLoading() => read(loadingProvider.notifier).stop();

  /// Shows the global loader (with [message]) while [job] runs, and always
  /// hides it afterwards, even if [job] navigates away (the screen that
  /// started it is gone by then) or throws.
  Future<T> withLoader<T>(Future<T> Function() job, {String? message}) async {
    final loader = read(loadingProvider.notifier);
    final text = read(loadingMessageProvider.notifier);
    text.set(message);
    loader.start();
    try {
      return await job();
    } finally {
      loader.stop();
      if (!loader.isLoading) text.set(null);
    }
  }
}
