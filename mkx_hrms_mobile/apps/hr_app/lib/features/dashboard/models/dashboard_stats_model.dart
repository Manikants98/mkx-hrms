/// Aggregate KPI statistics for the HR Dashboard overview
class DashboardStatsModel {
  final int totalEmployees;
  final int presentToday;
  final int absentToday;
  final int lateToday;
  final int pendingLeaves;
  final int openPositions;
  final List<RecentActivityModel> recentActivity;

  const DashboardStatsModel({
    required this.totalEmployees,
    required this.presentToday,
    required this.absentToday,
    required this.lateToday,
    required this.pendingLeaves,
    required this.openPositions,
    required this.recentActivity,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    final kpis = json['kpi_metrics'] as Map<String, dynamic>? ?? json;
    final attendance = json['attendance'] as Map<String, dynamic>? ?? {};
    final activityList = (json['recent_activities'] ?? json['recent_activity'])
            as List<dynamic>? ??
        [];

    final totalEmp = _parseInt(
      kpis['total_employees'] ?? json['total_employees'],
    );
    final onLeave = _parseInt(kpis['on_leave_today']);
    final openPos = _parseInt(
      kpis['active_candidates'] ?? json['open_positions'],
    );

    final present = attendance.containsKey('present')
        ? _parseInt(attendance['present'])
        : (kpis.containsKey('present_today')
            ? _parseInt(kpis['present_today'])
            : 0);
    final absent = attendance.containsKey('absent')
        ? _parseInt(attendance['absent'])
        : (kpis.containsKey('absent_today')
            ? _parseInt(kpis['absent_today'])
            : onLeave);
    final lateCount = attendance.containsKey('late')
        ? _parseInt(attendance['late'])
        : _parseInt(kpis['late_today']);
    final pendingLeaves = json.containsKey('pending_leaves')
        ? _parseInt(json['pending_leaves'])
        : (kpis.containsKey('pending_leaves')
            ? _parseInt(kpis['pending_leaves'])
            : onLeave);

    return DashboardStatsModel(
      totalEmployees: totalEmp,
      presentToday: present,
      absentToday: absent,
      lateToday: lateCount,
      pendingLeaves: pendingLeaves,
      openPositions: openPos,
      recentActivity: activityList
          .map((e) => RecentActivityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Fallback stats model used when the dashboard endpoint is unavailable
  factory DashboardStatsModel.empty() => const DashboardStatsModel(
        totalEmployees: 0,
        presentToday: 0,
        absentToday: 0,
        lateToday: 0,
        pendingLeaves: 0,
        openPositions: 0,
        recentActivity: [],
      );

  static int _parseInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
}

/// A single entry in the HR dashboard recent-activity feed
class RecentActivityModel {
  final String title;
  final String subtitle;
  final String type;
  final String timeAgo;

  const RecentActivityModel({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.timeAgo,
  });

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) =>
      RecentActivityModel(
        title: (json['title'] != null && json['title'].toString().isNotEmpty)
            ? json['title'].toString()
            : (json['name']?.toString() ?? ''),
        subtitle: (json['subtitle'] != null &&
                json['subtitle'].toString().isNotEmpty)
            ? json['subtitle'].toString()
            : (json['diff']?.toString() ?? json['subtext']?.toString() ?? ''),
        type: json['type']?.toString() ??
            json['status_type']?.toString() ??
            'info',
        timeAgo:
            json['time_ago']?.toString() ?? json['timeAgo']?.toString() ?? '',
      );
}
