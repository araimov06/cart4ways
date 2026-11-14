import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// onChange fires for Cubit AND Bloc (state -> state).
/// onTransition fires only for Bloc and adds the EVENT that caused the change.
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    debugPrint('[onChange] ${bloc.runtimeType}: ${change.currentState} -> ${change.nextState}');
  }

  @override
  void onTransition(Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> t) {
    super.onTransition(bloc, t);
    debugPrint('[onTransition] ${bloc.runtimeType}: ${t.event.runtimeType} '
        '| ${t.currentState} -> ${t.nextState}');
  }
}
