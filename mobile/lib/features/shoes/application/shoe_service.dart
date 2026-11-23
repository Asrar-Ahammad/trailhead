import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../data/shoe_repository.dart';
import '../data/models/shoe_isar.dart';
import '../../../main.dart'; // For isarInstance

final shoeRepositoryProvider = Provider<ShoeRepository>((ref) {
  return ShoeRepository(isarInstance);
});

final shoeServiceProvider = Provider<ShoeService>((ref) {
  final repo = ref.watch(shoeRepositoryProvider);
  return ShoeService(repo);
});

// Provides all shoes
final allShoesProvider = FutureProvider<List<ShoeIsar>>((ref) async {
  final service = ref.watch(shoeServiceProvider);
  return service.getAllShoes();
});

// Provides only active shoes
final activeShoesProvider = FutureProvider<List<ShoeIsar>>((ref) async {
  final service = ref.watch(shoeServiceProvider);
  return service.getActiveShoes();
});

class ShoeService {
  final ShoeRepository repository;

  ShoeService(this.repository);

  Future<List<ShoeIsar>> getAllShoes() => repository.getAllShoes();
  
  Future<List<ShoeIsar>> getActiveShoes() => repository.getActiveShoes();

  Future<ShoeIsar> addShoe(String name, String? brand) async {
    final shoe = ShoeIsar()
      ..clientShoeId = const Uuid().v4()
      ..name = name
      ..brand = brand
      ..distanceM = 0
      ..isActive = true
      ..createdAt = DateTime.now();
      
    await repository.saveShoe(shoe);
    return shoe;
  }

  Future<ShoeIsar?> updateShoe(Id id, {required String name, String? brand}) async {
    final shoe = await repository.getShoeById(id);
    if (shoe != null) {
      shoe.name = name;
      shoe.brand = brand?.trim().isEmpty == true ? null : brand?.trim();
      await repository.saveShoe(shoe);
      return shoe;
    }
    return null;
  }

  Future<void> retireShoe(Id id) async {
    final shoe = await repository.getShoeById(id);
    if (shoe != null) {
      shoe.isActive = false;
      await repository.saveShoe(shoe);
    }
  }

  Future<void> addDistanceToShoe(String clientShoeId, double distanceM) async {
    final shoe = await repository.getShoeByClientId(clientShoeId);
    if (shoe != null) {
      shoe.distanceM += distanceM;
      await repository.saveShoe(shoe);
    }
  }

  Future<void> deleteShoe(Id id) async {
    await repository.deleteShoe(id);
  }

  Future<void> uploadShoeImage(String clientShoeId, String imagePath) async {
    // Local-only shoe images: store local file path as imageUrl
    final shoe = await repository.getShoeByClientId(clientShoeId);
    if (shoe != null) {
      shoe.imageUrl = imagePath;
      await repository.saveShoe(shoe);
    }
  }
}
