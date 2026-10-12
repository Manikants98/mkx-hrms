import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import '../../../widgets/ios27_status_badge.dart';
import 'package:provider/provider.dart';

import '../../../widgets/ios27_glass_surface.dart';
import '../../../widgets/ios27_loader.dart';
import '../../../widgets/ios27_pull_to_refresh.dart';
import '../models/payslip_model.dart';
import '../state/payroll_provider.dart';
import 'payslip_detail_screen.dart';

/// Employee Salary Slips & Compensation Screen with iOS 27 Liquid Glass styling.
class PayrollScreen extends StatefulWidget {
  /// Constructs the payroll overview screen.
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  /// Fetches monthly payroll statements from the backend service.
  Future<void> _loadData() async {
    final AuthProvider auth = context.read<AuthProvider>();
    final PayrollProvider payroll = context.read<PayrollProvider>();
    await payroll.loadPayroll(
      employeeId: auth.currentUser?.employeeDbId,
      employeeCode: auth.currentUser?.employeeId,
    );
  }

  /// Opens the itemized payslip breakdown screen.
  void _openDetailModal(Payslip slip) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => PayslipDetailScreen(slip: slip),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final Color primaryColor = CupertinoTheme.of(context).primaryColor;
    final PayrollProvider payroll = context.watch<PayrollProvider>();
    final Payslip? latest = payroll.latestPayslip;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Compensation & Earnings',
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
                        'Payslips',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: isDark
                              ? CupertinoColors.white
                              : const Color(0xFF1C1C1E),
                        ),
                      ),
                    ],
                  ),
                  GlassIconButton(
                    icon: Icon(
                      CupertinoIcons.doc_text_viewfinder,
                      size: 19,
                      color: isDark
                          ? CupertinoColors.white
                          : const Color(0xFF1C1C1E),
                    ),
                    onPressed: () {
                      if (latest != null) _openDetailModal(latest);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Ios27PageLoader(
                isLoading: payroll.isLoading && payroll.slips.isEmpty,
                message: 'Loading Salary Slips...',
                child: Ios27RefreshableScrollView(
                  onRefresh: _loadData,
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
                    if (payroll.slips.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Ios27GlassCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.doc_text,
                                size: 44,
                                color: isDark
                                    ? CupertinoColors.white
                                        .withValues(alpha: 0.4)
                                    : const Color(0xFF8E8E93),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No salary slips generated yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? CupertinoColors.white
                                      : const Color(0xFF1C1C1E),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Your monthly remuneration statements will appear here after payroll processing.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? CupertinoColors.white
                                          .withValues(alpha: 0.6)
                                      : const Color(0xFF6C6C70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      if (latest != null) ...[
                        const Ios27SectionHeader(title: 'Latest Disbursement'),
                        Ios27GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${latest.monthLabel} Statement',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFF8E8E93)
                                          : const Color(0xFF6E6E73),
                                    ),
                                  ),
                                  Ios27StatusBadge(status: latest.status),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                latest.formattedNetPay,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                  color: Color(0xFF34C759),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Paid on ${latest.payDate} • Direct Bank Transfer',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? const Color(0xFFA1A1A6)
                                      : const Color(0xFF636366),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? CupertinoColors.white
                                                .withValues(alpha: 0.06)
                                            : CupertinoColors.black
                                                .withValues(alpha: 0.03),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Base Salary',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? const Color(0xFF8E8E93)
                                                  : const Color(0xFF6E6E73),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            latest.formattedBase,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? CupertinoColors.white
                                                  : const Color(0xFF1C1C1E),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? CupertinoColors.white
                                                .withValues(alpha: 0.06)
                                            : CupertinoColors.black
                                                .withValues(alpha: 0.03),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Allowances',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? const Color(0xFF8E8E93)
                                                  : const Color(0xFF6E6E73),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            latest.formattedAllowance,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF34C759),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? CupertinoColors.white
                                                .withValues(alpha: 0.06)
                                            : CupertinoColors.black
                                                .withValues(alpha: 0.03),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Deductions',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? const Color(0xFF8E8E93)
                                                  : const Color(0xFF6E6E73),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            latest.formattedDeductions,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFFF3B30),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => _openDetailModal(latest),
                                child: Container(
                                  height: 44,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color:
                                          primaryColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(CupertinoIcons.doc_plaintext,
                                          size: 16, color: primaryColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        'View Full Itemized Statement',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Ios27SectionHeader(title: 'Disbursement Archive'),
                      Ios27GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Column(
                          children: payroll.slips.map((Payslip slip) {
                            return CupertinoButton(
                              padding: EdgeInsets.only(bottom: 10),
                              minimumSize: Size.zero,
                              onPressed: () => _openDetailModal(slip),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF34C759)
                                            .withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.doc_text_fill,
                                        color: Color(0xFF34C759),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            slip.monthLabel,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? CupertinoColors.white
                                                  : const Color(0xFF1C1C1E),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Paid: ${slip.payDate}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? const Color(0xFF8E8E93)
                                                  : const Color(0xFF6E6E73),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          slip.formattedNetPay,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? CupertinoColors.white
                                                : const Color(0xFF1C1C1E),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Ios27StatusBadge(status: slip.status),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
