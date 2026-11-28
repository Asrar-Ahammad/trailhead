import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/navigation/app_navigator.dart';
import '../../../shared/theme/app_colors.dart';
import '../domain/shoes_repository_inventory.dart';
import '../state_management/shoes_bloc_edit_gear.dart';

Future<void> showShoeEditor(
  BuildContext context, {
  ShoeGear? shoe,
  bool? retire,
}) async {
  final createBloc = context.read<CreateShoeEditBloc>();
  await AppNavigator.dialog<void>(
    context,
    (_) => BlocProvider(
      create: (_) => createBloc(),
      child: _ShoeEditor(shoe, retire),
    ),
    barrierDismissible: false,
  );
}

class _ShoeEditor extends StatefulWidget {
  const _ShoeEditor(this.shoe, this.retire);
  final ShoeGear? shoe;
  final bool? retire;

  @override
  State<_ShoeEditor> createState() => _ShoeEditorState();
}

class _ShoeEditorState extends State<_ShoeEditor> {
  late String name = widget.shoe?.name ?? '';
  late String brand = widget.shoe?.brand ?? '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShoeEditBloc>().state;
    final colors = Theme.of(context).extension<AppColors>()!;
    final retire = widget.retire;
    final title = switch (retire) {
      true => 'Retire Shoe',
      false => 'Delete Shoe',
      null => widget.shoe == null ? 'Add New Shoe' : 'Edit Shoe',
    };
    return BlocListener<ShoeEditBloc, ShoeEditState>(
      listener: (context, state) {
        if (state.saved && ModalRoute.of(context)?.isCurrent == true) {
          AppNavigator.pop(context);
        }
      },
      child: AlertDialog(
        backgroundColor: colors.surface,
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (retire == null) ...[
              TextFormField(
                initialValue: name,
                enabled: !state.busy,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (value) => name = value,
              ),
              TextFormField(
                initialValue: brand,
                enabled: !state.busy,
                decoration: const InputDecoration(
                  labelText: 'Brand (optional)',
                ),
                onChanged: (value) => brand = value,
              ),
            ] else
              Text(
                retire
                    ? 'Retire this shoe from your active rotation?'
                    : 'Permanently delete this shoe?',
              ),
            if (state.error case final error?)
              Text(error, style: TextStyle(color: colors.error)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: state.busy ? null : () => AppNavigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (state.busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton(
              onPressed: () => context.read<ShoeEditBloc>().add(
                retire == null
                    ? SaveShoe(widget.shoe?.id, name, brand)
                    : RemoveShoe(widget.shoe!.id!, retire: retire),
              ),
              child: Text(
                retire == null
                    ? 'Save'
                    : retire
                    ? 'Retire'
                    : 'Delete',
              ),
            ),
        ],
      ),
    );
  }
}
