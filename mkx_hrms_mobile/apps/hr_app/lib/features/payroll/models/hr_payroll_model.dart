/// Payroll record for a single employee for a given month
class HrPayrollModel {
  final int id;
  final int employeeId;
  final String employeeName;
  final String employeeCode;
  final String? role;
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
    this.role,
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
      id: json['db_id'] is int
          ? json['db_id'] as int
          : (json['id'] is int
                ? json['id'] as int
                : int.tryParse(
                        json['db_id']?.toString() ??
                            json['id']?.toString() ??
                            '',
                      ) ??
                      0),
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
          json['payroll_code']?.toString() ??
          employee['employee_id']?.toString() ??
          json['id']?.toString() ??
          '',
      role: json['role']?.toString() ?? employee['role']?.toString(),
      department:
          json['department']?.toString() ?? employee['department']?.toString(),
      month: json['month'] is int
          ? json['month'] as int
          : int.tryParse(json['month']?.toString() ?? '') ??
                DateTime.now().month,
      year: json['year'] is int
          ? json['year'] as int
          : int.tryParse(json['year']?.toString() ?? '') ?? DateTime.now().year,
      basicSalary: _parseDouble(
        json['basic_salary'] ?? json['raw_gross'] ?? json['gross_pay'],
      ),
      allowances: _parseDouble(json['allowances'] ?? json['raw_allowances']),
      deductions: _parseDouble(
        json['deductions'] ??
            json['raw_deductions'] ??
            json['total_deductions'],
      ),
      netSalary: _parseDouble(
        json['net_salary'] ?? json['raw_net'] ?? json['net_pay'],
      ),
      status: json['status']?.toString() ?? 'Pending',
      processedAt:
          json['processed_at']?.toString() ?? json['pay_date']?.toString(),
      processedBy: json['processed_by']?.toString(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value == null) return 0.0;
    final cleaned = value
        .toString()
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    return double.tryParse(cleaned) ?? 0.0;
  }
}
