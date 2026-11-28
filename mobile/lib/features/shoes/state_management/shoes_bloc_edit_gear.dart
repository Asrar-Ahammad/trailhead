import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/shoes_use_case_manage_gear.dart';

typedef CreateShoeEditBloc = ShoeEditBloc Function();
typedef ShoeEditState = ({bool busy, bool saved, String? error});

sealed class ShoeEdit {
  const ShoeEdit();
}

final class SaveShoe extends ShoeEdit {
  const SaveShoe(this.id, this.name, this.brand);
  final int? id;
  final String name;
  final String? brand;
}

final class RemoveShoe extends ShoeEdit {
  const RemoveShoe(this.id, {required this.retire});
  final int id;
  final bool retire;
}

final class SetShoePhoto extends ShoeEdit {
  const SetShoePhoto(this.id, this.sourcePath);
  final int id;
  final String sourcePath;
}

class ShoeEditBloc extends Bloc<ShoeEdit, ShoeEditState> {
  ShoeEditBloc(ShoeService service, void Function(String?) selectShoe)
    : super((busy: false, saved: false, error: null)) {
    on<ShoeEdit>((event, emit) async {
      if (state.busy) return;
      emit((busy: true, saved: false, error: null));
      try {
        switch (event) {
          case SaveShoe(:final id, :final name, :final brand):
            if (id == null) {
              final shoe = await service.addShoe(name, brand);
              selectShoe(shoe.clientShoeId);
            } else if (await service.updateShoe(id, name: name, brand: brand) ==
                null) {
              throw StateError('Shoe no longer exists');
            }
          case RemoveShoe(:final id, :final retire):
            if (retire) {
              await service.retireShoe(id);
            } else {
              await service.deleteShoe(id);
            }
          case SetShoePhoto(:final id, :final sourcePath):
            await service.updatePhoto(id, sourcePath);
        }
        emit((busy: false, saved: true, error: null));
      } on FormatException catch (error) {
        emit((busy: false, saved: false, error: error.message));
      } catch (_) {
        emit((
          busy: false,
          saved: false,
          error: event is SetShoePhoto
              ? 'Could not update shoe photo.'
              : 'Could not update gear. Please try again.',
        ));
      }
    });
  }
}
