/// HR Attendance record for a single employee on a given day
class HrAttendanceModel {
  final int id;
  final int employeeId;
  final String employeeName;
  final String employeeCode;
  final String? department;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String status;
  final String? duration;

  const HrAttendanceModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    this.department,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.duration,
  });

  factory HrAttendanceModel.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'] as Map<String, dynamic>? ?? {};
    return HrAttendanceModel(
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
      date: json['date']?.toString() ?? '',
      checkIn: json['check_in']?.toString() ?? json['time_in']?.toString(),
      checkOut: json['check_out']?.toString() ?? json['time_out']?.toString(),
      status: json['status']?.toString() ?? 'Absent',
      duration: json['duration']?.toString() ?? json['work_hours']?.toString(),
    );
  }
}
