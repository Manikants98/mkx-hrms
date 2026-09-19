import 'package:flutter/material.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/widgets/section_tile.dart';
import 'package:mkx_core/widgets/status_badge.dart';
import '../models/payslip_model.dart';

/// Detailed itemized salary slip modal bottom sheet
class PayslipDetailModal extends StatelessWidget {
  final Payslip slip;

  const PayslipDetailModal({super.key, required this.slip});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBackground
            : AppColors
                  .lightBackground, // Changed to background color so cards stand out
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payslip Summary',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          slip.monthLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkMuted
                                : AppColors.lightMuted,
                          ),
                        ),
                      ],
                    ),
                    StatusBadge(status: slip.status),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Net Pay Card Highlight
              SectionTile(
                isDark: isDark,
                position: TilePosition.only,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Disbursed Amount',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkMuted
                            : AppColors.lightMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      slip.formattedNetPay,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppColors.darkMuted
                                    : AppColors.lightMuted)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Credited on ${slip.payDate}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkMuted
                              : AppColors.lightMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildSectionHeader('Employee Details', isDark),
              SectionCard(
                isDark: isDark,
                children: [
                  _buildRow(
                    'Employee Name',
                    slip.employeeName,
                    isDark,
                    isBoldValue: true,
                  ),
                  _buildRow('Designation', slip.role, isDark),
                  _buildRow('Department', slip.department, isDark),
                  _buildRow('Payroll Code', slip.payrollCode, isDark),
                ],
              ),
              const SizedBox(height: 16),

              _buildSectionHeader('Attendance & Calendar', isDark),
              SectionCard(
                isDark: isDark,
                children: [
                  _buildRow(
                    'Working Days in Month',
                    '${slip.workingDays} days',
                    isDark,
                  ),
                  _buildRow(
                    'Paid Days',
                    '${slip.paidDays} days',
                    isDark,
                    isBoldValue: true,
                  ),
                  if (slip.lopDays > 0)
                    _buildRow(
                      'Loss of Pay (Unpaid Leave)',
                      '${slip.lopDays} days',
                      isDark,
                      valueColor: AppColors.error,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              _buildSectionHeader('Earnings & Allowances', isDark),
              if (slip.items.any((i) => i.category == 'Earning'))
                SectionCard(
                  isDark: isDark,
                  children: slip.items
                      .where((i) => i.category == 'Earning')
                      .map(
                        (it) => _buildRow(
                          it.name,
                          '+${it.amount.toStringAsFixed(2)}',
                          isDark,
                          valueColor: AppColors.success,
                        ),
                      )
                      .toList(),
                )
              else
                SectionCard(
                  isDark: isDark,
                  children: [
                    _buildRow('Base Salary', slip.formattedBase, isDark),
                    _buildRow(
                      'Allowances & Benefits',
                      slip.formattedAllowance,
                      isDark,
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              if (slip.items.any((i) => i.category == 'Deduction') ||
                  slip.totalDeductions > 0) ...[
                _buildSectionHeader('Deductions & Statutory Taxes', isDark),
                if (slip.items.any((i) => i.category == 'Deduction'))
                  SectionCard(
                    isDark: isDark,
                    children: slip.items
                        .where((i) => i.category == 'Deduction')
                        .map(
                          (it) => _buildRow(
                            it.name,
                            '-${it.amount.toStringAsFixed(2)}',
                            isDark,
                            valueColor: AppColors.error,
                          ),
                        )
                        .toList(),
                  )
                else
                  SectionCard(
                    isDark: isDark,
                    children: [
                      _buildRow(
                        'Total Deductions',
                        slip.formattedDeductions,
                        isDark,
                        valueColor: AppColors.error,
                      ),
                    ],
                  ),
              ],

              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Net Pay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      slip.formattedNetPay,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value,
    bool isDark, {
    bool isBoldValue = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBoldValue ? FontWeight.w700 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
