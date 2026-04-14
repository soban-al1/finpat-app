import 'package:finpat_mobile/app/app_state.dart';
import 'package:flutter/widgets.dart';

class AppScope extends InheritedNotifier<AppStateController> {
  const AppScope({
    super.key,
    required AppStateController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppStateController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}
