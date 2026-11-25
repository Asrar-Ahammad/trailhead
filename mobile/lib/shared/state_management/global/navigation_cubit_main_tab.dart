import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/navigation/domain/navigation_entity_main_tab.dart';

/// Selected top-level tab shared between the home, run, and profile features.
class NavigationCubit extends Cubit<MainTab> {
  NavigationCubit() : super(MainTab.home);

  void selectTab(MainTab tab) {
    if (tab != state) emit(tab);
  }
}
