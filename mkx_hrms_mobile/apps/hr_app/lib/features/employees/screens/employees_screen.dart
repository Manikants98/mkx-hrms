import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/widgets/empty_state.dart';
import 'package:mkx_core/widgets/mkx_app_bar.dart';
import 'package:mkx_core/widgets/section_tile.dart';
import 'package:mkx_core/widgets/status_badge.dart';
import '../models/employee_list_model.dart';
import '../state/employees_provider.dart';

/// HR Employee Directory — matches employee_app structure and UI patterns
class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final _searchController = TextEditingController();

  static const List<String> _departments = [
    'All',
    'Engineering',
    'Sales',
    'HR',
    'Finance',
    'Operations',
    'Marketing',
  ];

  static const List<String> _statuses = ['All', 'Active', 'Inactive'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeesProvider>().loadEmployees();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: const MkxAppBar(
        title: 'Employees',
        subtitle: 'Workforce directory & staff records',
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => context.read<EmployeesProvider>().loadEmployees(),
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(isDark),
                const SizedBox(height: 10),
                _buildFilterChips(isDark),
                const SizedBox(height: 10),
                _buildEmployeeList(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return TextField(
      controller: _searchController,
      style: GoogleFonts.inter(fontSize: 13.5),
      decoration: InputDecoration(
        hintText: 'Search by name, email or code...',
        hintStyle: GoogleFonts.inter(
          fontSize: 13.5,
          color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                  context.read<EmployeesProvider>().setSearch('');
                },
              )
            : null,
        filled: true,
        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
      onChanged: (q) {
        setState(() {});
        context.read<EmployeesProvider>().setSearch(q);
      },
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final provider = context.watch<EmployeesProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _departments.map((dept) {
              final isSelected =
                  provider.departmentFilter == dept ||
                  (dept == 'All' && provider.departmentFilter.isEmpty);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    dept,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? (isDark
                                ? AppColors.darkPrimaryForeground
                                : AppColors.lightPrimaryForeground)
                          : (isDark
                                ? AppColors.darkMuted
                                : AppColors.lightMuted),
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) =>
                      provider.setDepartmentFilter(dept == 'All' ? '' : dept),
                  backgroundColor: isDark
                      ? AppColors.darkSecondary
                      : AppColors.lightSecondary,
                  selectedColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.lightPrimary,
                  showCheckmark: false,
                  side: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _statuses.map((status) {
              final isSelected =
                  provider.statusFilter == status ||
                  (status == 'All' && provider.statusFilter.isEmpty);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    status,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? (isDark
                                ? AppColors.darkPrimaryForeground
                                : AppColors.lightPrimaryForeground)
                          : (isDark
                                ? AppColors.darkMuted
                                : AppColors.lightMuted),
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) =>
                      provider.setStatusFilter(status == 'All' ? '' : status),
                  backgroundColor: isDark
                      ? AppColors.darkSecondary
                      : AppColors.lightSecondary,
                  selectedColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.lightPrimary,
                  showCheckmark: false,
                  side: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeList(bool isDark) {
    final provider = context.watch<EmployeesProvider>();

    if (provider.isLoading && provider.employees.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (provider.employees.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No employees found',
        description: provider.searchQuery.isNotEmpty
            ? 'Try adjusting your search or clear filters'
            : 'No employees match the selected department or status criteria',
      );
    }

    return SectionCard(
      isDark: isDark,
      children: provider.employees.map((emp) {
        return _EmployeeRow(
          employee: emp,
          isDark: isDark,
          onTap: () {
            final targetId = emp.id > 0 ? emp.id.toString() : emp.employeeCode;
            context.push('/employees/$targetId');
          },
        );
      }).toList(),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  final EmployeeListModel employee;
  final bool isDark;
  final VoidCallback onTap;

  const _EmployeeRow({
    required this.employee,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: primaryColor.withValues(alpha: 0.12),
              child: Text(
                employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${employee.designation ?? employee.role} • ${employee.department}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    employee.employeeCode,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(status: employee.status),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 20, color: mutedColor),
          ],
        ),
      ),
    );
  }
}
