class ShoeGear {
  const ShoeGear({
    this.id,
    this.clientShoeId,
    this.name,
    this.brand,
    this.imageUrl,
    this.distanceM = 0,
    this.isActive = true,
    this.createdAt,
  });

  final int? id;
  final String? clientShoeId;
  final String? name;
  final String? brand;
  final String? imageUrl;
  final double distanceM;
  final bool isActive;
  final DateTime? createdAt;

  ShoeGear update({
    String? name,
    String? brand,
    bool replaceBrand = false,
    String? imageUrl,
    double? distanceM,
    bool? isActive,
  }) => ShoeGear(
    id: id,
    clientShoeId: clientShoeId,
    name: name ?? this.name,
    brand: replaceBrand ? brand : this.brand,
    imageUrl: imageUrl ?? this.imageUrl,
    distanceM: distanceM ?? this.distanceM,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
  );
}

abstract interface class ShoesRepository {
  Stream<List<ShoeGear>> watchAll();
  Future<List<ShoeGear>> getActiveShoes();
  Future<ShoeGear> add(ShoeGear shoe);
  Future<ShoeGear?> update(int id, ShoeGear Function(ShoeGear) change);
  Future<void> delete(int id);
}

ShoeGear? findTrackedShoe(List<ShoeGear> inventory, String trackingId) {
  final match = inventory
      .where((shoe) => shoe.clientShoeId == trackingId)
      .firstOrNull;
  if (match != null) return match;
  final legacyId = int.tryParse(trackingId);
  return legacyId == null
      ? null
      : inventory.where((shoe) => shoe.id == legacyId).firstOrNull;
}
