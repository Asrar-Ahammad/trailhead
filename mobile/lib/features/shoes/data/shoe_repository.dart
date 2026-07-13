import 'package:isar/isar.dart';
import 'models/shoe_isar.dart';

class ShoeRepository {
  final Isar isar;

  ShoeRepository(this.isar);

  Future<void> saveShoe(ShoeIsar shoe) async {
    await isar.writeTxn(() async {
      await isar.shoeIsars.put(shoe);
    });
  }

  Future<List<ShoeIsar>> getAllShoes() async {
    return await isar.shoeIsars.where().sortByCreatedAtDesc().findAll();
  }

  Future<List<ShoeIsar>> getActiveShoes() async {
    return await isar.shoeIsars.filter().isActiveEqualTo(true).sortByCreatedAtDesc().findAll();
  }

  Future<ShoeIsar?> getShoeById(Id id) async {
    return await isar.shoeIsars.get(id);
  }

  Future<ShoeIsar?> getShoeByClientId(String clientId) async {
    return await isar.shoeIsars.filter().clientShoeIdEqualTo(clientId).findFirst();
  }

  Future<void> deleteShoe(Id id) async {
    await isar.writeTxn(() async {
      await isar.shoeIsars.delete(id);
    });
  }
}
