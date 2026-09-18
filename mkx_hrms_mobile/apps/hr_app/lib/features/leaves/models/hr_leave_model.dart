/// HR Leave request model representing an employee leave entry
class HrLeaveModel {
  final int id;
  final int employeeId;
  final String employeeName;
  final String employeeCode;
  final String? role;
  final String? department;
  final String leaveType;
  final String startDate;
  final String endDate;
  final int totalDays;
  final String reason;
  final String status;
  final String? appliedAt;
  final String? reviewedAt;
  final String? reviewedBy;

  const HrLeaveModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    this.role,
    this.department,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    this.appliedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory HrLeaveModel.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'] as Map<String, dynamic>? ?? {};
    return HrLeaveModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      employeeId: employee['id'] is int
          ? employee['id'] as int
          : int.tryParse(
                  employee['id']?.toString() ??
                      json['employee_id']?.toString() ??
                      '',
                ) ??
                0,
      employeeName:
          json['employee_name']?.toString() ??
          json['name']?.toString() ??
          employee['name']?.toString() ??
          'Unknown',
      employeeCode:
          json['employee_code']?.toString() ??
          json['employee_id']?.toString() ??
          employee['employee_id']?.toString() ??
          json['id']?.toString() ??
          '',
      role: json['role']?.toString() ?? employee['role']?.toString(),
      department:
          json['department']?.toString() ?? employee['department']?.toString(),
      leaveType:
          json['leave_type']?.toString() ?? json['type']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      totalDays: json['total_days'] is int
          ? json['total_days'] as int
          : int.tryParse(json['total_days']?.toString() ?? '') ?? 1,
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      appliedAt:
          json['applied_at']?.toString() ?? json['created_at']?.toString(),
      reviewedAt: json['reviewed_at']?.toString(),
      reviewedBy: json['reviewed_by']?.toString(),
    );
  }
}
