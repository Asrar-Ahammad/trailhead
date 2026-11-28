import 'package:isar/isar.dart';
import '../../run_tracking/data/models/run_isar.dart';

class ShoeActivityRepository {
  ShoeActivityRepository(this.isar);
  final Isar isar;

  Stream<List<RunIsar>> watchRuns(String? clientShoeId) {
    if (clientShoeId == null) return Stream.value(const []);
    return isar.runIsars
        .filter()
        .clientShoeIdEqualTo(clientShoeId)
        .statusEqualTo('completed')
        .sortByStartTimeDesc()
        .watch(fireImmediately: true);
  }
}
