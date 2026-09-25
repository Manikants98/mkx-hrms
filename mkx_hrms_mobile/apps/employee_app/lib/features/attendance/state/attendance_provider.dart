import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../data/attendance_repository.dart';
import '../models/attendance_model.dart';

/// State management for daily attendance, live ticker, and punch operations
class AttendanceProvider extends ChangeNotifier {
  final AttendanceRepository _repo = AttendanceRepository();

  AttendanceRecord? _todayRecord;
  AttendanceStats? _stats;
  List<AttendanceRecord> _history = [];
  bool _isLoading = false;
  bool _isPunching = false;
  String? _errorMessage;

  late Timer _tickerTimer;
  DateTime _currentTime = DateTime.now();

  AttendanceRecord? get todayRecord => _todayRecord;
  AttendanceStats? get stats => _stats;
  List<AttendanceRecord> get history => _history;
  bool get isLoading => _isLoading;
  bool get isPunching => _isPunching;
  String? get errorMessage => _errorMessage;
  DateTime get currentTime => _currentTime;

  AttendanceProvider() {
    _startClockTicker();
  }

  void _startClockTicker() {
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _currentTime = DateTime.now();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _tickerTimer.cancel();
    super.dispose();
  }

  Future<void> loadAttendance({int? employeeId, String? employeeCode}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repo.getMyAttendance(
        employeeId: employeeId,
        employeeCode: employeeCode,
      );
      _todayRecord = res.today;
      _stats = res.stats;
      _history = res.history;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> _getDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      if (kIsWeb) {
        final info = await deviceInfoPlugin.webBrowserInfo;
        return '${info.browserName.name} on ${info.platform}';
      } else if (Platform.isAndroid) {
        final info = await deviceInfoPlugin.androidInfo;
        return '${info.brand} ${info.model} (Android ${info.version.release})';
      } else if (Platform.isIOS) {
        final info = await deviceInfoPlugin.iosInfo;
        return '${info.name} (iOS ${info.systemVersion})';
      }
    } catch (_) {}
    return 'Unknown Device';
  }

  Future<String> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return 'Location Disabled';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Permission Denied';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return 'Permission Denied Forever';
      }

      final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      final geocoding = Geocoding();
      try {
        List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = [place.subLocality, place.locality]
              .where((p) => p != null && p.isNotEmpty)
              .toList();
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
      } catch (_) {}
      return '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    } catch (_) {}
    return 'Location Unavailable';
  }

  Future<bool> punchIn({int? employeeId, String location = 'Office'}) async {
    _isPunching = true;
    notifyListeners();

    try {
      final gpsLocation = await _getLocation();
      final deviceInfo = await _getDeviceInfo();
      final finalLocation = (gpsLocation != 'Location Unavailable' &&
              gpsLocation != 'Location Disabled' &&
              gpsLocation != 'Permission Denied' &&
              gpsLocation != 'Permission Denied Forever')
          ? gpsLocation
          : location;

      final updated = await _repo.punch(
        action: 'check-in',
        employeeId: employeeId,
        location: finalLocation,
        deviceInfo: deviceInfo,
      );
      _todayRecord = updated;
      await loadAttendance(employeeId: employeeId);
      _isPunching = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isPunching = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> punchOut({int? employeeId, String location = 'Office'}) async {
    _isPunching = true;
    notifyListeners();

    try {
      final gpsLocation = await _getLocation();
      final deviceInfo = await _getDeviceInfo();
      final finalLocation = (gpsLocation != 'Location Unavailable' &&
              gpsLocation != 'Location Disabled' &&
              gpsLocation != 'Permission Denied' &&
              gpsLocation != 'Permission Denied Forever')
          ? gpsLocation
          : location;

      final updated = await _repo.punch(
        action: 'check-out',
        employeeId: employeeId,
        location: finalLocation,
        deviceInfo: deviceInfo,
      );
      _todayRecord = updated;
      await loadAttendance(employeeId: employeeId);
      _isPunching = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isPunching = false;
      notifyListeners();
      return false;
    }
  }
}
