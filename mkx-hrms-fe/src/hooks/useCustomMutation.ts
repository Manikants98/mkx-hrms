import { useMutation, useQueryClient } from "@tanstack/react-query";
import type { QueryKey, UseMutationOptions, UseMutationResult } from "@tanstack/react-query";
import { AxiosError } from "axios";
import type { AxiosRequestConfig } from "axios";
import { api } from "libraries/axios";
import toast from "react-hot-toast";

/**
 * Structure of variables for dynamic request overrides.
 *
 * @template TVariables - Structure of request body payload or query parameters
 * @template TData - Expected response payload type
 * @template TError - Expected error payload structure
 */
export interface CustomMutationVariables<TVariables, TData = unknown, TError = AxiosError> {
  /** Relative endpoint URL target */
  url?: string;
  /** HTTP verb to execute for the request */
  method?: "GET" | "POST" | "PUT" | "DELETE" | "PATCH";
  /** Optional request payload data to be serialized */
  data?: TVariables;
  /** Optional Axios configuration parameters such as custom headers */
  config?: AxiosRequestConfig;
  /** Optional custom toast messaging configuration to display during mutation lifecycle */
  toastMessages?: {
    /** Status message displayed while the mutation is in flight */
    loading?: string;
    /** Static string or factory function generating success feedback message */
    success?: string | ((data: TData) => string);
    /** Static string or factory function generating error feedback message */
    error?: string | ((error: TError) => string);
  };
}

/**
 * Options accepted by useCustomMutation hook including declarative URL/method,
 * query cache invalidation, custom execution logic, and toast message controls.
 *
 * @template TData - Expected response data payload returned by the mutation
 * @template TError - Expected error shape, defaulting to AxiosError
 * @template TVariables - Structure of data arguments supplied during invocation
 * @template TContext - Optional optimistic update context payload
 */
export interface CustomMutationOptions<TData, TError, TVariables, TContext> extends Omit<
  UseMutationOptions<
    TData,
    TError,
    CustomMutationVariables<TVariables, TData, TError> | TVariables,
    TContext
  >,
  "mutationFn"
> {
  /** Relative endpoint URL target or factory resolving URL dynamically from mutation variables */
  url?: string | ((variables: TVariables) => string);
  /** HTTP verb to execute for the request */
  method?: "GET" | "POST" | "PUT" | "DELETE" | "PATCH";
  /** Optional custom execution function overriding standard Axios HTTP dispatching */
  mutationFn?: (
    variables: CustomMutationVariables<TVariables, TData, TError> | TVariables,
  ) => Promise<TData>;
  /** Array of TanStack Query cache keys to automatically invalidate upon mutation success */
  invalidateQueries?: (string | QueryKey)[];
  /** If true, silences the success toast message */
  suppressSuccessToast?: boolean;
  /** If true, silences the error toast message */
  suppressErrorToast?: boolean;
  /** Custom toast messaging configuration for loading, success, and error states */
  toastMessages?: {
    /** Status message displayed while the mutation is in flight */
    loading?: string;
    /** Static string or factory function generating success feedback message */
    success?: string | ((data: TData) => string);
    /** Static string or factory function generating error feedback message */
    error?: string | ((error: TError) => string);
  };
}

/**
 * Unified enterprise React Query mutation hook for executing data modification requests.
 *
 * Combines declarative HTTP routing, automatic cache invalidation, promise-based toasts,
 * and automatic backend response message surfacing into a single zero-boilerplate hook.
 *
 * @template TData - Expected response data payload returned by the mutation
 * @template TError - Expected error shape, defaulting to AxiosError
 * @template TVariables - Structure of data arguments supplied during invocation
 * @template TContext - Optional optimistic update context payload
 *
 * @param options - Mutation configuration options, default URL/method, cache invalidation, and toast feedback
 *
 * @returns React Query mutation result object with mutate/mutateAsync functions and execution states
 *
 * @example
 * ```tsx
 * const { mutate, isPending } = useCustomMutation<ApiResponse<User>, unknown, CreateUserDto>({
 *   url: "/v1/users",
 *   method: "POST",
 *   invalidateQueries: ["users"],
 *   toastMessages: {
 *     loading: "Creating user...",
 *   },
 * });
 *
 * mutate({ first_name: "Alice", email: "alice@mkx.com" });
 * ```
 */
export function useCustomMutation<
  TData = unknown,
  TError = AxiosError,
  TVariables = unknown,
  TContext = unknown,
