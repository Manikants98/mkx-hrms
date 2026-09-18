import 'package:mkx_core/constants/api_endpoints.dart';
import 'package:mkx_core/network/dio_client.dart';
import '../models/dashboard_stats_model.dart';

/// Repository fetching aggregate KPI data for the HR Dashboard
class DashboardRepository {
  final DioClient _client = DioClient.instance;

  /// Fetches HR dashboard stats. Falls back to [DashboardStatsModel.empty]
  /// gracefully if the endpoint does not yet exist (404/500).
  Future<DashboardStatsModel> getStats() async {
    try {
      final response = await _client.get(ApiEndpoints.hrDashboard);
      if (response is Map<String, dynamic>) {
        return DashboardStatsModel.fromJson(response);
      }
    } catch (_) {
      // Endpoint may not yet be implemented; return empty shell
    }
    return DashboardStatsModel.empty();
  }
}
