import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../widgets/ios27_status_badge.dart';
import '../../../widgets/ios27_glass_surface.dart';
import '../models/payslip_model.dart';

/// Detailed itemized salary slip screen with iOS 27 Liquid Glass design.
class PayslipDetailScreen extends StatelessWidget {
  /// The payslip model instance to render.
  final Payslip slip;

  /// Creates a payslip detail presentation screen.
  const PayslipDetailScreen({super.key, required this.slip});

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: Ios27Background(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    GlassIconButton(
                      icon: Icon(
                        CupertinoIcons.chevron_back,
                        size: 20,
                        color: isDark
                            ? CupertinoColors.white
                            : const Color(0xFF1C1C1E),
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Payslip Summary',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF6E6E73),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            slip.monthLabel,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isDark
                                  ? CupertinoColors.white
                                  : const Color(0xFF1C1C1E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Ios27StatusBadge(status: slip.status),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Ios27GlassCard(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        quality: GlassQuality.premium,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Net Disbursed Compensation',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF8E8E93)
                                    : const Color(0xFF6E6E73),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              slip.formattedNetPay,
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.2,
                                color: Color(0xFF34C759),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? CupertinoColors.white
                                        .withValues(alpha: 0.08)
                                    : CupertinoColors.black
                                        .withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Credited on ${slip.payDate} • Automated Payroll',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFFD1D1D6)
                                      : const Color(0xFF3A3A3C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Ios27SectionHeader(title: 'Employee Details'),
                      Ios27GlassCard(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Column(
                          children: [
                            _buildRow(
                                'Employee Name', slip.employeeName, isDark,
                                isBoldValue: true),
                            _buildDivider(isDark),
                            _buildRow('Designation', slip.role, isDark),
                            _buildDivider(isDark),
                            _buildRow('Department', slip.department, isDark),
                            _buildDivider(isDark),
                            _buildRow('Payroll Code', slip.payrollCode, isDark),
                          ],
                        ),
                      ),
                      const Ios27SectionHeader(title: 'Attendance & Calendar'),
                      Ios27GlassCard(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Column(
                          children: [
                            _buildRow('Working Days in Month',
                                '${slip.workingDays} days', isDark),
                            _buildDivider(isDark),
                            _buildRow(
                                'Paid Days', '${slip.paidDays} days', isDark,
                                isBoldValue: true),
                            if (slip.lopDays > 0) ...[
                              _buildDivider(isDark),
                              _buildRow(
                                'Loss of Pay (Unpaid Leave)',
                                '${slip.lopDays} days',
                                isDark,
                                valueColor: const Color(0xFFFF3B30),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Ios27SectionHeader(title: 'Earnings & Allowances'),
                      Ios27GlassCard(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Column(
                          children: slip.items.any(
                                  (PayslipItem i) => i.category == 'Earning')
                              ? slip.items
                                  .where((PayslipItem i) =>
                                      i.category == 'Earning')
                                  .map(
                                    (PayslipItem it) => _buildRow(
                                      it.name,
                                      '+${it.amount.toStringAsFixed(2)}',
                                      isDark,
                                      valueColor: const Color(0xFF34C759),
                                    ),
                                  )
                                  .toList()
                              : [
                                  _buildRow('Base Salary', slip.formattedBase,
                                      isDark),
                                  _buildDivider(isDark),
                                  _buildRow('Allowances & Benefits',
                                      slip.formattedAllowance, isDark),
                                ],
                        ),
                      ),
                      if (slip.items.any(
                              (PayslipItem i) => i.category == 'Deduction') ||
                          slip.totalDeductions > 0) ...[
                        const Ios27SectionHeader(
                            title: 'Deductions & Statutory Taxes'),
                        Ios27GlassCard(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Column(
                            children: slip.items.any((PayslipItem i) =>
                                    i.category == 'Deduction')
                                ? slip.items
                                    .where((PayslipItem i) =>
                                        i.category == 'Deduction')
                                    .map(
                                      (PayslipItem it) => _buildRow(
                                        it.name,
                                        '-${it.amount.toStringAsFixed(2)}',
                                        isDark,
                                        valueColor: const Color(0xFFFF3B30),
                                      ),
                                    )
                                    .toList()
                                : [
                                    _buildRow(
                                      'Total Deductions',
                                      slip.formattedDeductions,
                                      isDark,
                                      valueColor: const Color(0xFFFF3B30),
                                    ),
                                  ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Ios27GlassCard(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Net Payable Salary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? CupertinoColors.white
                                    : const Color(0xFF1C1C1E),
                              ),
                            ),
                            Text(
                              slip.formattedNetPay,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF34C759),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a subtle glass row divider.
  Widget _buildDivider(bool isDark) {
    return Container(
      height: 0.6,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isDark ? const Color(0x1AFFFFFF) : const Color(0x14000000),
    );
  }

  /// Builds a key-value data row.
  Widget _buildRow(
    String label,
    String value,
    bool isDark, {
    bool isBoldValue = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBoldValue ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ??
                  (isDark ? CupertinoColors.white : const Color(0xFF1C1C1E)),
            ),
          ),
        ],
      ),
    );
  }
}
