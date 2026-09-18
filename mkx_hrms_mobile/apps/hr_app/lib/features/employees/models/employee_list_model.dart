/// Lightweight employee model for listing in the HR directory
class EmployeeListModel {
  final int id;
  final String employeeCode;
  final String name;
  final String email;
  final String department;
  final String role;
  final String status;
  final String? avatar;
  final String? joinDate;
  final String? phone;
  final String? designation;

  const EmployeeListModel({
    required this.id,
    required this.employeeCode,
    required this.name,
    required this.email,
    required this.department,
    required this.role,
    required this.status,
    this.avatar,
    this.joinDate,
    this.phone,
    this.designation,
  });

  factory EmployeeListModel.fromJson(Map<String, dynamic> json) =>
      EmployeeListModel(
        id: json['db_id'] is int
            ? json['db_id'] as int
            : int.tryParse(json['db_id']?.toString() ?? '') ??
                  (json['id'] is int
                      ? json['id'] as int
                      : int.tryParse(json['id']?.toString() ?? '') ?? 0),
        employeeCode:
            (json['id'] != null && json['id'].toString().startsWith('EMP'))
            ? json['id'].toString()
            : json['employee_id']?.toString() ?? json['id']?.toString() ?? '',
        name:
            json['name']?.toString() ??
            '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
        email: json['email']?.toString() ?? '',
        department: json['department']?.toString() ?? 'General',
        role: json['role']?.toString() ?? 'Employee',
        status: json['status']?.toString() ?? 'Active',
        avatar: json['avatar']?.toString(),
        joinDate: json['join_date']?.toString(),
        phone: json['phone']?.toString(),
        designation:
            json['designation']?.toString() ?? json['role']?.toString(),
      );
}
