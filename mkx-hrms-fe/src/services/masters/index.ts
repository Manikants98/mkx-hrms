import { useCustomQuery } from "hooks/useCustomQuery";
import { useCustomMutation } from "hooks/useCustomMutation";
import { type ApiResponse } from "../api.types";

/**
 * Department entity model returned from backend
 */
export interface MasterDepartment {
  id: number;
  name: string;
  code: string;
  description: string;
  status: "Active" | "Inactive";
  employee_count: number;
  designation_count: number;
  created_at: string;
  updated_at: string;
}

/**
 * Permission item assigned to roles
 */
export interface MasterPermission {
  id: number;
  name: string;
  module: string;
  description: string;
}

/**
 * Role entity model returned from backend
 */
export interface MasterRole {
  id: number;
  name: string;
  description: string;
  status: "Active" | "Inactive";
  permissions: MasterPermission[];
  user_count: number;
  created_at: string;
  updated_at: string;
}

/**
 * Designation entity model returned from backend
 */
export interface MasterDesignation {
  id: number;
  title: string;
  code: string;
  department_id: number | null;
  department_name: string;
  description: string;
  status: "Active" | "Inactive";
  employee_count: number;
  created_at: string;
  updated_at: string;
}

/**
 * Leave type configuration model
 */
export interface MasterLeaveType {
  id: number;
  name: string;
  code: string;
  days_per_year: number;
  is_paid: boolean;
  color: string;
  description: string;
  status: "Active" | "Inactive";
  request_count: number;
  created_at: string;
  updated_at: string;
}

/**
 * Salary structure configuration model
 */
export interface MasterSalaryStructure {
  id: number;
  name: string;
  code: string;
  description?: string | null;
  is_deduction: boolean;
  is_taxable: boolean;
  is_base_salary: boolean;
  calculation_type: string;
  default_value: number;
  status: "Active" | "Inactive";
  created_at: string;
  updated_at: string;
}

/**
 * Work shift schedule model
 */
export interface MasterWorkShift {
  id: number;
  name: string;
  code: string;
  start_time: string;
  end_time: string;
  grace_mins: number;
  description: string;
  status: "Active" | "Inactive";
  created_at: string;
  updated_at: string;
}

/**
 * Retrieval hook for Master Departments
 *
 * @param params - Optional query filter parameters
 * @returns React Query query result
 */
export const useGetMasterDepartments = (params?: { search?: string; status?: string }) => {
  const queryParams = new URLSearchParams();
  if (params?.search) queryParams.append("search", params.search);
  if (params?.status && params.status !== "All") queryParams.append("status", params.status);

  const queryString = queryParams.toString() ? `?${queryParams.toString()}` : "";

  return useCustomQuery<ApiResponse<MasterDepartment[]>>(
    ["masters", "departments", params?.search, params?.status],
    `/v1/masters/departments${queryString}`,
  );
};

/**
 * Mutation hook to create a department
 *
 * @param onSuccessCallback - Optional callback executed on success
 * @returns Mutation trigger
 */
export const useCreateMasterDepartment = (onSuccess?: () => void) => {
  return useCustomMutation<ApiResponse<MasterDepartment>, unknown, Partial<MasterDepartment>>({
    url: "/v1/masters/departments",
    method: "POST",
    invalidateQueries: [["masters", "departments"]],
    toastMessages: {
      loading: "Creating department...",
    },
    onSuccess,
  });
};

/**
 * Mutation hook to update a department
 *
 * @param id - Department ID
 * @param onSuccess - Optional callback executed on success
 * @returns Mutation trigger
 */
export const useUpdateMasterDepartment = (id: number, onSuccess?: () => void) => {
  return useCustomMutation<ApiResponse<MasterDepartment>, unknown, Partial<MasterDepartment>>({
    url: `/v1/masters/departments/${id}`,
    method: "PUT",
    invalidateQueries: [["masters", "departments"]],
    toastMessages: {
      loading: "Updating department...",
    },
    onSuccess,
  });
};

/**
 * Mutation hook to delete a department
 *
 * @param onSuccess - Optional callback executed on success
 * @returns Mutation trigger
 */
export const useDeleteMasterDepartment = (onSuccess?: () => void) => {
  return useCustomMutation<ApiResponse<{ id: number }>, unknown, number>({
    url: (id) => `/v1/masters/departments/${id}`,
    method: "DELETE",
    invalidateQueries: [["masters", "departments"]],
    toastMessages: {
      loading: "Deleting department...",
    },
    onSuccess,
  });
};

