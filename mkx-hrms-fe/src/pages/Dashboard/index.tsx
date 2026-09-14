import { AccessTime, Cancel, CheckCircle, Info } from "@mui/icons-material";
import { Avatar, Badge, Chip } from "@mui/material";
import { Activity, ArrowUpRight, Briefcase, Trophy, UserCheck, Users } from "lucide-react";
import React, { useState } from "react";
import { DepartmentDistribution } from "components/Dashboard/DepartmentDistribution";
import { WorkforceChart } from "components/Dashboard/WorkforceChart";
import { ActivityAuditDrawer } from "components/Dashboard/ActivityAuditDrawer";
import { FadeUpItem, StaggerContainer } from "shared/animations";
import { MetricCard } from "shared/MetricCard";
import {
  useGetDashboardOverview,
  useGetWorkforceTrend,
  type RecentActivity,
} from "services/dashboard";

const statusIconMap: Record<string, React.ElementType> = {
  success: CheckCircle,
  warning: AccessTime,
  error: Cancel,
  info: Info,
};

/**
 * Computes a human-readable tenure string from an ISO date string
 *
 * @param joinDateStr - ISO date string of the employee's join date
 * @returns Formatted tenure string e.g. "2y 3m" or "5m"
 */
function formatTenure(joinDateStr: string): string {
  const join = new Date(joinDateStr);
  const now = new Date();
  const totalMonths =
    (now.getFullYear() - join.getFullYear()) * 12 + (now.getMonth() - join.getMonth());
  const years = Math.floor(totalMonths / 12);
  const months = totalMonths % 12;
  if (years === 0) return `${months}m`;
  if (months === 0) return `${years}y`;
  return `${years}y ${months}m`;
}

/**
 * Main dashboard view displaying key metrics, workforce telemetry, and real-time activity log
 *
 * @returns Rendered Dashboard page
 */
