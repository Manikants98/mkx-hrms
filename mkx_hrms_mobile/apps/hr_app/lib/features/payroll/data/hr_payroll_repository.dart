import 'package:mkx_core/constants/api_endpoints.dart';
import 'package:mkx_core/network/dio_client.dart';
import '../models/hr_payroll_model.dart';

/// Repository for HR payroll processing and retrieval
class HrPayrollRepository {
  final DioClient _client = DioClient.instance;

  /// Fetches all payroll records for the given [month] and [year].
  Future<List<HrPayrollModel>> getPayroll({
    required int month,
    required int year,
    String? department,
  }) async {
    final params = <String, dynamic>{
      'month': month,
      'year': year,
      if (department != null && department.isNotEmpty && department != 'All')
        'department': department,
    };

    final response = await _client.get(
      ApiEndpoints.allPayroll,
      queryParameters: params,
    );

    final List<dynamic> list = response is List
        ? response
        : (response is Map<String, dynamic>
            ? (response['payroll'] ?? response['data'] ?? []) as List<dynamic>
            : []);

    return list
        .map((e) => HrPayrollModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Triggers payroll processing for a single employee record [payrollId].
  Future<HrPayrollModel> processPayroll(int payrollId) async {
    final response = await _client.post(
      ApiEndpoints.processPayroll(payrollId),
    );
    if (response is Map<String, dynamic>) {
      return HrPayrollModel.fromJson(response);
    }
    throw Exception('Failed to process payroll');
  }
}
