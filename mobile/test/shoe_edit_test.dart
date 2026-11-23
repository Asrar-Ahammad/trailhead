import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:trailhead_mobile/features/shoes/application/shoe_service.dart';
import 'package:trailhead_mobile/features/shoes/data/models/shoe_isar.dart';
import 'package:trailhead_mobile/features/shoes/data/shoe_repository.dart';

class FakeShoeRepository implements ShoeRepository {
  final Map<Id, ShoeIsar> _shoes = {};

  @override
  Isar get isar => throw UnimplementedError();

  @override
  Future<void> saveShoe(ShoeIsar shoe) async {
    _shoes[shoe.id] = shoe;
  }

  @override
  Future<ShoeIsar?> getShoeById(Id id) async {
    return _shoes[id];
  }

  @override
  Future<List<ShoeIsar>> getAllShoes() async => _shoes.values.toList();

  @override
  Future<List<ShoeIsar>> getActiveShoes() async =>
      _shoes.values.where((s) => s.isActive).toList();

  @override
  Future<ShoeIsar?> getShoeByClientId(String clientId) async {
    return _shoes.values.cast<ShoeIsar?>().firstWhere(
      (s) => s?.clientShoeId == clientId,
      orElse: () => null,
    );
  }

  @override
  Future<void> deleteShoe(Id id) async {
    _shoes.remove(id);
  }
}

void main() {
  group('ShoeService - Edit Shoe Name and Company', () {
    late FakeShoeRepository repository;
    late ShoeService shoeService;

    setUp(() {
      repository = FakeShoeRepository();
      shoeService = ShoeService(repository);
    });

    test('updateShoe updates name and company (brand) successfully', () async {
      final initialShoe = ShoeIsar()
        ..id = 1
        ..clientShoeId = 'test-shoe-1'
        ..name = 'Pegasus 39'
        ..brand = 'Nike'
        ..distanceM = 15000
        ..isActive = true;
      await repository.saveShoe(initialShoe);

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
      final persisted = await repository.getShoeById(1);
      expect(persisted?.name, equals('Pegasus 40'));
      expect(persisted?.brand, equals('Nike Running'));
    });

    test('updateShoe trims whitespace and sets empty company to null', () async {
      final initialShoe = ShoeIsar()
        ..id = 2
        ..clientShoeId = 'test-shoe-2'
        ..name = 'Clifton 9'
        ..brand = 'Hoka'
        ..isActive = true;
      await repository.saveShoe(initialShoe);

      final updatedShoe = await shoeService.updateShoe(
        2,
        name: 'Clifton 9 Wide',
        brand: '   ',
      );

      expect(updatedShoe, isNotNull);
      expect(updatedShoe!.name, equals('Clifton 9 Wide'));
      expect(updatedShoe.brand, isNull);
    });

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