>(
  options?: CustomMutationOptions<TData, TError, TVariables, TContext>,
): UseMutationResult<
  TData,
  TError,
  CustomMutationVariables<TVariables, TData, TError> | TVariables,
  TContext
> {
  const queryClient = useQueryClient();

  const {
    url: defaultUrl,
    method: defaultMethod,
    mutationFn: customMutationFn,
    invalidateQueries,
    suppressSuccessToast,
    suppressErrorToast,
    toastMessages: defaultToastMessages,
    onSuccess: userOnSuccess,
    ...mutationOptions
  } = options || {};

  return useMutation<
    TData,
    TError,
    CustomMutationVariables<TVariables, TData, TError> | TVariables,
    TContext
  >({
    mutationFn: async (
      variables: CustomMutationVariables<TVariables, TData, TError> | TVariables,
    ): Promise<TData> => {
      let url =
        typeof defaultUrl === "function"
          ? defaultUrl(
              typeof variables === "object" &&
                variables !== null &&
                "data" in variables &&
                (variables as CustomMutationVariables<TVariables, TData, TError>).data !== undefined
                ? ((variables as CustomMutationVariables<TVariables, TData, TError>).data as TVariables)
                : (variables as TVariables),
            )
          : defaultUrl;
      let method = defaultMethod || "POST";
      let data: unknown =
        typeof defaultUrl === "function" && method === "DELETE" ? undefined : variables;
      let config: AxiosRequestConfig | undefined;
      let inlineToastMessages:
        | {
            loading?: string;
            success?: string | ((data: TData) => string);
            error?: string | ((error: TError) => string);
          }
        | undefined;

      if (
        typeof variables === "object" &&
        variables !== null &&
        ("url" in variables || "method" in variables || "config" in variables)
      ) {
        const customVars = variables as CustomMutationVariables<TVariables, TData, TError>;
        if (customVars.url) url = customVars.url;
        if (customVars.method) method = customVars.method;
        data = customVars.data !== undefined ? customVars.data : variables;
        config = customVars.config;
        inlineToastMessages = customVars.toastMessages;
      }

      const executeRequest = async (): Promise<TData> => {
        if (customMutationFn) {
          return customMutationFn(variables);
        }

        if (!url) {
          throw new Error("No URL specified for mutation request.");
        }

        const response = await api.request<TData>({
          url,
          method,
          data,
          ...config,
        });

        return response.data;
      };

      const requestPromise = executeRequest();

      const shouldToast = Boolean(defaultToastMessages || inlineToastMessages);

      if (shouldToast) {
        const activeToastMessages = inlineToastMessages || defaultToastMessages || {};

        toast.promise(
          requestPromise,
          {
            loading: activeToastMessages.loading || "Processing...",
            success: (resData: TData) => {
              if (suppressSuccessToast) {
                return "";
              }

              if (typeof activeToastMessages.success === "function") {
                return activeToastMessages.success(resData);
              }

              if (typeof activeToastMessages.success === "string") {
                return activeToastMessages.success;
              }

              if (
                resData &&
                typeof resData === "object" &&
                "message" in resData &&
                typeof (resData as { message?: unknown }).message === "string"
              ) {
                return (resData as { message: string }).message;
              }

              return "Operation completed successfully!";
            },
            error: (err: unknown) => {
              if (suppressErrorToast) {
                return "";
              }

              const status = (err as AxiosError)?.response?.status;
              if (status === 401) {
                return "";
              }

              if (typeof activeToastMessages.error === "function") {
                return activeToastMessages.error(err as TError);
              }

              if (typeof activeToastMessages.error === "string") {
                return activeToastMessages.error;
              }

              const axiosError = err as AxiosError<{ message?: string; error?: string }>;
              return (
                axiosError.response?.data?.message ||
                axiosError.response?.data?.error ||
                axiosError.message ||
                "An error occurred"
              );
            },
          },
          {
            success: {
              style: suppressSuccessToast ? { display: "none" } : undefined,
            },
            error: {
              style: suppressErrorToast ? { display: "none" } : undefined,
            },
          },
        );
      }

      return requestPromise;
    },
    onSuccess: (...args) => {
      if (invalidateQueries && invalidateQueries.length > 0) {
        invalidateQueries.forEach((key) => {
          const queryKey = Array.isArray(key) ? key : [key];
          queryClient.invalidateQueries({ queryKey });
        });
      }

      if (userOnSuccess) {
        userOnSuccess(...args);
      }
    },
    ...mutationOptions,
  });
}
