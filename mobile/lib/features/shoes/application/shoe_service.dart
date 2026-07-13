import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../data/shoe_repository.dart';
import '../data/models/shoe_isar.dart';
import '../../sync/application/sync_service.dart';
import '../../../main.dart'; // For isarInstance

import '../../sync/data/api_client.dart';

final shoeRepositoryProvider = Provider<ShoeRepository>((ref) {
  return ShoeRepository(isarInstance!);
});

final shoeServiceProvider = Provider<ShoeService>((ref) {
  final repo = ref.watch(shoeRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);
  final syncService = SyncService(isar: isarInstance!, apiClient: apiClient);
  return ShoeService(repo, syncService);
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
  final SyncService syncService;

  ShoeService(this.repository, this.syncService);

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
    
    // Attempt background sync
    try {
      await syncService.syncShoe(shoe);
    } catch (e) {
      // Ignored: will be handled by regular sync job or just silently fail and sync later
    }
    
    return shoe;
  }

  Future<void> retireShoe(Id id) async {
    final shoe = await repository.getShoeById(id);
    if (shoe != null) {
      shoe.isActive = false;
      await repository.saveShoe(shoe);
      
      try {
        await syncService.syncShoe(shoe);
      } catch (e) {}
    }
  }

  Future<void> addDistanceToShoe(String clientShoeId, double distanceM) async {
    final shoe = await repository.getShoeByClientId(clientShoeId);
    if (shoe != null) {
      shoe.distanceM += distanceM;
      await repository.saveShoe(shoe);
      
      try {
        await syncService.syncShoe(shoe);
      } catch (e) {}
    }
  }

  Future<void> deleteShoe(Id id) async {
    final shoe = await repository.getShoeById(id);
    if (shoe != null) {
      final clientShoeId = shoe.clientShoeId;
      await repository.deleteShoe(id);
      
      try {
        if (clientShoeId != null) {
          await syncService.deleteShoe(clientShoeId);
        }
      } catch (e) {
        // Silently fail if offline, a robust system would queue delete operations.
      }
    }
  }
}