export default function Dashboard(): React.ReactElement {
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const { data: dashboardResponse } = useGetDashboardOverview();
  const { data: trendResponse, isLoading: isTrendLoading } = useGetWorkforceTrend();

  const metrics = dashboardResponse?.data?.kpi_metrics;
  const recentActivitiesList: RecentActivity[] = dashboardResponse?.data?.recent_activities || [];
  const workforceTrendData = trendResponse?.data || [];

  const topPerformersList = (dashboardResponse?.data?.top_performers || []).map(
    (performer, idx) => ({
      id: idx + 1,
      rank: idx < 3 ? idx + 1 : undefined,
      initials: performer.name
        .split(" ")
        .map((part) => part[0])
        .join("")
        .slice(0, 2),
      name: performer.name,
      role: performer.role,
      department: performer.department,
      tenure: formatTenure(performer.join_date),
      weeklyHours: performer.weekly_hours,
      performancePct: performer.performance_pct,
    }),
  );

  return (
    <StaggerContainer className="space-y-4">
      <FadeUpItem className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricCard
          title="Total Employees"
          value={String(metrics?.total_employees ?? 0)}
          icon={<Users className="w-4 h-4" />}
        />
        <MetricCard
          title="Active Attendance"
          value={String(metrics?.active_workforce ?? 0)}
          icon={<UserCheck className="w-4 h-4" />}
        />
        <MetricCard
          title="On Leave Today"
          value={String(metrics?.on_leave_today ?? 0)}
          icon={<Briefcase className="w-4 h-4" />}
        />
        <MetricCard
          title="Active Candidates"
          value={String(metrics?.active_candidates ?? 0)}
          icon={<Activity className="w-4 h-4" />}
        />
      </FadeUpItem>

      <FadeUpItem className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="lg:col-span-2">
          <WorkforceChart data={workforceTrendData} isLoading={isTrendLoading} />
        </div>
        <div className="lg:col-span-1">
          <DepartmentDistribution />
        </div>
      </FadeUpItem>

      <FadeUpItem className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div className="bg-card border border-border rounded-xl p-5">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h3 className="text-base font-semibold text-foreground">Recent Activity</h3>
              <p className="text-sm text-muted-foreground mt-0.5">Live audit trail & updates</p>
            </div>
            <button
              onClick={() => setIsDrawerOpen(true)}
              className="flex items-center gap-1 text-sm text-primary hover:text-primary/80 font-medium transition-colors group cursor-pointer"
            >
              View all
              <ArrowUpRight className="w-4 h-4 transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
            </button>
          </div>

          <StaggerContainer className="space-y-3">
            {recentActivitiesList.length === 0 ? (
              <div className="py-8 text-center text-muted-foreground text-sm">
                No recent activity logs recorded yet.
              </div>
            ) : (
              recentActivitiesList.map((activity) => {
                const Icon = statusIconMap[activity.status_type] || CheckCircle;
                return (
                  <FadeUpItem
                    key={activity.id}
                    onClick={() => setIsDrawerOpen(true)}
                    className="group flex items-center justify-between p-3 rounded-lg hover:bg-secondary/50 transition-all duration-200 cursor-pointer"
                  >
                    <div className="flex items-center gap-3">
                      <Avatar
                        variant="rounded"
                        className="shrink-0 !rounded-[6px] !text-xs !font-bold"
                        style={{
                          backgroundColor: activity.bg_alpha || "rgba(0, 177, 216, 0.15)",
                          color:
                            activity.status_type === "success"
                              ? "#10b981"
                              : activity.status_type === "warning"
                                ? "#f59e0b"
                                : activity.status_type === "error"
                                  ? "#ef4444"
                                  : "#3b82f6",
                        }}
                      >
                        {activity.initials}
                      </Avatar>
                      <div className="max-w-[200px] sm:max-w-[280px]">
                        <p className="text-sm font-medium text-foreground truncate">
                          {activity.name}
                        </p>
                        <p className="text-xs text-muted-foreground truncate">{activity.subtext}</p>
                      </div>
                    </div>
                    <Chip
                      icon={<Icon className="!w-3.5 !h-3.5" />}
                      label={activity.status_label}
                      size="small"
                      variant="outlined"
                      color={
                        activity.status_type === "info"
                          ? "default"
                          : (activity.status_type as "success" | "warning" | "error" | "default")
                      }
                    />
                  </FadeUpItem>
                );
              })
            )}
          </StaggerContainer>
        </div>

        <div className="bg-card border border-border rounded-xl p-5">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h3 className="text-base font-semibold text-foreground">Top Performers</h3>
              <p className="text-sm text-muted-foreground mt-0.5">This month's leaders</p>
            </div>
            <div className="flex items-center gap-1 text-warning">
              <Trophy className="w-5 h-5" />
            </div>
          </div>

          <StaggerContainer className="space-y-3">
            {topPerformersList.map((performer) => (
              <FadeUpItem
                key={performer.id}
                className="group flex items-center justify-between p-2 rounded-lg hover:bg-secondary/50 transition-all duration-200 cursor-pointer"
              >
                <div className="flex items-center gap-3">
                  <Badge
                    badgeContent={performer.rank}
                    invisible={!performer.rank}
                    color="warning"
                    className="[&_.MuiBadge-badge]:!rounded-[5px]"
                  >
                    <Avatar className="!w-10 !h-10 !bg-secondary !text-muted-foreground !text-[0.875rem] !font-semibold">
                      {performer.initials}
                    </Avatar>
                  </Badge>
                  <div>
                    <p className="text-sm font-medium text-foreground">{performer.name}</p>
                    <p className="text-xs text-muted-foreground">{performer.role}</p>
                  </div>
                </div>
                <div className="text-right shrink-0 min-w-[80px]">
                  <p className="text-sm font-semibold text-foreground">{performer.weeklyHours}</p>
                  <p className="text-[10px] text-muted-foreground mt-0.5">this week</p>
                  <div className="mt-1.5 h-1.5 w-full rounded-full bg-secondary overflow-hidden">
                    <div
                      className="h-full rounded-full transition-all duration-700"
                      style={{
                        width: `${performer.performancePct}%`,
                        backgroundColor:
                          performer.performancePct >= 80
                            ? "#10b981"
                            : performer.performancePct >= 50
                              ? "#f59e0b"
                              : "#ef4444",
                      }}
                    />
                  </div>
                  <p
                    className="text-[10px] font-medium mt-0.5"
                    style={{
                      color:
                        performer.performancePct >= 80
                          ? "#10b981"
                          : performer.performancePct >= 50
                            ? "#f59e0b"
                            : "#ef4444",
                    }}
                  >
                    {performer.performancePct}% efficiency
                  </p>
                </div>
              </FadeUpItem>
            ))}
          </StaggerContainer>
        </div>
      </FadeUpItem>

      <ActivityAuditDrawer open={isDrawerOpen} onClose={() => setIsDrawerOpen(false)} />
    </StaggerContainer>
  );
}
