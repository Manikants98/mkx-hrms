import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:mkx_core/utils/ui_helpers.dart';
import 'package:provider/provider.dart';

import '../../../widgets/ios27_text_field.dart';
import '../models/leave_model.dart';
import '../state/leaves_provider.dart';

/// Modal bottom sheet for applying for leaves in Cupertino iOS 27 style
class ApplyLeaveBottomSheet extends StatefulWidget {
  const ApplyLeaveBottomSheet({super.key});

  @override
  State<ApplyLeaveBottomSheet> createState() => _ApplyLeaveBottomSheetState();
}

class _ApplyLeaveBottomSheetState extends State<ApplyLeaveBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedLeaveType;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final leaves = context.read<LeavesProvider>();
      if (leaves.masterLeaveTypes.isEmpty) {
        leaves.loadLeaveTypes();
      }
      if (leaves.balances == null) {
        final auth = context.read<AuthProvider>();
        leaves.loadLeaves(
          employeeId: auth.currentUser?.employeeDbId,
          employeeCode: auth.currentUser?.employeeId,
        );
      }
    });
  }

  int get _calculatedDays {
    final diff = _endDate.difference(_startDate).inDays;
    return diff >= 0 ? diff + 1 : 1;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    DateTime tempDate = initialDate;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) {
        return Container(
          height: 300,
          padding: const EdgeInsets.only(top: 6),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: CupertinoTheme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    Text(
                      isStart ? 'Select Start Date' : 'Select End Date',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    CupertinoButton(
                      child: const Text('Done',
                          style: TextStyle(fontWeight: FontWeight.w600)),
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
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate,
                    minimumDate:
                        DateTime.now().subtract(const Duration(days: 1)),
                    maximumDate: DateTime.now().add(const Duration(days: 365)),
                    onDateTimeChanged: (DateTime newDate) {
                      tempDate = newDate;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLeaveTypePicker(List<String> types) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) {
        return CupertinoActionSheet(
          title: const Text('Select Leave Type'),
          actions: types.map((type) {
            final isSelected = type == _selectedLeaveType;
            return CupertinoActionSheetAction(
              onPressed: () {
                setState(() => _selectedLeaveType = type);
                Navigator.of(ctx).pop();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    type,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  if (isSelected) ...[
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final leaves = context.read<LeavesProvider>();

    final selectedType = _selectedLeaveType ?? leaves.leaveTypeNames.first;
    final dateFormat = DateFormat('yyyy-MM-dd');
    final success = await leaves.submitLeave(
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
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final primary = CupertinoTheme.of(context).primaryColor;
    final leaves = context.watch<LeavesProvider>();
    final dateDisplay = DateFormat('MMM dd, yyyy');

    final availableNames = leaves.leaveTypeNames;
    if (_selectedLeaveType == null ||
        !availableNames.contains(_selectedLeaveType)) {
      if (availableNames.isNotEmpty) {
        _selectedLeaveType = availableNames.first;
      }
    }

    final surfaceColor =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
    final textPrimary =
        isDark ? CupertinoColors.white : const Color(0xFF1C1C1E);
    final textSecondary =
        isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFA161B26) : const Color(0xFAF8F9FD),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? CupertinoColors.white.withValues(alpha: 0.18)
                : CupertinoColors.white.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                CupertinoColors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.25)
                          : CupertinoColors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Sheet Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Apply for Leave',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_calculatedDays ${_calculatedDays == 1 ? "Day" : "Days"}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 22,
                        color: isDark
                            ? CupertinoColors.systemGrey
                            : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Submit your time-off request for manager authorization.',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Leave Type Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Leave Type',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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
                    final names = leaves.masterLeaveTypes.isNotEmpty
                        ? leaves.masterLeaveTypes.map((t) => t.name).toList()
                        : availableNames;
                    if (names.isNotEmpty) {
                      _showLeaveTypePicker(names);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedLeaveType ?? 'Select leave type',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _selectedLeaveType != null
                                ? textPrimary
                                : textSecondary,
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_up_chevron_down,
                          size: 16,
                          color: textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                _buildQuotaIndicator(leaves, isDark),
                const SizedBox(height: 16),

                // Date Selectors
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Date',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
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
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.calendar,
                                    size: 16,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    dateDisplay.format(_startDate),
                                    style: TextStyle(
                                      fontSize: 13,
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
                        children: [
                          Text(
                            'End Date',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
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
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.calendar,
                                    size: 16,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    dateDisplay.format(_endDate),
                                    style: TextStyle(
                                      fontSize: 13,
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

                // Reason Input
                Ios27TextField(
                  controller: _reasonController,
                  label: 'Reason for Leave',
                  placeholder: 'Briefly state the reason for this time-off...',
                  maxLines: 3,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please provide a reason for the leave request';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                if (leaves.isSubmitting)
                  const Center(
                    child: SizedBox(
                      height: 50,
                      child: CupertinoActivityIndicator(radius: 14),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _handleSubmit,
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primary,
                            HSLColor.fromColor(primary)
                                .withLightness(
                                    (HSLColor.fromColor(primary).lightness -
                                            0.12)
                                        .clamp(0.0, 1.0))
                                .toColor(),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.paperplane_fill,
                              size: 18, color: CupertinoColors.white),
                          SizedBox(width: 8),
                          Text(
                            'Submit Leave Request',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
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
      ),
    );
  }

  /// Builds live quota card indicating remaining leave balance and limit checks
  Widget _buildQuotaIndicator(LeavesProvider leaves, bool isDark) {
    final selectedName = _selectedLeaveType ?? '';
    final list = leaves.balances?.list ?? [];
    LeaveQuota? quota;
    for (final item in list) {
      if ((item.name ?? '').toLowerCase() == selectedName.toLowerCase() ||
          (item.code ?? '').toLowerCase() == selectedName.toLowerCase()) {
        quota = item;
        break;
      }
    }

    if (quota == null && leaves.masterLeaveTypes.isNotEmpty) {
      for (final type in leaves.masterLeaveTypes) {
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

    final remaining = quota.remaining;
    final total = quota.total;
    final used = quota.used;
    final isExceeded = _calculatedDays > remaining;
    final isZero = remaining <= 0;
    final color = UiHelpers.parseHexColor(quota.color);

    final errorColor = CupertinoColors.systemRed;
    final textPrimary =
        isDark ? CupertinoColors.white : const Color(0xFF1C1C1E);
    final textSecondary =
        isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isExceeded
            ? errorColor.withValues(alpha: 0.12)
            : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
        borderRadius: BorderRadius.circular(10),
        border: isExceeded
            ? Border.all(color: errorColor.withValues(alpha: 0.4))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isExceeded
                        ? CupertinoIcons.exclamationmark_triangle_fill
                        : CupertinoIcons.briefcase_fill,
                    size: 15,
                    color: isExceeded ? errorColor : color,
                  ),
                  const SizedBox(width: 6),
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
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: isExceeded ? errorColor : color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$used used • $total allocated',
                style: TextStyle(
                  fontSize: 11,
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