/**
 * Retrieval hook for Master Roles
 *
 * @param params - Optional query filter parameters
 * @returns React Query query result
 */
export const useGetMasterRoles = (params?: { search?: string; status?: string }) => {
  const queryParams = new URLSearchParams();
  if (params?.search) queryParams.append("search", params.search);
  if (params?.status && params.status !== "All") queryParams.append("status", params.status);
  const queryString = queryParams.toString() ? `?${queryParams.toString()}` : "";
  return useCustomQuery<ApiResponse<MasterRole[]>>(
    ["masters", "roles", params?.search, params?.status],
    `/v1/masters/roles${queryString}`,
  );
};

/**
 * Retrieval hook for all available system permissions
 *
 * @returns React Query query result
 */
export const useGetMasterPermissions = () => {
  return useCustomQuery<ApiResponse<MasterPermission[]>>(
    ["masters", "permissions"],
    "/v1/masters/permissions",
  );
};

/**
 * Mutation hook to create a role
 *
 * @param onSuccessCallback - Optional callback executed on success
 * @returns Mutation trigger
 */
export const useCreateMasterRole = (onSuccess?: () => void) => {
  return useCustomMutation<
    ApiResponse<MasterRole>,
    unknown,
    { name: string; description?: string; status?: string; permission_ids?: number[] }
  >({
    url: "/v1/masters/roles",
    method: "POST",
    invalidateQueries: [["masters", "roles"]],
    toastMessages: {
      loading: "Creating role...",
    },
    onSuccess,
  });
};

/**
 * Mutation hook to update a role
 *
 * @param id - Role ID
 * @param onSuccess - Optional callback executed on success
 * @returns Mutation trigger
 */
export const useUpdateMasterRole = (id: number, onSuccess?: () => void) => {
  return useCustomMutation<
    ApiResponse<MasterRole>,
    unknown,
    { name?: string; description?: string; status?: string; permission_ids?: number[] }
  >({
    url: `/v1/masters/roles/${id}`,
    method: "PUT",
    invalidateQueries: [["masters", "roles"]],
    toastMessages: {
      loading: "Updating role...",
    },
    onSuccess,
  });
};

/**
 * Mutation hook to delete a role
 *
 * @param onSuccess - Optional callback executed on success
 * @returns Mutation trigger
 */
export const useDeleteMasterRole = (onSuccess?: () => void) => {
  return useCustomMutation<ApiResponse<{ id: number }>, unknown, number>({
    url: (id) => `/v1/masters/roles/${id}`,
    method: "DELETE",
    invalidateQueries: [["masters", "roles"]],
    toastMessages: {
      loading: "Deleting role...",
    },
    onSuccess,
  });
};

/**
 * Retrieval hook for Master Designations
 *
 * @param params - Optional query filter parameters
 * @returns React Query query result
 */
export const useGetMasterDesignations = (params?: {
  search?: string;
  status?: string;
  department_id?: number | string;
}) => {
  const queryParams = new URLSearchParams();
  if (params?.search) queryParams.append("search", params.search);
  if (params?.status && params.status !== "All") queryParams.append("status", params.status);
  if (params?.department_id && params.department_id !== "All")
    queryParams.append("department_id", String(params.department_id));

  const queryString = queryParams.toString() ? `?${queryParams.toString()}` : "";

  return useCustomQuery<ApiResponse<MasterDesignation[]>>(
    ["masters", "designations", params?.search, params?.status, params?.department_id],
    `/v1/masters/designations${queryString}`,
  );
};

/**
 * Mutation hook to create a designation
 *
 * @param onSuccessCallback - Optional callback executed on success
 * @returns Mutation trigger
 */
export const useCreateMasterDesignation = (onSuccess?: () => void) => {
  return useCustomMutation<
    ApiResponse<MasterDesignation>,
    unknown,
    {
      title: string;
      code?: string;
      department_id?: number | null;
      description?: string;
      status?: string;
    }
  >({
    url: "/v1/masters/designations",
    method: "POST",
    invalidateQueries: [["masters", "designations"]],
    toastMessages: {
      loading: "Creating designation...",
    },
    onSuccess,
  });
};

