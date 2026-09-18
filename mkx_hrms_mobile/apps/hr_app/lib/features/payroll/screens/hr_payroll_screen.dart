import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/utils/ui_helpers.dart';
import 'package:mkx_core/widgets/app_text.dart';
import 'package:mkx_core/widgets/empty_state.dart';
import 'package:mkx_core/widgets/metric_card.dart';
import 'package:mkx_core/widgets/status_badge.dart';
import '../models/hr_payroll_model.dart';
import '../state/hr_payroll_provider.dart';

/// HR Payroll Processing — monthly records with process action and salary details
class HrPayrollScreen extends StatefulWidget {
  const HrPayrollScreen({super.key});

  @override
  State<HrPayrollScreen> createState() => _HrPayrollScreenState();
}

class _HrPayrollScreenState extends State<HrPayrollScreen> {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark),
            _buildSummary(isDark),
            Expanded(child: _buildList(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Consumer<HrPayrollProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText.heading('Payroll'),
                    AppText.muted(
                      '${_monthNames[provider.selectedMonth - 1]} ${provider.selectedYear}',
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _showMonthPicker(context, provider),
                icon: const Icon(Icons.calendar_month_rounded, size: 16),
                label: const AppText.label('Month'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummary(bool isDark) {
    return Consumer<HrPayrollProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'Pending',
                  value: provider.pendingCount.toString(),
                  icon: Icons.pending_rounded,
                  iconColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricCard(
                  title: 'Processed',
                  value: provider.processedCount.toString(),
                  icon: Icons.check_circle_rounded,
                  iconColor: AppColors.success,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(bool isDark) {
    return Consumer<HrPayrollProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.payrolls.isEmpty) {
          return EmptyState(
            icon: Icons.payments_outlined,
            title: 'No payroll records',
            description:
                'No payroll data for ${_monthNames[provider.selectedMonth - 1]} ${provider.selectedYear}',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadPayroll(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: provider.payrolls.length,
            itemBuilder: (context, i) {
              return _PayrollCard(
                payroll: provider.payrolls[i],
                isDark: isDark,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showMonthPicker(
    BuildContext context,
    HrPayrollProvider provider,
  ) async {
    int selectedMonth = provider.selectedMonth;
    int selectedYear = provider.selectedYear;

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppText.title('Select Month'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => setModalState(() => selectedYear--),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      AppText.title('$selectedYear'),
                      IconButton(
                        onPressed: () => setModalState(() => selectedYear++),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                                ? AppColors.info
                                : (isDark
                                      ? AppColors.darkSecondary
                                      : AppColors.lightSecondary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: AppText(
                            _monthNames[i].substring(0, 3),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? Colors.white
                                : (isDark
                                      ? AppColors.darkForeground
                                      : AppColors.lightForeground),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        provider.setMonthYear(selectedMonth, selectedYear);
                      },
                      child: const Text('Apply'),
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
}

class _PayrollCard extends StatelessWidget {
  final HrPayrollModel payroll;
  final bool isDark;

  const _PayrollCard({required this.payroll, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<HrPayrollProvider>();
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final isPending = payroll.status.toLowerCase() == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.info.withValues(alpha: 0.1),
                  child: AppText(
                    payroll.employeeName.isNotEmpty
                        ? payroll.employeeName[0].toUpperCase()
                        : '?',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.bodyBold(payroll.employeeName),
                      AppText.caption(
                        '${payroll.employeeCode}${payroll.department != null ? ' • ${payroll.department}' : ''}',
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: payroll.status),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSecondary
                    : AppColors.lightSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SalaryItem(
                    label: 'Basic',
                    value: currencyFormat.format(payroll.basicSalary),
                  ),
                  _SalaryItem(
                    label: 'Allowances',
                    value: currencyFormat.format(payroll.allowances),
                    valueColor: AppColors.success,
                  ),
                  _SalaryItem(
                    label: 'Deductions',
                    value: currencyFormat.format(payroll.deductions),
                    valueColor: AppColors.error,
                  ),
                  _SalaryItem(
                    label: 'Net Pay',
                    value: currencyFormat.format(payroll.netSalary),
                    valueColor: AppColors.info,
                    isBold: true,
                  ),
                ],
              ),
            ),
            if (isPending) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: provider.isProcessing(payroll.id)
                      ? null
                      : () => _handleProcess(context, provider, payroll),
                  icon: provider.isProcessing(payroll.id)
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 16),
                  label: AppText(
                    provider.isProcessing(payroll.id)
                        ? 'Processing...'
                        : 'Process Payroll',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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

class _SalaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _SalaryItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppText.caption(label),
        const SizedBox(height: 2),
        AppText(
          value,
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: valueColor,
        ),
      ],
    );
  }
}
