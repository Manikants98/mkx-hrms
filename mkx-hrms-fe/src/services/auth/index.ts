import { useCustomMutation } from "hooks/useCustomMutation";
import type { ApiResponse } from "services/api.types";
import type { AuthUser } from "contexts/AuthContext";

/**
 * Request payload for authentication login
 */
export interface LoginPayload {
  email: string;
  password: string;
}

/**
 * Successful authentication response body
 */
export interface LoginResponse {
  token: string;
  user: AuthUser;
}

/**
 * Mutation hook to authenticate user and issue JWT session token
 *
 * @param onSuccessCallback - Optional callback executed on successful authentication
 * @returns Mutation trigger with mutate and mutateAsync
 */
export const useLogin = (onSuccessCallback?: (data: ApiResponse<LoginResponse>) => void) => {
  return useCustomMutation<ApiResponse<LoginResponse>, unknown, LoginPayload>({
    url: "/v1/auth/login",
    method: "POST",
    toastMessages: {
      loading: "Signing in...",
      success: (res) => res.message || "Login successful",
    },
    onSuccess: (data) => {
      if (onSuccessCallback) onSuccessCallback(data);
    },
  });
};
