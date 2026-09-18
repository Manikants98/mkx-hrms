import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/widgets/app_text.dart';
import 'package:mkx_core/widgets/empty_state.dart';
import 'package:mkx_core/widgets/status_badge.dart';
import '../models/employee_list_model.dart';
import '../state/employees_provider.dart';

/// HR Employee Directory — searchable, filterable list with detail navigation
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: AppText.heading('Employees'),
            ),
            _buildSearchBar(isDark),
            _buildFilters(isDark),
            Expanded(child: _buildList(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search by name, email or ID...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
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
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.info, width: 1.5),
          ),
        ),
        onChanged: (q) {
          setState(() {});
          context.read<EmployeesProvider>().setSearch(q);
        },
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return Consumer<EmployeesProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              ..._departments.map((dept) {
                final selected =
                    provider.departmentFilter == dept ||
                    (dept == 'All' && provider.departmentFilter.isEmpty);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: dept,
                    selected: selected,
                    isDark: isDark,
                    onTap: () =>
                        provider.setDepartmentFilter(dept == 'All' ? '' : dept),
                  ),
                );
              }),
              Container(
                width: 1,
                height: 20,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                margin: const EdgeInsets.only(right: 8),
              ),
              ..._statuses.map((s) {
                final selected =
                    provider.statusFilter == s ||
                    (s == 'All' && provider.statusFilter.isEmpty);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: s,
                    selected: selected,
                    isDark: isDark,
                    onTap: () => provider.setStatusFilter(s == 'All' ? '' : s),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(bool isDark) {
    return Consumer<EmployeesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.employees.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline_rounded,
            title: 'No employees found',
            description: provider.searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'No employees match the selected filters',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadEmployees(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: provider.employees.length,
            itemBuilder: (context, i) {
              return _EmployeeTile(
                employee: provider.employees[i],
                isDark: isDark,
                onTap: () =>
                    context.push('/employees/${provider.employees[i].id}'),
              );
            },
          ),
        );
      },
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  final EmployeeListModel employee;
  final bool isDark;
  final VoidCallback onTap;

  const _EmployeeTile({
    required this.employee,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.info.withValues(alpha: 0.1),
              child: AppText(
                employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyBold(
                    employee.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  AppText.caption(
                    '${employee.designation ?? employee.role} • ${employee.department}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  AppText.caption(employee.employeeCode),
                ],
              ),
            ),
            StatusBadge(status: employee.status),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.info
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.info
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: AppText.label(
          label,
          color: selected
              ? Colors.white
              : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
        ),
      ),
    );
  }
}
