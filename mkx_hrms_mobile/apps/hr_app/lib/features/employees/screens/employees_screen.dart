import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';
import 'package:mkx_core/widgets/app_avatar.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EmployeesProvider>();
      provider.loadDepartments();
      provider.loadEmployees();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = M3ETheme.of(context).brightness == Brightness.dark;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainer,
      appBar: const MkxAppBar(
        title: 'Employees',
        subtitle: 'Workforce directory & staff records',
      ),
      body: SafeArea(
        top: false,
        child: M3ERefreshIndicator(
          onRefresh: () => context.read<EmployeesProvider>().loadEmployees(),
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
      style: const TextStyle(fontSize: 13.5),
      decoration: InputDecoration(
        hintText: 'Search by name, email or code...',
        hintStyle: TextStyle(
          fontSize: 13.5,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
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
        if (provider.isLoadingDepartments)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                4,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: index == 0 ? 50 : 90.0 + (index * 10),
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: provider.departments.map((dept) {
                final isSelected = provider.departmentFilter == dept ||
                    (dept == 'All' && provider.departmentFilter.isEmpty);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: M3EChip(
                    label: dept,
                    type: M3EChipType.filter,
                    selected: isSelected,
                    elevated: isSelected,
                    leading: Icon(
                      dept == 'All'
                          ? Icons.groups_outlined
                          : Icons.apartment_rounded,
                      size: 14,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () =>
                        provider.setDepartmentFilter(dept == 'All' ? '' : dept),
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
          child: SizedBox(
              width: 52,
              height: 52,
              child: M3EProgressIndicator.circularWavy(strokeWidth: 3)),
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
    final mutedColor = M3ETheme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(
              name: employee.name,
              imageUrl: employee.avatar,
              size: 44,
              borderRadius: 8,
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
                    style: const TextStyle(
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
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    employee.employeeCode,
                    style: TextStyle(
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
          ],
        ),
      ),
    );
  }
}
