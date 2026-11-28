import 'package:flutter_test/flutter_test.dart';
import 'package:trailhead_mobile/features/shoes/domain/shoes_repository_inventory.dart';
import 'package:trailhead_mobile/features/shoes/domain/shoes_use_case_manage_gear.dart';
import 'package:trailhead_mobile/features/shoes/state_management/shoes_bloc_edit_gear.dart';

class FakeShoesRepository implements ShoesRepository {
  final shoes = <int, ShoeGear>{};
  @override
  Stream<List<ShoeGear>> watchAll() => Stream.value(shoes.values.toList());
  @override
  Future<List<ShoeGear>> getActiveShoes() async =>
      shoes.values.where((shoe) => shoe.isActive).toList();
  @override
  Future<ShoeGear> add(ShoeGear shoe) async =>
      shoes[shoe.id ?? shoes.length + 1] = shoe;
  @override
  Future<ShoeGear?> update(int id, ShoeGear Function(ShoeGear) change) async {
    final shoe = shoes[id];
    return shoe == null ? null : shoes[id] = change(shoe);
  }

  @override
  Future<void> delete(int id) async {
    shoes.remove(id);
  }
}

void main() {
  test('gear edit reports an invalid name and permits a valid retry', () async {
    final repository = FakeShoesRepository();
    final service = ShoeService(
      repository,
      newClientId: () => 'new-id',
      preparePhoto: (_) async => null,
    );
    final selections = <String?>[];
    final bloc = ShoeEditBloc(service, selections.add);
    addTearDown(bloc.close);
    final invalid = bloc.stream.firstWhere((state) => state.error != null);
    bloc.add(const SaveShoe(null, '   ', null));
    expect((await invalid).error, 'Enter a shoe name.');
    expect(repository.shoes, isEmpty);
    final saved = bloc.stream.firstWhere((state) => state.saved);
    bloc.add(const SaveShoe(null, ' Ghost ', ' Brooks '));
    await saved;
    expect(repository.shoes.values.single.name, 'Ghost');
    expect(selections, ['new-id']);
  });

  test('history resolves client IDs before legacy numeric database IDs', () {
    const inventory = [
      ShoeGear(id: 8, clientShoeId: 'uuid'),
      ShoeGear(id: 9, clientShoeId: '8'),
    ];
    expect(findTrackedShoe(inventory, '8')?.id, 9);
    expect(findTrackedShoe(inventory, '9')?.id, 9);
    expect(findTrackedShoe(inventory, 'unknown'), isNull);
  });
  group('ShoeService - Edit Shoe Name and Company', () {
    late FakeShoesRepository repository;
    late ShoeService shoeService;

    setUp(() {
      repository = FakeShoesRepository();
      shoeService = ShoeService(
        repository,
        newClientId: () => 'new-shoe',
        preparePhoto: (_) async => null,
      );
    });

    test('updateShoe updates name and company (brand) successfully', () async {
      final initialShoe = ShoeGear(
        id: 1,
        clientShoeId: 'test-shoe-1',
        name: 'Pegasus 39',
        brand: 'Nike',
        distanceM: 15000,
        isActive: true,
      );
      await repository.add(initialShoe);

      final updatedShoe = await shoeService.updateShoe(
        1,
        name: 'Pegasus 40',
        brand: 'Nike Running',
      );

      expect(updatedShoe, isNotNull);
      expect(updatedShoe!.name, equals('Pegasus 40'));
      expect(updatedShoe.brand, equals('Nike Running'));
      expect(updatedShoe.distanceM, equals(15000)); // preserves existing stats

      // Verify persistence in repository
      final persisted = repository.shoes[1];
      expect(persisted?.name, equals('Pegasus 40'));
      expect(persisted?.brand, equals('Nike Running'));
    });

    test(
      'updateShoe trims whitespace and sets empty company to null',
      () async {
        final initialShoe = ShoeGear(
          id: 2,
          clientShoeId: 'test-shoe-2',
          name: 'Clifton 9',
          brand: 'Hoka',
          isActive: true,
        );
        await repository.add(initialShoe);

        final updatedShoe = await shoeService.updateShoe(
          2,
          name: 'Clifton 9 Wide',
          brand: '   ',
        );

        expect(updatedShoe, isNotNull);
        expect(updatedShoe!.name, equals('Clifton 9 Wide'));
        expect(updatedShoe.brand, isNull);
      },
    );

    test('updateShoe returns null if shoe does not exist', () async {
      final result = await shoeService.updateShoe(
        999,
        name: 'Ghost 15',
        brand: 'Brooks',
      );

      expect(result, isNull);
    });
  });
}
