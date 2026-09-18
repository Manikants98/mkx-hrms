/// Centralized API URLs and endpoint definitions for MKX HRMS Backend
class ApiEndpoints {
  ApiEndpoints._();

  /// Production Live API backend base URL
  static const String liveBaseUrl = 'https://api.mkx.monster/api/v1';

  /// Local development URL for Android emulator
  static const String emulatorBaseUrl = 'http://10.0.2.2:3000/api/v1';

  /// Localhost URL for iOS simulator / web / desktop
  static const String localBaseUrl = 'http://localhost:3000/api/v1';

  /// Resolves the default backend base URL
  /// Configured with live Render backend
  static String get defaultBaseUrl => liveBaseUrl;

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // ── Employee (self-service) ───────────────────────────────────────────────
  static const String punch = '/attendance/punch';
  static const String myAttendance = '/attendance/my';
  static const String myLeaves = '/leaves/my';
  static const String applyLeave = '/leaves';
  static const String leaveTypes = '/masters/leave-types';
  static const String myPayroll = '/payroll/my';

  // ── HR Admin — Employees ──────────────────────────────────────────────────
  /// `GET /employees` — paginated employee directory
  static const String employees = '/employees';

  /// `GET /employees/:id` — single employee profile
  static String employeeDetail(Object id) => '/employees/$id';

  // ── HR Admin — Leaves ─────────────────────────────────────────────────────
  /// `GET /leaves` — all employee leave requests (supports ?status= filter)
  static const String allLeaves = '/leaves';

  /// `PATCH /leaves/:id/approve`
  static String approveLeave(int id) => '/leaves/$id/approve';

  /// `PATCH /leaves/:id/reject`
  static String rejectLeave(int id) => '/leaves/$id/reject';

  // ── HR Admin — Attendance ─────────────────────────────────────────────────
  /// `GET /attendance` — all employee attendance (supports ?date= filter)
  static const String allAttendance = '/attendance';

  // ── HR Admin — Payroll ────────────────────────────────────────────────────
  /// `GET /payroll` — all payroll records (supports ?month=&year= filter)
  static const String allPayroll = '/payroll';

  /// `POST /payroll/:id/process`
  static String processPayroll(int id) => '/payroll/$id/process';

  // ── HR Admin — Dashboard ──────────────────────────────────────────────────
  /// `GET /dashboard/overview` — aggregate KPI stats for HR overview
  static const String hrDashboard = '/dashboard/overview';
}
