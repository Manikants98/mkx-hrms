import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/widgets/app_text.dart';
import 'package:mkx_core/widgets/status_badge.dart';
import '../state/employees_provider.dart';

/// Detailed employee profile screen navigated to from the directory
class EmployeeDetailScreen extends StatefulWidget {
  final int employeeId;

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

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        title: const AppText.title('Employee Profile'),
        elevation: 0,
      ),
      body: Consumer<EmployeesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingDetail) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = provider.selectedEmployee;

          if (data.isEmpty) {
            return const Center(child: AppText.muted('Employee not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileCard(isDark, data),
                const SizedBox(height: 12),
                _buildInfoSection(isDark, 'Work Details', [
                  _InfoRow(
                    label: 'Department',
                    value: data['department']?.toString() ?? '—',
                  ),
                  _InfoRow(
                    label: 'Designation',
                    value:
                        data['designation']?.toString() ??
                        data['role']?.toString() ??
                        '—',
                  ),
                  _InfoRow(
                    label: 'Employee ID',
                    value: data['employee_id']?.toString() ?? '—',
                  ),
                  _InfoRow(
                    label: 'Join Date',
                    value: data['join_date']?.toString() ?? '—',
                  ),
                  _InfoRow(
                    label: 'Shift',
                    value:
                        data['shift']?.toString() ??
                        data['shift_name']?.toString() ??
                        '—',
                  ),
                  _InfoRow(
                    label: 'Manager',
                    value: data['manager_name']?.toString() ?? '—',
                  ),
                ]),
                const SizedBox(height: 12),
                _buildInfoSection(isDark, 'Contact', [
                  _InfoRow(
                    label: 'Email',
                    value: data['email']?.toString() ?? '—',
                  ),
                  _InfoRow(
                    label: 'Phone',
                    value: data['phone']?.toString() ?? '—',
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(bool isDark, Map<String, dynamic> data) {
    final name =
        data['name']?.toString() ??
        '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
    final status = data['status']?.toString() ?? 'Active';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.info.withValues(alpha: 0.1),
            child: AppText(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.info,
            ),
          ),
          const SizedBox(height: 12),
          AppText(
            name,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          AppText.muted(
            data['email']?.toString() ?? '',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          StatusBadge(status: status),
        ],
      ),
    );
  }

  Widget _buildInfoSection(bool isDark, String title, List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: AppText(
              title,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              letterSpacing: 0.5,
            ),
          ),
          ...rows.asMap().entries.map((entry) {
            final isLast = entry.key == rows.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.muted(entry.value.label),
                      AppText(
                        entry.value.value,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    indent: 16,
                  ),
              ],
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});
}
