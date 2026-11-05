import { useCustomQuery } from "hooks/useCustomQuery";
import { useCustomMutation } from "hooks/useCustomMutation";
import { type ApiResponse } from "../api.types";

/**
 * User profile settings contract
 */
export interface UserProfileSettings {
  first_name: string;
  last_name: string;
  email: string;
  role: string;
  timezone?: string;
  avatar: string;
}

/**
 * Integration service item
 */
export interface IntegrationItem {
  key: string;
  name: string;
  description: string;
  short_code: string;
  connected: boolean;
  last_sync: string | null;
}

/**
 * Notification preference item
 */
export interface NotificationPreferenceSetting {
  key: string;
  label: string;
  description: string;
  default_email: boolean;
  default_push: boolean;
}

/**
 * Combined settings dataset
 */
export interface SettingsData {
  profile: UserProfileSettings;
  roles?: { label: string; value: string }[];
  integrations: IntegrationItem[];
  notification_preferences: NotificationPreferenceSetting[];
}

/**
 * Hook to retrieve full application settings
 *
 * @returns React Query query result
 */
export const useGetSettings = () => {
  return useCustomQuery<ApiResponse<SettingsData>>(["settings"], "/v1/settings");
};

/**
 * Hook to update user profile
 *
 * @param onSuccessCallback - Optional callback on success
 * @returns Mutation trigger
 */
export const useUpdateProfile = (onSuccess?: () => void) => {
  return useCustomMutation<ApiResponse<unknown>, unknown, Partial<UserProfileSettings>>({
    url: "/v1/settings/profile",
    method: "PUT",
    invalidateQueries: [["settings"]],
    toastMessages: {
      loading: "Updating profile...",
    },
    onSuccess,
  });
};

/**
 * Hook to update notification channel switches
 *
 * @param onSuccess - Optional callback on success
 * @returns Mutation trigger
 */
export const useUpdateNotificationPreferences = (onSuccess?: () => void) => {
  return useCustomMutation<
    ApiResponse<unknown>,
    unknown,
    { preferences: Record<string, { email: boolean; push: boolean }> }
  >({
    url: "/v1/settings/notifications",
    method: "PUT",
    invalidateQueries: [["settings"]],
    toastMessages: {
      loading: "Saving preferences...",
    },
    onSuccess,
  });
};

