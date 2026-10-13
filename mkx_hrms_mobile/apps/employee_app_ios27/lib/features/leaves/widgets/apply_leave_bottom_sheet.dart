import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:mkx_core/utils/ui_helpers.dart';
import 'package:provider/provider.dart';

import '../../../widgets/ios27_button.dart';
import '../../../widgets/ios27_text_field.dart';
import '../models/leave_model.dart';
import '../state/leaves_provider.dart';

/**
 * Modal bottom sheet for applying for leaves with iOS 27 Liquid Glass aesthetic.
 */
class ApplyLeaveBottomSheet extends StatefulWidget {
  /**
   * Constructs the leave application bottom sheet modal.
   */
  const ApplyLeaveBottomSheet({super.key});

  @override
  State<ApplyLeaveBottomSheet> createState() => _ApplyLeaveBottomSheetState();
}

class _ApplyLeaveBottomSheetState extends State<ApplyLeaveBottomSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedLeaveType;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final LeavesProvider leaves = context.read<LeavesProvider>();
      if (leaves.masterLeaveTypes.isEmpty) {
        leaves.loadLeaveTypes();
      }
      if (leaves.balances == null) {
        final AuthProvider auth = context.read<AuthProvider>();
        leaves.loadLeaves(
          employeeId: auth.currentUser?.employeeDbId,
          employeeCode: auth.currentUser?.employeeId,
        );
      }
    });
  }

  int get _calculatedDays {
    final int diff = _endDate.difference(_startDate).inDays;
    return diff >= 0 ? diff + 1 : 1;
  }

  /**
   * Opens the liquid glass date picker dialog.
   */
  Future<void> _pickDate({required bool isStart}) async {
    final DateTime initialDate = isStart ? _startDate : _endDate;
    DateTime tempDate = initialDate;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) {
        final bool isDark =
            CupertinoTheme.of(ctx).brightness == Brightness.dark;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 320,
              padding: const EdgeInsets.only(top: 10),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xC70E131E) : const Color(0xDCF6F8FD),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.18)
                      : CupertinoColors.white.withValues(alpha: 0.85),
                  width: 1.0,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: CupertinoColors.black
                        .withValues(alpha: isDark ? 0.60 : 0.18),
                    blurRadius: 40,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF8E8E93)
                                    : const Color(0xFF6E6E73),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                          Text(
                            isStart ? 'Select Start Date' : 'Select End Date',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: -0.3,
                              color: isDark
                                  ? CupertinoColors.white
                                  : const Color(0xFF1C1C1E),
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                if (isStart) {
                                  _startDate = tempDate;
                                  if (_endDate.isBefore(_startDate)) {
                                    _endDate = _startDate;
                                  }
                                } else {
                                  _endDate = tempDate;
                                  if (_startDate.isAfter(_endDate)) {
                                    _startDate = _endDate;
                                  }
                                }
                              });
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: initialDate,
                        minimumDate:
                            DateTime.now().subtract(const Duration(days: 1)),
                        maximumDate:
                            DateTime.now().add(const Duration(days: 365)),
                        onDateTimeChanged: (DateTime newDate) {
                          tempDate = newDate;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /**
   * Opens action sheet to pick from available leave types.
   */
  void _showLeaveTypePicker(List<String> types) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) {
        return CupertinoActionSheet(
          title: const Text('Select Leave Type'),
          actions: types.map((String type) {
            final bool isSelected = type == _selectedLeaveType;
            return CupertinoActionSheetAction(
              onPressed: () {
                setState(() => _selectedLeaveType = type);
                Navigator.of(ctx).pop();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    type,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  if (isSelected) ...<Widget>[
                    const SizedBox(width: 8),
                    const Icon(CupertinoIcons.checkmark_alt, size: 18),
                  ],
                ],
              ),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  /**
   * Validates form and initiates asynchronous leave application submission.
   */
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final AuthProvider auth = context.read<AuthProvider>();
    final LeavesProvider leaves = context.read<LeavesProvider>();

    final String selectedType =
        _selectedLeaveType ?? leaves.leaveTypeNames.first;
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    final bool success = await leaves.submitLeave(
      employeeId: auth.currentUser?.employeeDbId,
      leaveType: selectedType,
      startDate: dateFormat.format(_startDate),
      endDate: dateFormat.format(_endDate),
      reason: _reasonController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      UiHelpers.showSnackBar(
        context,
        'Leave request submitted for approval!',
        isSuccess: true,
      );
    } else {
      UiHelpers.showSnackBar(
        context,
        leaves.errorMessage ?? 'Failed to submit leave request',
        isError: true,
      );
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final Color primary = CupertinoTheme.of(context).primaryColor;
    final LeavesProvider leaves = context.watch<LeavesProvider>();
    final DateFormat dateDisplay = DateFormat('MMM dd, yyyy');

    final List<String> availableNames = leaves.leaveTypeNames;
    if (_selectedLeaveType == null ||
        !availableNames.contains(_selectedLeaveType)) {
      if (availableNames.isNotEmpty) {
        _selectedLeaveType = availableNames.first;
      }
    }

    final Color textPrimary =
        isDark ? CupertinoColors.white : const Color(0xFF1C1C1E);
    final Color textSecondary =
        isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? <Color>[
                        const Color(0xF2121722),
                        const Color(0xFA0B0F17),
                      ]
                    : <Color>[
                        const Color(0xF7FFFFFF),
                        const Color(0xFCF2F5FB),
                      ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.18)
                    : CupertinoColors.white.withValues(alpha: 0.85),
                width: 1.0,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: CupertinoColors.black
                      .withValues(alpha: isDark ? 0.60 : 0.18),
                  blurRadius: 40,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark
                                ? CupertinoColors.white.withValues(alpha: 0.32)
                                : CupertinoColors.black.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(2.5),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: isDark
                                    ? CupertinoColors.black
                                        .withValues(alpha: 0.30)
                                    : CupertinoColors.white
                                        .withValues(alpha: 0.80),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                'Apply for Leave',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: primary.withValues(
                                      alpha: isDark ? 0.22 : 0.14),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: primary.withValues(
                                        alpha: isDark ? 0.45 : 0.30),
                                    width: 0.8,
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: primary.withValues(alpha: 0.18),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '$_calculatedDays ${_calculatedDays == 1 ? "Day" : "Days"}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFF64D2FF)
                                        : primary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(32, 32),
                            onPressed: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? CupertinoColors.white
                                        .withValues(alpha: 0.12)
                                    : CupertinoColors.black
                                        .withValues(alpha: 0.06),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? CupertinoColors.white
                                          .withValues(alpha: 0.20)
                                      : CupertinoColors.black
                                          .withValues(alpha: 0.08),
                                  width: 0.8,
                                ),
                              ),
                              child: Icon(
                                CupertinoIcons.xmark,
                                size: 15,
                                color: isDark
                                    ? CupertinoColors.white
                                    : const Color(0xFF1C1C1E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Submit your time-off request for manager authorization.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Leave Type',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              color: textPrimary,
                            ),
                          ),
                          if (leaves.isLoadingLeaveTypes)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CupertinoActivityIndicator(radius: 7),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          final List<String> names =
                              leaves.masterLeaveTypes.isNotEmpty
                                  ? leaves.masterLeaveTypes
                                      .map((MasterLeaveType t) => t.name)
                                      .toList()
                                  : availableNames;
                          if (names.isNotEmpty) {
                            _showLeaveTypePicker(names);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? CupertinoColors.white.withValues(alpha: 0.06)
                                : CupertinoColors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? CupertinoColors.white
                                      .withValues(alpha: 0.14)
                                  : CupertinoColors.white
                                      .withValues(alpha: 0.45),
                              width: 0.8,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: CupertinoColors.black
                                    .withValues(alpha: isDark ? 0.20 : 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Icon(
                                    CupertinoIcons.square_grid_2x2_fill,
                                    size: 16,
                                    color: isDark
                                        ? const Color(0xFF64D2FF)
                                        : primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _selectedLeaveType ?? 'Select leave type',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedLeaveType != null
                                          ? textPrimary
                                          : textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                CupertinoIcons.chevron_up_chevron_down,
                                size: 15,
                                color: textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildQuotaIndicator(leaves, isDark),
                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Start Date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _pickDate(isStart: true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 13,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? CupertinoColors.white
                                              .withValues(alpha: 0.06)
                                          : CupertinoColors.white
                                              .withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark
                                            ? CupertinoColors.white
                                                .withValues(alpha: 0.14)
                                            : CupertinoColors.white
                                                .withValues(alpha: 0.45),
                                        width: 0.8,
                                      ),
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: CupertinoColors.black
                                              .withValues(
                                                  alpha: isDark ? 0.18 : 0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Icon(
                                          CupertinoIcons.calendar,
                                          size: 16,
                                          color: isDark
                                              ? const Color(0xFF64D2FF)
                                              : primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          dateDisplay.format(_startDate),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'End Date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _pickDate(isStart: false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 13,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? CupertinoColors.white
                                              .withValues(alpha: 0.06)
                                          : CupertinoColors.white
                                              .withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark
                                            ? CupertinoColors.white
                                                .withValues(alpha: 0.14)
                                            : CupertinoColors.white
                                                .withValues(alpha: 0.45),
                                        width: 0.8,
                                      ),
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: CupertinoColors.black
                                              .withValues(
                                                  alpha: isDark ? 0.18 : 0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Icon(
                                          CupertinoIcons.calendar,
                                          size: 16,
                                          color: isDark
                                              ? const Color(0xFF64D2FF)
                                              : primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          dateDisplay.format(_endDate),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
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
                      ),
                      const SizedBox(height: 16),
                      Ios27TextField(
                        controller: _reasonController,
                        label: 'Reason for Leave',
                        placeholder:
                            'Briefly state the reason for this time-off...',
                        maxLines: 3,
                        validator: (String? val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please provide a reason for the leave request';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Ios27Button(
                        onPressed: _handleSubmit,
                        label: 'Submit Leave Request',
                        icon: const Icon(
                          CupertinoIcons.paperplane_fill,
                          size: 17,
                          color: CupertinoColors.white,
                        ),
                        isLoading: leaves.isSubmitting,
                        height: 52,
                        borderRadius: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /**
   * Builds live quota card indicating remaining leave balance and limit checks with liquid glass styling.
   */
  Widget _buildQuotaIndicator(LeavesProvider leaves, bool isDark) {
    final String selectedName = _selectedLeaveType ?? '';
    final List<LeaveQuota> list = leaves.balances?.list ?? <LeaveQuota>[];
    LeaveQuota? quota;
    for (final LeaveQuota item in list) {
      if ((item.name ?? '').toLowerCase() == selectedName.toLowerCase() ||
          (item.code ?? '').toLowerCase() == selectedName.toLowerCase()) {
        quota = item;
        break;
      }
    }

    if (quota == null && leaves.masterLeaveTypes.isNotEmpty) {
      for (final MasterLeaveType type in leaves.masterLeaveTypes) {
        if (type.name.toLowerCase() == selectedName.toLowerCase() ||
            type.code.toLowerCase() == selectedName.toLowerCase()) {
          quota = LeaveQuota(
            id: type.id,
            name: type.name,
            code: type.code,
            total: type.daysPerYear,
            used: 0,
            remaining: type.daysPerYear,
            color: type.color,
            isPaid: type.isPaid,
          );
          break;
        }
      }
    }

    if (quota == null) return const SizedBox.shrink();

    final int remaining = quota.remaining;
    final int total = quota.total;
    final int used = quota.used;
    final bool isExceeded = _calculatedDays > remaining;
    final bool isZero = remaining <= 0;
    final Color color = UiHelpers.parseHexColor(quota.color);

    const Color errorColor = CupertinoColors.systemRed;
    final Color textPrimary =
        isDark ? CupertinoColors.white : const Color(0xFF1C1C1E);
    final Color textSecondary =
        isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isExceeded
            ? errorColor.withValues(alpha: isDark ? 0.18 : 0.09)
            : (isDark
                ? CupertinoColors.white.withValues(alpha: 0.05)
                : CupertinoColors.white.withValues(alpha: 0.60)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExceeded
              ? errorColor.withValues(alpha: 0.50)
              : (isDark
                  ? CupertinoColors.white.withValues(alpha: 0.12)
                  : CupertinoColors.white.withValues(alpha: 0.40)),
          width: 0.8,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color:
                CupertinoColors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    isExceeded
                        ? CupertinoIcons.exclamationmark_triangle_fill
                        : CupertinoIcons.briefcase_fill,
                    size: 15,
                    color: isExceeded ? errorColor : color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Available Balance',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isExceeded ? errorColor : textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '$remaining / $total Days Left',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isExceeded ? errorColor : color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 5,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: isExceeded ? errorColor : color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: (isExceeded ? errorColor : color)
                            .withValues(alpha: 0.40),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '$used used • $total allocated',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
              if (isExceeded)
                Text(
                  isZero
                      ? 'No balance left'
                      : 'Exceeds quota by ${_calculatedDays - remaining}d',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: errorColor,
                  ),
                )
              else
                Text(
                  '$_calculatedDays ${_calculatedDays == 1 ? "day" : "days"} requested',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
