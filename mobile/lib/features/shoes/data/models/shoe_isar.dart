import 'package:isar/isar.dart';

part 'shoe_isar.g.dart';

@collection
class ShoeIsar {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? clientShoeId; // UUID generated on client side

  String? name;
  String? brand;
  
  double distanceM = 0;
  
  bool isActive = true;
  
  DateTime? createdAt;
}
