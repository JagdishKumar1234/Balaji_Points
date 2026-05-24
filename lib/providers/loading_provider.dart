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

extension LoadingControllerExtension on WidgetRef {
  void startLoading() => read(loadingProvider.notifier).start();
  void stopLoading() => read(loadingProvider.notifier).stop();
}
