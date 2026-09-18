import 'package:intl/intl.dart';
import 'package:mkx_core/constants/api_endpoints.dart';
import 'package:mkx_core/network/dio_client.dart';
import '../models/hr_attendance_model.dart';

/// Repository for HR admin attendance view and management
class HrAttendanceRepository {
  final DioClient _client = DioClient.instance;

  /// Fetches all employee attendance records for the given [date].
  /// Defaults to today when [date] is null.
  Future<List<HrAttendanceModel>> getAttendance({
    DateTime? date,
    String? department,
    String? status,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date ?? DateTime.now());

    final params = <String, dynamic>{
      'date': dateStr,
      if (department != null && department.isNotEmpty && department != 'All')
        'department': department,
      if (status != null && status.isNotEmpty && status != 'All')
        'status': status.toLowerCase(),
    };

    final response = await _client.get(
      ApiEndpoints.allAttendance,
      queryParameters: params,
    );

    final List<dynamic> list = response is List
        ? response
        : (response is Map<String, dynamic>
            ? (response['attendance'] ?? response['data'] ?? [])
                as List<dynamic>
            : []);

    return list
        .map((e) => HrAttendanceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
