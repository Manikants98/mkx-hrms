/// Payroll record for a single employee for a given month
class HrPayrollModel {
  final int id;
  final int employeeId;
  final String employeeName;
  final String employeeCode;
  final String? department;
  final int month;
  final int year;
  final double basicSalary;
  final double allowances;
  final double deductions;
  final double netSalary;
  final String status;
  final String? processedAt;
  final String? processedBy;

  const HrPayrollModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    this.department,
    required this.month,
    required this.year,
    required this.basicSalary,
    required this.allowances,
    required this.deductions,
    required this.netSalary,
    required this.status,
    this.processedAt,
    this.processedBy,
  });

  factory HrPayrollModel.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'] as Map<String, dynamic>? ?? {};
    return HrPayrollModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      employeeId: employee['id'] is int
          ? employee['id'] as int
          : int.tryParse(employee['id']?.toString() ?? '') ?? 0,
      employeeName:
          employee['name']?.toString() ??
          json['employee_name']?.toString() ??
          'Unknown',
      employeeCode:
          employee['employee_id']?.toString() ??
          json['employee_code']?.toString() ??
          '',
      department:
          employee['department']?.toString() ?? json['department']?.toString(),
      month: json['month'] is int
          ? json['month'] as int
          : int.tryParse(json['month']?.toString() ?? '') ?? 1,
      year: json['year'] is int
          ? json['year'] as int
          : int.tryParse(json['year']?.toString() ?? '') ?? DateTime.now().year,
      basicSalary: _parseDouble(json['basic_salary']),
      allowances: _parseDouble(json['allowances']),
      deductions: _parseDouble(json['deductions']),
      netSalary: _parseDouble(json['net_salary']),
      status: json['status']?.toString() ?? 'Pending',
      processedAt: json['processed_at']?.toString(),
      processedBy: json['processed_by']?.toString(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
