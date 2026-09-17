import { useCustomQuery } from "hooks/useCustomQuery";
import { useCustomMutation } from "hooks/useCustomMutation";
import { useQueryClient } from "@tanstack/react-query";
import { type ApiResponse } from "../api.types";

export interface JobPosting {
  id: number;
  job_code: string;
  title: string;
  department_id: number | null;
  role_id?: number | null;
  shift_id?: number | null;
  department_rel?: { id: number; name: string };
  location: string;
  employment_type: string;
  experience_level: string;
  salary_range: string;
  description: string;
  vacancies: number;
  status: string;
  _count?: { candidates: number };
}

export const useGetJobPostings = () => {
  return useCustomQuery<ApiResponse<JobPosting[]>>(["job-postings"], "/v1/job-postings");
};

export const useGetJobPostingById = (id: number) => {
  return useCustomQuery<ApiResponse<JobPosting>>(["job-postings", id], `/v1/job-postings/${id}`, {
    enabled: !!id,
  });
};

export const useCreateJobPosting = (onSuccessCallback?: () => void) => {
  const queryClient = useQueryClient();
  const mutation = useCustomMutation<ApiResponse<JobPosting>, unknown, Partial<JobPosting>>({
    toastMessages: {
      loading: "Creating job posting...",
      success: "Job posting created successfully!",
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["job-postings"] });
      if (onSuccessCallback) onSuccessCallback();
    },
  });

  return {
    ...mutation,
    mutate: (payload: Partial<JobPosting>) =>
      mutation.mutate({
        url: "/v1/job-postings",
        method: "POST",
        data: payload,
      }),
    mutateAsync: (payload: Partial<JobPosting>) =>
      mutation.mutateAsync({
        url: "/v1/job-postings",
        method: "POST",
        data: payload,
      }),
  };
};

export const useUpdateJobPosting = (onSuccessCallback?: () => void) => {
  const queryClient = useQueryClient();
  const mutation = useCustomMutation<
    ApiResponse<JobPosting>,
    unknown,
    Partial<JobPosting> & { id: number }
  >({
    toastMessages: {
      loading: "Updating job posting...",
      success: "Job posting updated successfully!",
    },
    onSuccess: (_) => {
      queryClient.invalidateQueries({ queryKey: ["job-postings"] });
      if (onSuccessCallback) onSuccessCallback();
    },
  });

  return {
    ...mutation,
    mutate: (payload: Partial<JobPosting> & { id: number }) => {
      const { id, ...data } = payload;
      return mutation.mutate({
        url: `/v1/job-postings/${id}`,
        method: "PUT",
        data: data as Partial<JobPosting> & { id: number },
      });
    },
    mutateAsync: (payload: Partial<JobPosting> & { id: number }) => {
      const { id, ...data } = payload;
      return mutation.mutateAsync({
        url: `/v1/job-postings/${id}`,
        method: "PUT",
        data: data as Partial<JobPosting> & { id: number },
      });
    },
  };
};

export const useDeleteJobPosting = (onSuccessCallback?: () => void) => {
  const queryClient = useQueryClient();
  const mutation = useCustomMutation<ApiResponse<null>, unknown, number>({
    toastMessages: {
      loading: "Deleting job posting...",
      success: "Job posting deleted successfully!",
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["job-postings"] });
      if (onSuccessCallback) onSuccessCallback();
    },
  });

  return {
    ...mutation,
    mutate: (id: number) =>
      mutation.mutate({
        url: `/v1/job-postings/${id}`,
        method: "DELETE",
      }),
    mutateAsync: (id: number) =>
      mutation.mutateAsync({
        url: `/v1/job-postings/${id}`,
        method: "DELETE",
      }),
  };
};