/**
 * Mutation hook to update a designation
 *
 * @param id - Designation ID
 * @param onSuccess - Optional callback executed on success
 * @returns Mutation trigger
 */
export const useUpdateMasterDesignation = (id: number, onSuccess?: () => void) => {
  return useCustomMutation<
    ApiResponse<MasterDesignation>,
    unknown,
    {
      title?: string;
      code?: string;
      department_id?: number | null;
      description?: string;
      status?: string;
    }
  >({
    url: `/v1/masters/designations/${id}`,
    method: "PUT",
    invalidateQueries: [["masters", "designations"]],
    toastMessages: {
      loading: "Updating designation...",
    },
    onSuccess,
  });
};

/**
 * Mutation hook to delete a designation
 *
 * @param onSuccess - Optional callback executed on success
 * @returns Mutation trigger
 */
export const useDeleteMasterDesignation = (onSuccess?: () => void) => {
  return useCustomMutation<ApiResponse<{ id: number }>, unknown, number>({
    url: (id) => `/v1/masters/designations/${id}`,
    method: "DELETE",
    invalidateQueries: [["masters", "designations"]],
    toastMessages: {
      loading: "Deleting designation...",
    },
    onSuccess,
  });
};

/**
 * Retrieval hook for Master Leave Types
 *
 * @param params - Optional query filter parameters
 * @returns React Query query result
 */
export const useGetMasterLeaveTypes = (params?: { search?: string; status?: string }) => {
  const queryParams = new URLSearchParams();
  if (params?.search) queryParams.append("search", params.search);
  if (params?.status && params.status !== "All") queryParams.append("status", params.status);

  const queryString = queryParams.toString() ? `?${queryParams.toString()}` : "";

  return useCustomQuery<ApiResponse<MasterLeaveType[]>>(
    ["masters", "leave-types", params?.search, params?.status],
    `/v1/masters/leave-types${queryString}`,
  );
};

/**
 * Mutation hook to create a leave type
 *
 * @param onSuccessCallback - Optional callback executed on success
 * @returns Mutation trigger
 */
export const useCreateMasterLeaveType = (onSuccess?: () => void) => {
  return useCustomMutation<
    ApiResponse<MasterLeaveType>,
    unknown,
    Partial<MasterLeaveType>
  >({
    url: "/v1/masters/leave-types",
    method: "POST",
    invalidateQueries: [["masters", "leave-types"]],
    toastMessages: {
      loading: "Creating leave type...",
    },
    onSuccess,
  });
};

/**
 * Mutation hook to update a leave type
 *
 * @param id - Leave type ID
 * @param onSuccess - Optional callback executed on success
 * @returns Mutation trigger
 */
export const useUpdateMasterLeaveType = (id: number, onSuccess?: () => void) => {
  return useCustomMutation<
    ApiResponse<MasterLeaveType>,
    unknown,
    Partial<MasterLeaveType>
  >({
    url: `/v1/masters/leave-types/${id}`,
    method: "PUT",
    invalidateQueries: [["masters", "leave-types"]],
    toastMessages: {
      loading: "Updating leave type...",
    },
    onSuccess,
  });
};

/**
 * Mutation hook to delete a leave type
 *
 * @param onSuccess - Optional callback executed on success
 * @returns Mutation trigger
 */
export const useDeleteMasterLeaveType = (onSuccess?: () => void) => {
  return useCustomMutation<ApiResponse<{ id: number }>, unknown, number>({
    url: (id) => `/v1/masters/leave-types/${id}`,
    method: "DELETE",
    invalidateQueries: [["masters", "leave-types"]],
    toastMessages: {
      loading: "Deleting leave type...",
    },
    onSuccess,
  });
};

/**
 * Retrieval hook for Master Salary Structures
 *
 * @param params - Optional query filter parameters
 * @returns React Query query result
 */
export const useGetMasterSalaryStructures = (params?: { search?: string; status?: string }) => {
  const queryParams = new URLSearchParams();
  if (params?.search) queryParams.append("search", params.search);
  if (params?.status && params.status !== "All") queryParams.append("status", params.status);

  const queryString = queryParams.toString() ? `?${queryParams.toString()}` : "";

  return useCustomQuery<ApiResponse<MasterSalaryStructure[]>>(
    ["masters", "salary-structures", params?.search, params?.status],
    `/v1/masters/salary-structures${queryString}`,
  );
};

