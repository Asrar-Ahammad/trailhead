import 'package:flutter_bloc/flutter_bloc.dart';

/// Selected top-level tab shared between the home, run, and profile features.
class NavigationCubit extends Cubit<int> {
  NavigationCubit() : super(0);

  void selectTab(int index) {
    if (index < 0 || index > 2 || index == state) return;
    emit(index);
  }
}
