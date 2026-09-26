import { useCustomQuery } from "hooks/useCustomQuery";
import { useCustomMutation } from "hooks/useCustomMutation";
import { type ApiResponse } from "../api.types";

/**
 * Dashboard activity item contract
 */
export interface RecentActivity {
  id: number;
  initials: string;
  name: string;
  subtext: string;
  diff?: string;
  time_ago?: string;
  status_label: string;
  status_type: "success" | "warning" | "error" | "info";
  bg_alpha: string;
  created_at?: string;
}

/**
 * Top performer contract
 */
export interface TopPerformer {
  name: string;
  role: string;
  department: string | null;
  join_date: string;
  weekly_hours: string;
  performance_pct: number;
  avatar?: string;
}

/**
 * Single month data point for the workforce growth trend chart
 */
export interface WorkforceTrendPoint {
  name: string;
  employees: number;
}

/**
 * Dashboard celebration item (Birthday / Work Anniversary)
 */
export interface Celebration {
  type: "Birthday" | "Work Anniversary" | "New Joiner";
  employee_id: number;
  name: string;
  role: string;
  avatar?: string;
  years?: number;
}

/**
 * Dashboard overview dataset
 */
export interface DashboardOverview {
  kpi_metrics: {
    total_employees: number;
    active_workforce: number;
    present_today?: number;
    absent_today?: number;
    late_today?: number;
    on_leave_today: number;
    pending_leaves?: number;
    active_candidates: number;
  };
  attendance?: {
    present: number;
    absent: number;
    late: number;
    on_leave: number;
    total: number;
  };
  pending_leaves?: number;
  recent_activities: RecentActivity[];
  top_performers: TopPerformer[];
  celebrations?: Celebration[];
}

/**
 * Hook to retrieve dashboard overview data
 *
 * @returns React Query query result
 */
export const useGetDashboardOverview = () => {
  return useCustomQuery<ApiResponse<DashboardOverview>>(
    ["dashboard", "overview"],
    "/v1/dashboard/overview",
  );
};

/**
 * Hook to retrieve all tracked activities with optional search query
 *
 * @param search - Optional search filter string
 * @returns React Query query result
 */
export const useGetAllActivities = (search?: string) => {
  const queryParam = search?.trim() ? `?search=${encodeURIComponent(search.trim())}` : "";
  return useCustomQuery<ApiResponse<RecentActivity[]>>(
    ["dashboard", "activities", search],
    `/v1/dashboard/activities${queryParam}`,
  );
};

/**
 * Hook to retrieve real monthly workforce growth trend for the current year
 *
 * @returns React Query query result
 */
export const useGetWorkforceTrend = () => {
  return useCustomQuery<ApiResponse<WorkforceTrendPoint[]>>(
    ["dashboard", "workforce-trend"],
    "/v1/dashboard/workforce-trend",
  );
};

export interface SendWishPayload {
  employee_id: number;
  message: string;
}

export const useSendWish = () => {
  const mutation = useCustomMutation<ApiResponse<{}>, unknown, SendWishPayload>({
    toastMessages: {
      loading: "Sending wish...",
      success: "Wish sent successfully!",
      error: "Failed to send wish",
    },
  });

  return {
    ...mutation,
    mutate: (payload: SendWishPayload) =>
      mutation.mutate({
        url: "/v1/dashboard/send-wish",
        method: "POST",
        data: payload,
      }),
    mutateAsync: (payload: SendWishPayload) =>
      mutation.mutateAsync({
        url: "/v1/dashboard/send-wish",
        method: "POST",
        data: payload,
      }),
  };
};

/**
 * In-app notification record from the database
 */
export interface AppNotification {
  id: number;
  user_id: number;
  title: string;
  message: string;
  type: string;
  sender_name: string | null;
  is_read: boolean;
  data: Record<string, unknown> | null;
  created_at: string;
  updated_at: string;
}

/**
 * Notifications API response shape
 */
export interface NotificationsResponse {
  notifications: AppNotification[];
  unread_count: number;
}

/**
 * Hook to fetch notifications for the authenticated user
 *
 * @returns React Query result with notifications and unread count
 */
export const useGetNotifications = () => {
  return useCustomQuery<ApiResponse<NotificationsResponse>>(
    ["notifications"],
    "/v1/notifications",
  );
};

/**
 * Hook to mark a single notification as read
 */
export const useMarkNotificationRead = () => {
  const mutation = useCustomMutation<ApiResponse<{}>, unknown, { id: number }>({});

  return {
    ...mutation,
    mutate: (id: number) =>
      mutation.mutate({ url: `/v1/notifications/${id}/read`, method: "PATCH" }),
  };
};

/**
 * Hook to mark all notifications as read
 */
export const useMarkAllNotificationsRead = () => {
  const mutation = useCustomMutation<ApiResponse<{}>, unknown, void>({});

  return {
    ...mutation,
    mutate: () =>
      mutation.mutate({ url: "/v1/notifications/mark-all-read", method: "PATCH" }),
  };
};

