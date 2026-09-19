import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart' as m3e;
import 'package:provider/provider.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/utils/ui_helpers.dart';
import 'package:mkx_core/widgets/app_avatar.dart';
import 'package:mkx_core/widgets/empty_state.dart';
import '../../../widgets/m3_expressive_loader.dart';
import 'package:mkx_core/widgets/metric_card.dart';
import 'package:mkx_core/widgets/mkx_app_bar.dart';
import 'package:mkx_core/widgets/section_tile.dart';
import 'package:mkx_core/widgets/status_badge.dart';
import '../models/hr_payroll_model.dart';
import '../state/hr_payroll_provider.dart';

/// HR Payroll Processing — matches employee_app structure and UI patterns
class HrPayrollScreen extends StatefulWidget {
  const HrPayrollScreen({super.key});

  @override
  State<HrPayrollScreen> createState() => _HrPayrollScreenState();
}

class _HrPayrollScreenState extends State<HrPayrollScreen> {
  String _statusFilter = 'All';
  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HrPayrollProvider>().loadPayroll();
    });
  }

  Future<void> _showMonthPicker(
    BuildContext context,
    HrPayrollProvider provider,
  ) async {
    int selectedMonth = provider.selectedMonth;
    int selectedYear = provider.selectedYear;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Month & Year',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: () =>
                                setModalState(() => selectedYear--),
                          ),
                          Text(
                            '$selectedYear',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            onPressed: () =>
                                setModalState(() => selectedYear++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: 12,
                    itemBuilder: (context, i) {
                      final selected = selectedMonth == i + 1;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedMonth = i + 1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : (isDark
                                      ? AppColors.darkSecondary
                                      : AppColors.lightSecondary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _monthNames[i].substring(0, 3),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : (isDark
                                        ? AppColors.darkForeground
                                        : AppColors.lightForeground),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: m3e.M3EButton(
                      style: m3e.M3EButtonStyle.filled,
                      size: m3e.M3EButtonSize.md,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        provider.setMonthYear(selectedMonth, selectedYear);
                      },
                      child: const Text(
                        'Apply',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<HrPayrollProvider>();

    final filteredPayrolls = provider.payrolls.where((p) {
      if (_statusFilter == 'Pending') return p.status.toLowerCase() == 'pending';
      if (_statusFilter == 'Processed') return p.status.toLowerCase() == 'processed';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: MkxAppBar(
        title: 'Payroll',
        subtitle:
            '${_monthNames[provider.selectedMonth - 1]} ${provider.selectedYear}',
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_month_rounded,
              size: 19,
              color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
            ),
            tooltip: 'Select Month',
            onPressed: () => _showMonthPicker(context, provider),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => provider.loadPayroll(),
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummary(isDark, provider),
                const SizedBox(height: 10),
                _buildFilterChips(isDark, provider),
                const SizedBox(height: 10),
                if (provider.isLoading && provider.payrolls.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: M3ExpressiveLoader.contained(size: 52),
                    ),
                  )
                else if (filteredPayrolls.isEmpty)
                  EmptyState(
                    icon: Icons.payments_outlined,
                    title: 'No $_statusFilter payroll records',
                    description:
                        'No payroll data found for ${_monthNames[provider.selectedMonth - 1]} ${provider.selectedYear}',
                  )
                else
                  SectionCard(
                    isDark: isDark,
                    children: filteredPayrolls.map((payroll) {
                      return _PayrollRow(payroll: payroll, isDark: isDark);
                    }).toList(),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark, HrPayrollProvider provider) {
    final filters = [
      ('All', Icons.receipt_long_rounded, provider.payrolls.length),
      ('Pending', Icons.pending_actions_rounded, provider.pendingCount),
      ('Processed', Icons.check_circle_outline_rounded, provider.processedCount),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _statusFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: m3e.M3EChip(
              label: '${f.$1} (${f.$3})',
              type: m3e.M3EChipType.filter,
              selected: isSelected,
              elevated: isSelected,
              leading: Icon(
                f.$2,
                size: 14,
                color: isSelected
                    ? (isDark
                        ? AppColors.darkPrimaryForeground
                        : AppColors.lightPrimaryForeground)
                    : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
              ),
              onPressed: () => setState(() => _statusFilter = f.$1),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummary(bool isDark, HrPayrollProvider provider) {
    return Row(
      children: [
        Expanded(
          child: MetricCard(
            title: 'Pending',
            value: provider.pendingCount.toString(),
            subtext: 'Requires processing',
            icon: Icons.pending_actions_rounded,
            iconColor: AppColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MetricCard(
            title: 'Processed',
            value: provider.processedCount.toString(),
            subtext: 'Disbursed / locked',
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _PayrollRow extends StatelessWidget {
  final HrPayrollModel payroll;
  final bool isDark;

  const _PayrollRow({required this.payroll, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<HrPayrollProvider>();
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final isPending = payroll.status.toLowerCase() == 'pending';
    final primaryColor = Theme.of(context).colorScheme.primary;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(name: payroll.employeeName, size: 36, borderRadius: 8),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payroll.employeeName,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    [
                      if (payroll.role != null && payroll.role!.isNotEmpty)
                        payroll.role,
                      if (payroll.department != null &&
                          payroll.department!.isNotEmpty)
                        payroll.department,
                    ].join(' • '),
                    style: TextStyle(fontSize: 11.5, color: mutedColor),
                  ),
                ],
              ),
            ),
            StatusBadge(status: payroll.status),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SalaryCol(
                label: 'Basic',
                value: currencyFormat.format(payroll.basicSalary),
                isDark: isDark,
              ),
              _SalaryCol(
                label: 'Allowances',
                value: currencyFormat.format(payroll.allowances),
                color: AppColors.success,
                isDark: isDark,
              ),
              _SalaryCol(
                label: 'Deductions',
                value: currencyFormat.format(payroll.deductions),
                color: AppColors.error,
                isDark: isDark,
              ),
              _SalaryCol(
                label: 'Net Pay',
                value: currencyFormat.format(payroll.netSalary),
                color: primaryColor,
                isBold: true,
                isDark: isDark,
              ),
            ],
          ),
        ),
        if (isPending) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: m3e.M3EButton(
              style: m3e.M3EButtonStyle.outlined,
              size: m3e.M3EButtonSize.sm,
              onPressed: provider.isProcessing(payroll.id)
                  ? null
                  : () => _handleProcess(context, provider, payroll),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (provider.isProcessing(payroll.id))
                    M3ExpressiveLoader.button(
                      size: 14,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                    )
                  else
                    const Icon(Icons.play_arrow_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    provider.isProcessing(payroll.id)
                        ? 'Processing...'
                        : 'Process Payroll',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleProcess(
    BuildContext context,
    HrPayrollProvider provider,
    HrPayrollModel payroll,
  ) async {
    final confirmed = await UiHelpers.showConfirmDialog(
      context: context,
      title: 'Process Payroll',
      message:
          'Process payroll for ${payroll.employeeName}?\nNet Pay: ₹${payroll.netSalary.toStringAsFixed(0)}',
      confirmText: 'Process',
    );
    if (confirmed == true && context.mounted) {
      final ok = await provider.processPayroll(payroll.id);
      if (context.mounted) {
        UiHelpers.showSnackBar(
          context,
          ok
              ? 'Payroll processed for ${payroll.employeeName}'
              : (provider.errorMessage ?? 'Failed to process payroll'),
          isSuccess: ok,
          isError: !ok,
        );
      }
    }
  }
}

class _SalaryCol extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool isBold;
  final bool isDark;

  const _SalaryCol({
    required this.label,
    required this.value,
    this.color,
    this.isBold = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
