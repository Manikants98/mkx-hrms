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
    final attendance = json['attendance'] as Map<String, dynamic>? ?? {};
    final activityList = json['recent_activity'] as List<dynamic>? ?? [];

    return DashboardStatsModel(
      totalEmployees: _parseInt(json['total_employees']),
      presentToday: _parseInt(attendance['present']),
      absentToday: _parseInt(attendance['absent']),
      lateToday: _parseInt(attendance['late']),
      pendingLeaves: _parseInt(json['pending_leaves']),
      openPositions: _parseInt(json['open_positions']),
      recentActivity: activityList
          .map((e) => RecentActivityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Fallback stats model used when the `/hr/dashboard` endpoint is unavailable
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
        title: json['title']?.toString() ?? '',
        subtitle: json['subtitle']?.toString() ?? '',
        type: json['type']?.toString() ?? 'info',
        timeAgo: json['time_ago']?.toString() ?? '',
      );
}