/**
 * Mutation hook to create a salary structure
 *
 * @param onSuccessCallback - Optional callback executed on success
 * @returns Mutation trigger
 */
export const useCreateMasterSalaryStructure = (onSuccess?: () => void) => {
  return useCustomMutation<
    ApiResponse<MasterSalaryStructure>,
    unknown,
    Partial<MasterSalaryStructure>
  >({
    url: "/v1/masters/salary-structures",
    method: "POST",
    invalidateQueries: [["masters", "salary-structures"]],
    toastMessages: {
      loading: "Creating salary structure...",
    },
    onSuccess,
  });
};

/**
 * Mutation hook to update a salary structure
 *
 * @param id - Salary structure ID
 * @param onSuccess - Optional callback executed on success
 * @returns Mutation trigger
 */
export const useUpdateMasterSalaryStructure = (id: number, onSuccess?: () => void) => {
  return useCustomMutation<
    ApiResponse<MasterSalaryStructure>,
    unknown,
    Partial<MasterSalaryStructure>
  >({
    url: `/v1/masters/salary-structures/${id}`,
    method: "PUT",
    invalidateQueries: [["masters", "salary-structures"]],
    toastMessages: {
      loading: "Updating salary structure...",
    },
    onSuccess,
  });
};

/**
 * Mutation hook to delete a salary structure
 *
 * @param onSuccess - Optional callback executed on success
 * @returns Mutation trigger
 */
export const useDeleteMasterSalaryStructure = (onSuccess?: () => void) => {
  return useCustomMutation<ApiResponse<{ id: number }>, unknown, number>({
    url: (id) => `/v1/masters/salary-structures/${id}`,
    method: "DELETE",
    invalidateQueries: [["masters", "salary-structures"]],
    toastMessages: {
      loading: "Deleting salary structure...",
    },
    onSuccess,
  });
};

/**
 * Retrieval hook for Master Work Shifts
 *
 * @param params - Optional query filter parameters
 * @returns React Query query result
 */
export const useGetMasterWorkShifts = (params?: { search?: string; status?: string }) => {
  const queryParams = new URLSearchParams();
  if (params?.search) queryParams.append("search", params.search);
  if (params?.status && params.status !== "All") queryParams.append("status", params.status);

  const queryString = queryParams.toString() ? `?${queryParams.toString()}` : "";

  return useCustomQuery<ApiResponse<MasterWorkShift[]>>(
    ["masters", "shifts", params?.search, params?.status],
    `/v1/masters/shifts${queryString}`,
  );
};

/**
 * Mutation hook to create a work shift
 *
 * @param onSuccess - Optional callback executed on success
 * @returns Mutation trigger
 */
export const useCreateMasterWorkShift = (onSuccess?: () => void) => {
  return useCustomMutation<
    ApiResponse<MasterWorkShift>,
    unknown,
    Partial<MasterWorkShift>
  >({
    url: "/v1/masters/shifts",
    method: "POST",
    invalidateQueries: [["masters", "shifts"]],
    toastMessages: {
      loading: "Creating work shift...",
    },
    onSuccess,
  });
};

/**
 * Mutation hook to update a work shift
 *
 * @param id - Work shift ID
 * @param onSuccess - Optional callback executed on success
 * @returns Mutation trigger
 */
export const useUpdateMasterWorkShift = (id: number, onSuccess?: () => void) => {
  return useCustomMutation<
    ApiResponse<MasterWorkShift>,
    unknown,
    Partial<MasterWorkShift>
  >({
    url: `/v1/masters/shifts/${id}`,
    method: "PUT",
    invalidateQueries: [["masters", "shifts"]],
    toastMessages: {
      loading: "Updating work shift...",
    },
    onSuccess,
  });
};

/**
 * Mutation hook to delete a work shift
 *
 * @param onSuccess - Optional callback executed on success
 * @returns Mutation trigger
 */
export const useDeleteMasterWorkShift = (onSuccess?: () => void) => {
  return useCustomMutation<ApiResponse<{ id: number }>, unknown, number>({
    url: (id) => `/v1/masters/shifts/${id}`,
    method: "DELETE",
    invalidateQueries: [["masters", "shifts"]],
    toastMessages: {
      loading: "Deleting work shift...",
    },
    onSuccess,
  });
};


