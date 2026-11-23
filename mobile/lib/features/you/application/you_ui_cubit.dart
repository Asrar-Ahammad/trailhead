import 'package:flutter_bloc/flutter_bloc.dart';

class YouUiState {
  const YouUiState({
    this.selectedActivityIds = const {},
    this.isDeleting = false,
    this.recordsMode = 'best_effort',
  });

  final Set<int> selectedActivityIds;
  final bool isDeleting;
  final String recordsMode;

  YouUiState copyWith({
    Set<int>? selectedActivityIds,
    bool? isDeleting,
    String? recordsMode,
  }) => YouUiState(
    selectedActivityIds: selectedActivityIds ?? this.selectedActivityIds,
    isDeleting: isDeleting ?? this.isDeleting,
    recordsMode: recordsMode ?? this.recordsMode,
  );
}

class YouUiCubit extends Cubit<YouUiState> {
  YouUiCubit() : super(const YouUiState());

  void setSelectedActivities(Set<int> ids) =>
      emit(state.copyWith(selectedActivityIds: Set.unmodifiable(ids)));

  void clearSelection() => emit(state.copyWith(selectedActivityIds: const {}));

  void setDeleting(bool value) => emit(state.copyWith(isDeleting: value));

  void setRecordsMode(String value) => emit(state.copyWith(recordsMode: value));
}
