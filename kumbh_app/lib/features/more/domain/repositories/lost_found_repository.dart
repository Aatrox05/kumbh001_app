import '../../data/models/lost_found_report.dart';

abstract class LostFoundRepository {
  Future<int> insertReport(LostFoundReport report);
  Future<List<LostFoundReport>> getUnsyncedReports();
  Future<void> markAsSynced(int id);
}
