import 'shoes_repository_inventory.dart';

class ShoeService {
  ShoeService(
    this.repository, {
    required this.newClientId,
    required this.preparePhoto,
  });
  final ShoesRepository repository;
  final String Function() newClientId;
  final Future<String?> Function(String sourcePath) preparePhoto;

  Future<List<ShoeGear>> getActiveShoes() => repository.getActiveShoes();

  Future<ShoeGear> addShoe(String name, String? brand) => repository.add(
    ShoeGear(
      clientShoeId: newClientId(),
      name: _name(name),
      brand: _brand(brand),
      createdAt: DateTime.now(),
    ),
  );

  Future<ShoeGear?> updateShoe(int id, {required String name, String? brand}) =>
      repository.update(
        id,
        (shoe) => shoe.update(
          name: _name(name),
          brand: _brand(brand),
          replaceBrand: true,
        ),
      );

  Future<void> retireShoe(int id) async {
    await repository.update(id, (shoe) => shoe.update(isActive: false));
  }

  Future<void> deleteShoe(int id) => repository.delete(id);

  Future<void> updatePhoto(int id, String sourcePath) async {
    final path = await preparePhoto(sourcePath);
    if (path == null) throw StateError('Could not process image');
    final shoe = await repository.update(
      id,
      (shoe) => shoe.update(imageUrl: path),
    );
    if (shoe == null) throw StateError('Shoe no longer exists');
  }

  String _name(String value) {
    final name = value.trim();
    if (name.isEmpty) throw const FormatException('Enter a shoe name.');
    return name;
  }

  String? _brand(String? value) {
    final brand = value?.trim();
    return brand == null || brand.isEmpty ? null : brand;
  }
}
