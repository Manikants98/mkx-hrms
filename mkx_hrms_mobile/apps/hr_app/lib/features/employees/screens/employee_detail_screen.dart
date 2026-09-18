import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/widgets/mkx_app_bar.dart';
import 'package:mkx_core/widgets/section_tile.dart';
import 'package:mkx_core/widgets/status_badge.dart';
import '../state/employees_provider.dart';

/// Detailed employee profile screen matching employee_app structure
class EmployeeDetailScreen extends StatefulWidget {
  final String employeeId;

  const EmployeeDetailScreen({super.key, required this.employeeId});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeesProvider>().loadEmployeeDetail(widget.employeeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<EmployeesProvider>(
      builder: (context, provider, _) {
        final data = provider.selectedEmployee;
        final name = data['name']?.toString() ??
            '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
        final email = data['email']?.toString() ?? '';

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          appBar: MkxAppBar(
            title: 'Employee Profile',
            subtitle: name.isNotEmpty ? '$name • $email' : 'Employment details',
          ),
          body: SafeArea(
            top: false,
            child: provider.isLoadingDetail
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : data.isEmpty
                    ? Center(
                        child: Text(
                          'Employee record not found',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkMuted
                                : AppColors.lightMuted,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileHeader(isDark, data, name),
                            const SizedBox(height: 12),
                            _buildSectionHeader('WORK INFORMATION', isDark),
                            const SizedBox(height: 6),
                            SectionCard(
                              isDark: isDark,
                              children: [
                                _buildDetailRow(
                                  'Employee ID',
                                  data['employee_id']?.toString() ??
                                      data['id']?.toString() ??
                                      '—',
                                  isDark,
                                ),
                                _buildDetailRow(
                                  'Department',
                                  data['department']?.toString() ?? '—',
                                  isDark,
                                ),
                                _buildDetailRow(
                                  'Designation / Role',
                                  data['designation']?.toString() ??
                                      data['role']?.toString() ??
                                      '—',
                                  isDark,
                                ),
                                _buildDetailRow(
                                  'Assigned Shift',
                                  data['shift']?.toString() ??
                                      data['shift_name']?.toString() ??
                                      'General Day Shift',
                                  isDark,
                                ),
                                _buildDetailRow(
                                  'Reporting Manager',
                                  data['manager']?.toString() ??
                                      (data['manager_details'] is Map
                                          ? data['manager_details']['name']
                                              ?.toString()
                                          : null) ??
                                      data['manager_name']?.toString() ??
                                      '—',
                                  isDark,
                                ),
                                _buildDetailRow(
                                  'Date of Joining',
                                  data['join_date']?.toString() ?? '—',
                                  isDark,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _buildSectionHeader('CONTACT DETAILS', isDark),
                            const SizedBox(height: 6),
                            SectionCard(
                              isDark: isDark,
                              children: [
                                _buildDetailRow(
                                  'Corporate Email',
                                  data['email']?.toString() ?? '—',
                                  isDark,
                                ),
                                _buildDetailRow(
                                  'Phone Number',
                                  data['phone']?.toString().isNotEmpty == true
                                      ? data['phone'].toString()
                                      : 'Not provided',
                                  isDark,
                                ),
                                _buildDetailRow(
                                  'Office Location',
                                  data['address']?.toString().isNotEmpty == true
                                      ? data['address'].toString()
                                      : 'Corporate Headquarters',
                                  isDark,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (data['salary_structures'] is List &&
                                (data['salary_structures'] as List).isNotEmpty) ...[
                              _buildSectionHeader(
                                'SALARY STRUCTURE',
                                isDark,
                              ),
                              const SizedBox(height: 6),
                              SectionCard(
                                isDark: isDark,
                                children: (data['salary_structures'] as List)
                                    .map((s) {
                                  final item = s as Map<String, dynamic>;
                                  final structure = item['salary_structure']
                                          as Map<String, dynamic>? ??
                                      {};
                                  final name = structure['name']?.toString() ??
                                      'Salary Item';
                                  final amount = item['amount']?.toString() ??
                                      '0';
                                  return _buildDetailRow(
                                    name,
                                    '₹$amount',
                                    isDark,
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 14),
                            ],
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(
    bool isDark,
    Map<String, dynamic> data,
    String name,
  ) {
    final status = data['status']?.toString() ?? 'Active';
    final primaryColor = Theme.of(context).colorScheme.primary;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return SectionTile(
      isDark: isDark,
      position: TilePosition.only,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: primaryColor.withValues(alpha: 0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Employee',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data['email']?.toString() ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: mutedColor,
                  ),
                ),
                const SizedBox(height: 8),
                StatusBadge(status: status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: mutedColor,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
