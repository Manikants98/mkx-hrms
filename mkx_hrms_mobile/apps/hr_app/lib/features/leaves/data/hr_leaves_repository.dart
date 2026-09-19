import 'package:mkx_core/constants/api_endpoints.dart';
import 'package:mkx_core/network/dio_client.dart';
import '../models/hr_leave_model.dart';

/// Repository for HR admin leave management operations
class HrLeavesRepository {
  final DioClient _client = DioClient.instance;

  /// Fetches all employee leave requests, optionally filtered by [status].
  Future<List<HrLeaveModel>> getLeaves({String? status}) async {
    final String? normalizedStatus = (status != null &&
            status.isNotEmpty &&
            status.toLowerCase() != 'all')
        ? '${status[0].toUpperCase()}${status.substring(1).toLowerCase()}'
        : null;

    final params = <String, dynamic>{
      if (normalizedStatus != null) 'status': normalizedStatus,
    };

    final response = await _client.get(
      ApiEndpoints.allLeaves,
      queryParameters: params,
    );

    final List<dynamic> list = response is List
        ? response
        : (response is Map<String, dynamic>
            ? (response['leaves'] ?? response['data'] ?? []) as List<dynamic>
            : []);

    return list
        .map((e) => HrLeaveModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Approves a leave request by [leaveId].
  Future<void> approveLeave(int leaveId) async {
    await _client.patch(ApiEndpoints.approveLeave(leaveId));
  }

  /// Rejects a leave request by [leaveId] with an optional [reason].
  Future<void> rejectLeave(int leaveId, {String? reason}) async {
    await _client.patch(
      ApiEndpoints.rejectLeave(leaveId),
      data: reason != null ? {'reason': reason} : null,
    );
  }
}
