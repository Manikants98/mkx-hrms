import 'package:flutter/material.dart';
import '../data/hr_leaves_repository.dart';
import '../models/hr_leave_model.dart';

/// State provider for HR leave management
class HrLeavesProvider extends ChangeNotifier {
  final HrLeavesRepository _repo = HrLeavesRepository();

  List<HrLeaveModel> _leaves = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _statusFilter = 'All';
  final Set<int> _processingIds = {};

  List<HrLeaveModel> get leaves => _leaves;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get statusFilter => _statusFilter;

  /// Returns true when a specific leave ID is being processed
  bool isProcessing(int leaveId) => _processingIds.contains(leaveId);

  Future<void> loadLeaves({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _leaves = await _repo.getLeaves(status: status ?? _statusFilter);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
    loadLeaves(status: status);
  }

  Future<bool> approveLeave(int leaveId) async {
    _processingIds.add(leaveId);
    notifyListeners();

    try {
      await _repo.approveLeave(leaveId);
      await loadLeaves();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _processingIds.remove(leaveId);
      notifyListeners();
    }
  }

  Future<bool> rejectLeave(int leaveId, {String? reason}) async {
    _processingIds.add(leaveId);
    notifyListeners();

    try {
      await _repo.rejectLeave(leaveId, reason: reason);
      await loadLeaves();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _processingIds.remove(leaveId);
      notifyListeners();
    }
  }
}
