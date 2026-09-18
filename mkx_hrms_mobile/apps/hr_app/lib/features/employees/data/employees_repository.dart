import 'package:mkx_core/constants/api_endpoints.dart';
import 'package:mkx_core/network/dio_client.dart';
import '../models/employee_list_model.dart';

/// Repository for HR employee directory operations
class EmployeesRepository {
  final DioClient _client = DioClient.instance;

  /// Fetches a paginated, optionally filtered list of employees.
  Future<List<EmployeeListModel>> getEmployees({
    int page = 1,
    int limit = 20,
    String? search,
    String? department,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (department != null && department.isNotEmpty) 'department': department,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final response = await _client.get(
      ApiEndpoints.employees,
      queryParameters: params,
    );

    final List<dynamic> list = response is List
        ? response
        : (response is Map<String, dynamic>
              ? (response['employees'] ?? response['data'] ?? [])
                    as List<dynamic>
              : []);

    return list
        .map((e) => EmployeeListModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches full profile details for a single employee.
  Future<Map<String, dynamic>> getEmployeeDetail(int id) async {
    final response = await _client.get(ApiEndpoints.employeeDetail(id));
    if (response is Map<String, dynamic>) return response;
    return {};
  }
}
