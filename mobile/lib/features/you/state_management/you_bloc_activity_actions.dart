import 'package:flutter_bloc/flutter_bloc.dart';

typedef CreateYouBloc = YouBloc Function();

enum RecordsMode { bestEffort, manual }

typedef YouState = ({
  Set<int> selected,
  bool deleting,
  RecordsMode mode,
  String? error,
});

sealed class YouEvent {
  const YouEvent();
}

final class ToggleActivitySelection extends YouEvent {
  const ToggleActivitySelection(this.id);
  final int id;
}

final class ClearActivitySelection extends YouEvent {
  const ClearActivitySelection();
}

final class DeleteSelectedActivities extends YouEvent {
  const DeleteSelectedActivities();
}

final class ChangeRecordsMode extends YouEvent {
  const ChangeRecordsMode(this.mode);
  final RecordsMode mode;
}

class YouBloc extends Bloc<YouEvent, YouState> {
  YouBloc(Future<void> Function(Set<int>) delete)
    : super((
        selected: const {},
        deleting: false,
        mode: RecordsMode.bestEffort,
        error: null,
      )) {
    on<YouEvent>((event, emit) async {
      if (event is ChangeRecordsMode) {
        emit((
          selected: state.selected,
          deleting: state.deleting,
          mode: event.mode,
          error: null,
        ));
        return;
      }
      if (state.deleting) return;
      switch (event) {
        case ToggleActivitySelection(:final id):
          final selected = {...state.selected};
          if (!selected.add(id)) selected.remove(id);
          emit((
            selected: Set.unmodifiable(selected),
            deleting: false,
            mode: state.mode,
            error: null,
          ));
        case ClearActivitySelection():
          emit((
            selected: const {},
            deleting: false,
            mode: state.mode,
            error: null,
          ));
        case DeleteSelectedActivities():
          final selected = state.selected;
          if (selected.isEmpty) return;
          emit((
            selected: selected,
            deleting: true,
            mode: state.mode,
            error: null,
          ));
          try {
            await delete(selected);
            emit((
              selected: const {},
              deleting: false,
              mode: state.mode,
              error: null,
            ));
          } catch (_) {
            emit((
              selected: selected,
              deleting: false,
              mode: state.mode,
              error: 'Could not delete activities.',
            ));
          }
        case ChangeRecordsMode():
          break;
      }
    });
  }
}
