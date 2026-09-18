import 'package:flutter/material.dart';
import '../data/dashboard_repository.dart';
import '../models/dashboard_stats_model.dart';

/// State provider for the HR Dashboard feature
class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _repo = DashboardRepository();

  DashboardStatsModel _stats = DashboardStatsModel.empty();
  bool _isLoading = false;
  String? _errorMessage;

  DashboardStatsModel get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _repo.getStats();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
