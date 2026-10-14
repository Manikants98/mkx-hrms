import 'package:flutter/material.dart';
export 'package:flutter/material.dart' show ThemeMode;
import 'package:mkx_core/storage/token_storage.dart';
import '../../../network/dio_client.dart';
import '../data/auth_repository.dart';
import '../models/user_model.dart';

/// State provider for Authentication and Global App Settings
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _hasSeenOnboarding = false;
  bool _hasSeenHrOnboarding = false;
  String? _errorMessage;
  ThemeMode _themeMode = ThemeMode.system;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get hasSeenHrOnboarding => _hasSeenHrOnboarding;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  ThemeMode get themeMode => _themeMode;

  AuthProvider() {
    DioClient.onUnauthorized ??= () {
      logout();
    };
    _initApp();
  }

  Future<void> _initApp() async {
    _isInitializing = true;
    notifyListeners();

    final Future<void> minSplashDelay =
        Future<void>.delayed(const Duration(milliseconds: 1800));

    try {
      /// Check onboarding completion state
      _hasSeenOnboarding = await TokenStorage.instance.getHasSeenOnboarding();
      _hasSeenHrOnboarding = await TokenStorage.instance.getHasSeenHrOnboarding();

      /// Load theme preference
      final savedMode = await TokenStorage.instance.getThemeMode();
      if (savedMode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedMode == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }

      /// Check existing authentication token
      final isAuth = await _repo.isAuthenticated();
      if (isAuth) {
        _currentUser = await _repo.getCachedUser();
        notifyListeners();
        /// Silently refresh profile in background
        _currentUser = await _repo.getMe() ?? _currentUser;
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    } finally {
      /// Guarantee minimum branded splash animation duration
      await minSplashDelay;

      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Completes or skips the first-time onboarding flow and persists the state.
  Future<void> completeOnboarding() async {
    _hasSeenOnboarding = true;
    await TokenStorage.instance.setHasSeenOnboarding(true);
    notifyListeners();
  }

  /// Completes or skips the first-time HR onboarding flow and persists the state.
  Future<void> completeHrOnboarding() async {
    _hasSeenHrOnboarding = true;
    await TokenStorage.instance.setHasSeenHrOnboarding(true);
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _repo.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    await DioClient.instance.clearCache();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    String modeStr = 'system';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    if (mode == ThemeMode.light) modeStr = 'light';
    await TokenStorage.instance.saveThemeMode(modeStr);
  }
}
