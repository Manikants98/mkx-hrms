import 'package:flutter/material.dart';
import '../data/hr_attendance_repository.dart';
import '../models/hr_attendance_model.dart';

/// State provider for HR all-employee attendance view
class HrAttendanceProvider extends ChangeNotifier {
  final HrAttendanceRepository _repo = HrAttendanceRepository();

  List<HrAttendanceModel> _records = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();
  String _departmentFilter = '';
  String _statusFilter = '';

  List<HrAttendanceModel> get records => _records;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;
  String get departmentFilter => _departmentFilter;
  String get statusFilter => _statusFilter;

  int get presentCount =>
      _records.where((r) => r.status.toLowerCase() == 'present').length;
  int get absentCount =>
      _records.where((r) => r.status.toLowerCase() == 'absent').length;
  int get lateCount =>
      _records.where((r) => r.status.toLowerCase() == 'late').length;

  Future<void> loadAttendance() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _records = await _repo.getAttendance(
        date: _selectedDate,
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

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
    loadAttendance();
  }

  void setDepartmentFilter(String dept) {
    _departmentFilter = dept;
    notifyListeners();
    loadAttendance();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
    loadAttendance();
  }
}
