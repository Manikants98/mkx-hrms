import 'package:flutter/material.dart';
import '../data/employees_repository.dart';
import '../models/employee_list_model.dart';

/// State provider for the HR Employee Directory feature
class EmployeesProvider extends ChangeNotifier {
  final EmployeesRepository _repo = EmployeesRepository();

  List<EmployeeListModel> _employees = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _departmentFilter = '';
  String _statusFilter = '';
  Map<String, dynamic> _selectedEmployee = {};
  bool _isLoadingDetail = false;
  List<String> _departments = ['All'];
  bool _isLoadingDepartments = false;

  List<EmployeeListModel> get employees => _employees;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get departmentFilter => _departmentFilter;
  String get statusFilter => _statusFilter;
  Map<String, dynamic> get selectedEmployee => _selectedEmployee;
  bool get isLoadingDetail => _isLoadingDetail;
  List<String> get departments => _departments;
  bool get isLoadingDepartments => _isLoadingDepartments;

  Future<void> loadEmployees() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _employees = await _repo.getEmployees(
        search: _searchQuery,
        department: _departmentFilter,
        status: _statusFilter,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDepartments() async {
    if (_isLoadingDepartments) return;
    _isLoadingDepartments = true;
    notifyListeners();

    try {
      final deps = await _repo.getDepartments();
      _departments = ['All', ...deps];
    } catch (_) {
      // Keep existing list on failure
    } finally {
      _isLoadingDepartments = false;
      notifyListeners();
    }
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
    loadEmployees();
  }

  void setDepartmentFilter(String dept) {
    _departmentFilter = dept;
    notifyListeners();
    loadEmployees();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
    loadEmployees();
  }

  Future<void> loadEmployeeDetail(Object id) async {
    _isLoadingDetail = true;
    _selectedEmployee = {};
    notifyListeners();

    try {
      _selectedEmployee = await _repo.getEmployeeDetail(id);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }
}
