import 'package:flutter/material.dart';
import '../data/hr_payroll_repository.dart';
import '../models/hr_payroll_model.dart';

/// State provider for HR payroll processing
class HrPayrollProvider extends ChangeNotifier {
  final HrPayrollRepository _repo = HrPayrollRepository();

  List<HrPayrollModel> _payrolls = [];
  bool _isLoading = false;
  String? _errorMessage;
  late int _selectedMonth;
  late int _selectedYear;
  final Set<int> _processingIds = {};

  List<HrPayrollModel> get payrolls => _payrolls;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;

  /// Returns true when a specific payroll ID is being processed
  bool isProcessing(int payrollId) => _processingIds.contains(payrollId);

  int get pendingCount =>
      _payrolls.where((p) => p.status.toLowerCase() == 'pending').length;
  int get processedCount =>
      _payrolls.where((p) => p.status.toLowerCase() == 'processed').length;

  HrPayrollProvider() {
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  Future<void> loadPayroll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _payrolls = await _repo.getPayroll(
        month: _selectedMonth,
        year: _selectedYear,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setMonthYear(int month, int year) {
    _selectedMonth = month;
    _selectedYear = year;
    notifyListeners();
    loadPayroll();
  }

  Future<bool> processPayroll(int payrollId) async {
    _processingIds.add(payrollId);
    notifyListeners();

    try {
      final updated = await _repo.processPayroll(payrollId);
      final index = _payrolls.indexWhere((p) => p.id == payrollId);
      if (index != -1) {
        _payrolls[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _processingIds.remove(payrollId);
      notifyListeners();
    }
  }
}
