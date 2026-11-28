import 'package:isar/isar.dart';
import '../domain/shoes_repository_inventory.dart';
import 'models/shoe_isar.dart';

class ShoesRepositoryImplementation implements ShoesRepository {
  ShoesRepositoryImplementation(this.isar);
  final Isar isar;

  @override
  Stream<List<ShoeGear>> watchAll() => isar.shoeIsars
      .where()
      .sortByCreatedAtDesc()
      .watch(fireImmediately: true)
      .map((rows) => rows.map(_toGear).toList(growable: false));

  @override
  Future<List<ShoeGear>> getActiveShoes() async {
    final rows = await isar.shoeIsars
        .filter()
        .isActiveEqualTo(true)
        .sortByCreatedAtDesc()
        .findAll();
    return rows.map(_toGear).toList(growable: false);
  }

  @override
  Future<ShoeGear> add(ShoeGear shoe) async {
    final row = _toRow(shoe);
    await isar.writeTxn(() => isar.shoeIsars.put(row));
    return _toGear(row);
  }

  @override
  Future<ShoeGear?> update(int id, ShoeGear Function(ShoeGear) change) =>
      isar.writeTxn(() async {
        final current = await isar.shoeIsars.get(id);
        if (current == null) return null;
        final updated = change(_toGear(current));
        await isar.shoeIsars.put(_toRow(updated));
        return updated;
      });

  @override
  Future<void> delete(int id) async {
    await isar.writeTxn(() => isar.shoeIsars.delete(id));
  }

  ShoeGear _toGear(ShoeIsar row) => ShoeGear(
    id: row.id,
    clientShoeId: row.clientShoeId,
    name: row.name,
    brand: row.brand,
    imageUrl: row.imageUrl,
    distanceM: row.distanceM,
    isActive: row.isActive,
    createdAt: row.createdAt,
  );

  ShoeIsar _toRow(ShoeGear shoe) => ShoeIsar()
    ..id = shoe.id ?? Isar.autoIncrement
    ..clientShoeId = shoe.clientShoeId
    ..name = shoe.name
    ..brand = shoe.brand
    ..imageUrl = shoe.imageUrl
    ..distanceM = shoe.distanceM
    ..isActive = shoe.isActive
    ..createdAt = shoe.createdAt;
}
