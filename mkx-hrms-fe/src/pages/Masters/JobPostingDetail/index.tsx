import {
  ArrowBack,
  AttachMoney,
  Business,
  CalendarToday,
  Cancel,
  CheckCircle,
  Delete,
  Edit,
  Group,
  LocationOn,
  OpenInNew,
  People,
  Schedule,
  Share,
  Visibility,
  Work,
  WorkOutlined,
} from "@mui/icons-material";
import {
  Avatar,
  Button,
  Chip,
  CircularProgress,
  IconButton,
  Skeleton,
  Tab,
  Tabs,
} from "@mui/material";
import dayjs from "dayjs";
import { useFormik } from "formik";
import React, { useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import {
  useDeleteJobPosting,
  useGetJobPostingById,
  useUpdateJobPosting,
} from "services/job-postings";
import {
  useGetMasterDepartments,
  useGetMasterRoles,
  useGetMasterWorkShifts,
} from "services/masters";
import { CustomDialog } from "shared/CustomDialog";
import { DataTable, type ColumnDef } from "shared/DataTable";
import { AppDrawer } from "shared/Drawer";
import { Input } from "shared/Input";
import { RichTextEditor } from "shared/RichTextEditor";
import { Select, type SelectOption } from "shared/Select";
import { StatsCard } from "shared/StatsCard";
import { FadeUpItem, StaggerContainer } from "shared/animations";
import * as Yup from "yup";

/**
 * Validation schema for editing job posting details
 */
const JobPostingEditSchema = Yup.object().shape({
  title: Yup.string().required("Title is required"),
  department_id: Yup.number().nullable(),
  role_id: Yup.number().nullable(),
  shift_id: Yup.number().nullable(),
  location: Yup.string().required("Location is required"),
  employment_type: Yup.string().required("Employment type is required"),
  experience_level: Yup.string().required("Experience level is required"),
  salary_range: Yup.string(),
  description: Yup.string(),
  vacancies: Yup.number().min(1, "Must be at least 1").required("Vacancies are required"),
  status: Yup.string().required("Status is required"),
});

/**
 * Formats date into standard readable format
 *
 * @param date - Date input
 * @returns Formatted date string
 */
const formatDate = (date?: string): string => {
  if (!date) return "N/A";
  return dayjs(date).format("DD MMMM YYYY");
};

/**
 * Full page detail view for workforce Job Postings
 *
 * @returns Rendered JobPostingDetail component
 */
export const JobPostingDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [activeTab, setActiveTab] = useState<"overview" | "candidates">("overview");
  const [isEditDrawerOpen, setIsEditDrawerOpen] = useState(false);
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
  const [copiedLink, setCopiedLink] = useState(false);

  const { data: jobResponse, isLoading, refetch } = useGetJobPostingById(id || "");
  const job = jobResponse?.data;

  const { data: departmentsResponse } = useGetMasterDepartments();
  const { data: rolesResponse } = useGetMasterRoles();
  const { data: shiftsResponse } = useGetMasterWorkShifts();

  const updateMutation = useUpdateJobPosting(() => {
    setIsEditDrawerOpen(false);
    refetch();
  });

  const deleteMutation = useDeleteJobPosting(() => {
    setIsDeleteDialogOpen(false);
    navigate("/masters/job-postings");
  });

  const departmentOptions: SelectOption[] = useMemo(() => {
    return (departmentsResponse?.data || []).map((d) => ({ label: d.name, value: d.id }));
  }, [departmentsResponse]);

  const roleOptions: SelectOption[] = useMemo(() => {
    return (rolesResponse?.data || []).map((r) => ({ label: r.name, value: r.id }));
  }, [rolesResponse]);

  const shiftOptions: SelectOption[] = useMemo(() => {
    return (shiftsResponse?.data || []).map((s) => ({ label: s.name, value: s.id }));
  }, [shiftsResponse]);

  const employmentOptions: SelectOption[] = [
    { label: "Full-Time", value: "Full-Time" },
    { label: "Part-Time", value: "Part-Time" },
    { label: "Contract", value: "Contract" },
    { label: "Internship", value: "Internship" },
  ];

  const experienceOptions: SelectOption[] = [
    { label: "Entry-Level", value: "Entry-Level" },
    { label: "Mid-Level", value: "Mid-Level" },
    { label: "Senior", value: "Senior" },
    { label: "Lead", value: "Lead" },
    { label: "Executive", value: "Executive" },
  ];

  const statusOptions: SelectOption[] = [
    { label: "Active", value: "Active" },
    { label: "Closed", value: "Closed" },
    { label: "Draft", value: "Draft" },
    { label: "On Hold", value: "On Hold" },
  ];

  const formik = useFormik({
    enableReinitialize: true,
    initialValues: {
      title: job?.title || "",
      department_id: (job?.department_id ?? "") as number | "",
      role_id: (job?.role_id ?? "") as number | "",
      shift_id: (job?.shift_id ?? "") as number | "",
      location: job?.location || "",
      employment_type: job?.employment_type || "Full-Time",
      experience_level: job?.experience_level || "Mid-Level",
      salary_range: job?.salary_range || "",
      description: job?.description || "",
      vacancies: job?.vacancies || 1,
      status: job?.status || "Active",
    },
    validationSchema: JobPostingEditSchema,
    onSubmit: (values) => {
      if (!job) return;
      updateMutation.mutate({
        id: job.id,
        title: values.title,
        department_id: values.department_id === "" ? null : Number(values.department_id),
        role_id: values.role_id === "" ? null : Number(values.role_id),
        shift_id: values.shift_id === "" ? null : Number(values.shift_id),
        location: values.location,
        employment_type: values.employment_type,
        experience_level: values.experience_level,
        salary_range: values.salary_range,
        description: values.description,
        vacancies: values.vacancies,
        status: values.status,
      });
    },
  });

  const candidates = useMemo(() => job?.candidates || [], [job?.candidates]);

  const candidateKpiCounts = useMemo(() => {
    const total = candidates.length;
    const inPipeline = candidates.filter(
      (c) => c.stage === "Screening" || c.stage === "Interviewing",
    ).length;
    const offeredOrHired = candidates.filter(
      (c) => c.stage === "Offered" || c.stage === "Hired",
    ).length;
    return { total, inPipeline, offeredOrHired };
  }, [candidates]);

  const candidateColumns: ColumnDef<(typeof candidates)[0]>[] = [
    {
      header: "CANDIDATE",
      cell: (row) => (
        <div className="flex items-center gap-3">
          <Avatar
            src={row.avatar || undefined}
            className="!w-8 !h-8 !bg-primary/20 !text-primary !text-xs !font-bold"
          >
            {row.name.charAt(0)}
          </Avatar>
          <div className="flex flex-col">
            <span
              onClick={() => navigate(`/candidates/${row.id}`)}
              className="font-medium text-foreground text-xs hover:text-primary transition-colors cursor-pointer"
            >
              {row.name}
            </span>
            <span className="text-[11px] text-muted-foreground">{row.email}</span>
          </div>
        </div>
      ),
      width: "35%",
    },
    {
      header: "STAGE",
      cell: (row) => (
        <Chip
          label={row.stage}
          size="small"
          className="!h-5 !text-[11px] !bg-primary/10 !text-primary !font-medium"
        />
      ),
      width: "20%",
    },
    {
      header: "STATUS",
      cell: (row) => (
        <Chip
          label={row.status}
          size="small"
          color={
            row.status === "Offered" || row.status === "Active"
              ? "success"
              : row.status === "In Review"
                ? "warning"
                : "error"
          }
          variant="outlined"
          className="!h-5 !text-[11px] !font-medium"
        />
      ),
      width: "20%",
    },
    {
      header: "APPLIED DATE",
      cell: (row) => (
        <span className="text-xs text-muted-foreground">{formatDate(row.applied_date)}</span>
      ),
      width: "15%",
    },
    {
      header: "ACTION",
      align: "right",
      cell: (row) => (
        <IconButton
          size="small"
          onClick={() => navigate(`/candidates/${row.id}`)}
          className="!text-muted-foreground hover:!text-foreground"
        >
          <Visibility className="!w-4 !h-4" />
        </IconButton>
      ),
      width: "10%",
    },
  ];

  const handleShareLink = () => {
    const url = `${window.location.origin}/careers`;
    navigator.clipboard.writeText(url);
    setCopiedLink(true);
    setTimeout(() => setCopiedLink(false), 2000);
  };

  const handleQuickStatusChange = (newStatus: "Active" | "Closed") => {
    if (!job) return;
    updateMutation.mutate({
      id: job.id,
      status: newStatus,
    });
  };

  if (isLoading) {
    return (
      <div className="space-y-6 max-w-[1600px] mx-auto pb-10">
        <div className="flex items-center gap-3">
          <Skeleton variant="circular" width={40} height={40} />
          <div className="flex flex-col gap-2">
            <Skeleton variant="text" width={240} height={32} />
            <Skeleton variant="text" width={360} height={20} />
          </div>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} variant="rounded" height={100} className="!rounded-[5px]" />
          ))}
        </div>
      </div>
    );
  }

  if (!job) {
    return (
      <div className="flex flex-col items-center justify-center py-20 text-center space-y-4">
        <div className="w-14 h-14 rounded-full bg-secondary flex items-center justify-center text-muted-foreground">
          <WorkOutlined className="!w-7 !h-7" />
        </div>
        <div>
          <h2 className="text-lg font-semibold text-foreground">Job Posting Not Found</h2>
          <p className="text-xs text-muted-foreground mt-1">
            The requisition you are looking for does not exist or may have been deleted.
          </p>
        </div>
        <Button
          variant="contained"
          size="small"
          onClick={() => navigate("/masters/job-postings")}
          startIcon={<ArrowBack className="!w-4 !h-4" />}
          className="!text-xs !normal-case"
        >
          Back to Workforce Masters
        </Button>
      </div>
    );
  }

  return (
    <StaggerContainer className="space-y-6 max-w-[1600px] mx-auto pb-12">
      {/** Top Breadcrumbs & Back Navigation */}
      <FadeUpItem className="flex items-center justify-between">
        <Button
          variant="text"
          size="small"
          onClick={() => navigate("/masters/job-postings")}
          startIcon={<ArrowBack className="!w-4 !h-4" />}
          className="!text-xs !normal-case !text-muted-foreground hover:!text-foreground !px-0"
        >
          Back to Job Postings
        </Button>
        <div className="flex items-center gap-2">
          <Button
            variant="outlined"
            size="small"
            onClick={handleShareLink}
            startIcon={<Share className="!w-4 !h-4" />}
            className="!border-border !bg-secondary !text-muted-foreground hover:!text-foreground !text-xs !normal-case !rounded-[5px]"
          >
            {copiedLink ? "Link Copied!" : "Share Careers Link"}
          </Button>
          <Button
            variant="outlined"
            size="small"
            onClick={() => window.open("/careers", "_blank")}
            endIcon={<OpenInNew className="!w-3.5 !h-3.5" />}
            className="!border-border !bg-secondary !text-muted-foreground hover:!text-foreground !text-xs !normal-case !rounded-[5px]"
          >
            Public View
          </Button>
        </div>
      </FadeUpItem>

      {/** Hero Requisition Header Card */}
      <FadeUpItem>
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-5 p-6 bg-card/60 border border-border rounded-[8px] backdrop-blur-sm">
          <div className="flex items-start gap-4">
            <div className="w-14 h-14 rounded-[8px] bg-primary/10 border border-primary/20 text-primary flex items-center justify-center shrink-0 shadow-inner">
              <Work className="!w-7 !h-7" />
            </div>

            <div className="flex flex-col gap-1.5">
              <div className="flex flex-wrap items-center gap-2.5">
                <h1 className="text-xl sm:text-2xl font-bold tracking-tight text-foreground">
                  {job.title}
                </h1>
                <span className="px-2 py-0.5 rounded-[5px] bg-secondary border border-border text-xs font-semibold text-muted-foreground">
                  {job.job_code}
                </span>
                <Chip
                  icon={
                    job.status === "Active" ? (
                      <CheckCircle className="!w-3.5 !h-3.5" />
                    ) : (
                      <Cancel className="!w-3.5 !h-3.5" />
                    )
                  }
                  label={job.status}
                  size="small"
                  color={
                    job.status === "Active"
                      ? "success"
                      : job.status === "Closed"
                        ? "error"
                        : "default"
                  }
                  variant="outlined"
                  className="!h-6 !text-xs !font-medium"
                />
              </div>

              <div className="flex flex-wrap items-center gap-y-1 gap-x-4 text-xs text-muted-foreground mt-0.5">
                <span className="flex items-center gap-1">
                  <Business className="!w-3.5 !h-3.5 text-primary" />
                  {job.department_rel?.name || "General Department"}
                </span>
                <span className="flex items-center gap-1">
                  <LocationOn className="!w-3.5 !h-3.5 text-primary" />
                  {job.location}
                </span>
                <span className="flex items-center gap-1">
                  <Schedule className="!w-3.5 !h-3.5 text-primary" />
                  {job.employment_type} • {job.experience_level}
                </span>
                {job.salary_range && (
                  <span className="flex items-center gap-1 font-medium text-emerald-600 dark:text-emerald-400">
                    <AttachMoney className="!w-3.5 !h-3.5" />
                    {job.salary_range}
                  </span>
                )}
              </div>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-2.5 shrink-0">
            {job.status === "Active" ? (
              <Button
                variant="outlined"
                size="small"
                color="error"
                onClick={() => handleQuickStatusChange("Closed")}
                disabled={updateMutation.isPending}
                className="!text-xs !normal-case !rounded-[5px]"
              >
                Close Requisition
              </Button>
            ) : (
              <Button
                variant="outlined"
                size="small"
                color="success"
                onClick={() => handleQuickStatusChange("Active")}
                disabled={updateMutation.isPending}
                className="!text-xs !normal-case !rounded-[5px]"
              >
                Reopen Position
              </Button>
            )}

            <Button
              variant="contained"
              size="small"
              onClick={() => setIsEditDrawerOpen(true)}
              startIcon={<Edit className="!w-4 !h-4" />}
              className="!bg-primary !text-primary-foreground hover:!bg-primary/90 !text-xs !normal-case !font-semibold !rounded-[5px] shadow-sm"
            >
              Edit Posting
            </Button>

            <Button
              variant="outlined"
              size="small"
              color="error"
              onClick={() => setIsDeleteDialogOpen(true)}
              startIcon={<Delete className="!w-4 !h-4 text-destructive" />}
              className="!border-destructive/30 !text-destructive hover:!bg-destructive/10 !text-xs !normal-case !rounded-[5px]"
            >
              Delete
            </Button>
          </div>
        </div>
      </FadeUpItem>

      {/** Metric KPI Summary Cards */}
      <FadeUpItem className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard
          title="Open Headcount"
          value={String(job.vacancies)}
          subtext="Approved vacancy count"
          icon={Group}
          iconColor="text-[#ad87ed]"
          iconBg="bg-[#ad87ed]/10"
        />
        <StatsCard
          title="Total Candidates"
          value={String(candidateKpiCounts.total)}
          subtext="Applications submitted"
          icon={People}
          iconColor="text-[#00b1d8]"
          iconBg="bg-[#00b1d8]/10"
        />
        <StatsCard
          title="In Review Pipeline"
          value={String(candidateKpiCounts.inPipeline)}
          subtext="Screening & interviews"
          icon={Schedule}
          iconColor="text-[#eab308]"
          iconBg="bg-[#eab308]/10"
        />
        <StatsCard
          title="Offers & Hires"
          value={String(candidateKpiCounts.offeredOrHired)}
          subtext="Hired or offer extended"
          icon={CheckCircle}
          iconColor="text-[#45ba50]"
          iconBg="bg-[#45ba50]/10"
        />
      </FadeUpItem>

      {/** Tabs Navigation */}
      <FadeUpItem className="border-b border-border">
        <Tabs
          value={activeTab}
          onChange={(_, val) => setActiveTab(val)}
          className="min-h-0 [&_.MuiTab-root]:min-h-0 [&_.MuiTab-root]:py-2.5"
          indicatorColor="primary"
        >
          <Tab
            value="overview"
            label="Requisition Overview"
            className="!text-xs !font-semibold !normal-case"
          />
          <Tab
            value="candidates"
            label={`Applicants (${candidates.length})`}
            className="!text-xs !font-semibold !normal-case"
          />
        </Tabs>
      </FadeUpItem>

      {/** Tab 1: Requisition Overview */}
      {activeTab === "overview" && (
        <FadeUpItem className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/** Left Column: Requisition Parameters & Rich Description */}
          <div className="lg:col-span-2 space-y-6">
            {/** Structured Requisition Details */}
            <div className="p-5 bg-card/60 border border-border rounded-[8px] space-y-4">
              <h3 className="text-sm font-semibold text-foreground flex items-center gap-2">
                <Work className="!w-4 !h-4 text-primary" /> Key Requisition Details
              </h3>

              <div className="grid grid-cols-2 sm:grid-cols-3 gap-y-4 gap-x-6 text-xs">
                <div className="flex flex-col gap-1">
                  <span className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wider">
                    Job Code
                  </span>
                  <span className="font-semibold text-foreground">{job.job_code}</span>
                </div>
                <div className="flex flex-col gap-1">
                  <span className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wider">
                    Department
                  </span>
                  <span className="font-medium text-foreground">
                    {job.department_rel?.name || "General"}
                  </span>
                </div>
                <div className="flex flex-col gap-1">
                  <span className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wider">
                    Location
                  </span>
                  <span className="font-medium text-foreground">{job.location}</span>
                </div>
                <div className="flex flex-col gap-1">
                  <span className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wider">
                    Employment Type
                  </span>
                  <span className="font-medium text-foreground">{job.employment_type}</span>
                </div>
                <div className="flex flex-col gap-1">
                  <span className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wider">
                    Experience Level
                  </span>
                  <span className="font-medium text-foreground">{job.experience_level}</span>
                </div>
                <div className="flex flex-col gap-1">
                  <span className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wider">
                    Approved Vacancies
                  </span>
                  <span className="font-semibold text-foreground">{job.vacancies}</span>
                </div>
                <div className="flex flex-col gap-1">
                  <span className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wider">
                    Target Role
                  </span>
                  <span className="font-medium text-foreground">
                    {job.role_rel?.name || "Standard Member"}
                  </span>
                </div>
                <div className="flex flex-col gap-1">
                  <span className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wider">
                    Work Shift
                  </span>
                  <span className="font-medium text-foreground">
                    {job.shift_rel?.name || "Standard General Shift"}
                  </span>
                </div>
                <div className="flex flex-col gap-1">
                  <span className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wider">
                    Salary Range
                  </span>
                  <span className="font-semibold text-emerald-600 dark:text-emerald-400">
                    {job.salary_range || "Not Disclosed"}
                  </span>
                </div>
              </div>
            </div>

            {/** Job Description Card */}
            <div className="p-5 bg-card/60 border border-border rounded-[8px] space-y-3">
              <h3 className="text-sm font-semibold text-foreground flex items-center gap-2">
                <CalendarToday className="!w-4 !h-4 text-primary" /> Full Job Description
              </h3>

              {job.description ? (
                <div
                  className="text-xs text-foreground leading-relaxed prose dark:prose-invert max-w-none [&_p]:mb-3 [&_ul]:list-disc [&_ul]:pl-5 [&_ol]:list-decimal [&_ol]:pl-5 [&_li]:mb-1 [&_strong]:font-semibold"
                  dangerouslySetInnerHTML={{ __html: job.description }}
                />
              ) : (
                <p className="text-xs text-muted-foreground italic">
                  No detailed description has been added for this job posting yet.
                </p>
              )}
            </div>
          </div>

          {/** Right Column: Metadata & Quick Summary */}
          <div className="space-y-6">
            <div className="p-5 bg-card/60 border border-border rounded-[8px] space-y-4">
              <h3 className="text-sm font-semibold text-foreground flex items-center gap-2">
                <Schedule className="!w-4 !h-4 text-primary" /> Posting Timeline
              </h3>

              <div className="space-y-3 text-xs">
                <div className="flex items-center justify-between pb-2 border-b border-border/60">
                  <span className="text-muted-foreground">Posting Status</span>
                  <span className="font-semibold text-foreground">{job.status}</span>
                </div>
                <div className="flex items-center justify-between pb-2 border-b border-border/60">
                  <span className="text-muted-foreground">Date Created</span>
                  <span className="font-medium text-foreground">{formatDate(job.created_at)}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-muted-foreground">Last Updated</span>
                  <span className="font-medium text-foreground">{formatDate(job.updated_at)}</span>
                </div>
              </div>
            </div>

            <div className="p-5 bg-card/60 border border-border rounded-[8px] space-y-3">
              <h3 className="text-sm font-semibold text-foreground">Hiring Workflow</h3>
              <p className="text-xs text-muted-foreground leading-relaxed">
                Candidates applying for this role will automatically be assigned to the Screening
                stage under Recruitment pipeline.
              </p>
              <Button
                variant="outlined"
                size="small"
                fullWidth
                onClick={() => navigate("/candidates")}
                className="!text-xs !normal-case !rounded-[5px] !border-border !text-foreground"
              >
                Go to Recruitment Pipeline
              </Button>
            </div>
          </div>
        </FadeUpItem>
      )}

      {/** Tab 2: Linked Applicants Table */}
      {activeTab === "candidates" && (
        <FadeUpItem className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-sm font-semibold text-foreground">Applied Candidates</h3>
              <p className="text-xs text-muted-foreground mt-0.5">
                Review and evaluate candidates linked to {job.title}
              </p>
            </div>
            <Button
              variant="contained"
              size="small"
              onClick={() => navigate("/candidates")}
              className="!text-xs !normal-case !rounded-[5px] !bg-primary"
            >
              Add Candidate
            </Button>
          </div>

          <DataTable data={candidates} columns={candidateColumns} pageSize={8} loading={false} />
        </FadeUpItem>
      )}

      {/** Edit Job Posting Drawer */}
      <AppDrawer
        open={isEditDrawerOpen}
        onClose={() => setIsEditDrawerOpen(false)}
        title="Edit Job Posting"
        subtitle={`Updating requisition ${job.job_code}`}
        width={750}
        footer={
          <div className="flex items-center justify-end gap-2 w-full">
            <Button
              variant="outlined"
              size="small"
              onClick={() => setIsEditDrawerOpen(false)}
              className="!border-border !text-muted-foreground hover:!text-foreground !text-xs !normal-case !rounded-[5px]"
            >
              Cancel
            </Button>
            <Button
              variant="contained"
              size="small"
              onClick={() => formik.handleSubmit()}
              disabled={updateMutation.isPending}
              className="!bg-primary !text-primary-foreground hover:!bg-primary/90 !text-xs !normal-case !font-semibold !rounded-[5px]"
            >
              {updateMutation.isPending ? (
                <CircularProgress size={14} color="inherit" />
              ) : (
                "Save Changes"
              )}
            </Button>
          </div>
        }
      >
        <form onSubmit={formik.handleSubmit} className="flex flex-col gap-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Input
              name="title"
              label="Job Title"
              placeholder="e.g. Senior Frontend Developer"
              required
              formik={formik}
            />
            <Select
              name="department_id"
              label="Department"
              options={departmentOptions}
              placeholder="Select Department"
              formik={formik}
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Select
              name="role_id"
              label="Role (Optional)"
              options={roleOptions}
              placeholder="Select exact Role mapping"
              formik={formik}
            />
            <Select
              name="shift_id"
              label="Work Shift (Optional)"
              options={shiftOptions}
              placeholder="Select exact Shift mapping"
              formik={formik}
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Input
              name="location"
              label="Location"
              placeholder="e.g. Remote, New York HQ"
              required
              formik={formik}
            />
            <Select
              name="employment_type"
              label="Employment Type"
              options={employmentOptions}
              required
              formik={formik}
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Select
              name="experience_level"
              label="Experience Level"
              options={experienceOptions}
              required
              formik={formik}
            />
            <Input
              name="salary_range"
              label="Salary Range"
              placeholder="e.g. $80k - $120k"
              formik={formik}
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Input type="number" name="vacancies" label="Vacancies" required formik={formik} />
            <Select name="status" label="Status" options={statusOptions} required formik={formik} />
          </div>

          <div className="flex flex-col gap-1.5 mt-2">
            <label className="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">
              Job Description
            </label>
            <RichTextEditor
              name="description"
              formik={formik}
              minHeight={250}
              placeholder="Write the job description, responsibilities, and requirements here..."
            />
          </div>
        </form>
      </AppDrawer>

      {/** Delete Confirmation Dialog */}
      <CustomDialog
        open={isDeleteDialogOpen}
        onClose={() => setIsDeleteDialogOpen(false)}
        title="Delete Job Posting"
        maxWidth="xs"
        actions={
          <div className="flex items-center justify-end gap-2 w-full">
            <Button
              variant="outlined"
              size="small"
              onClick={() => setIsDeleteDialogOpen(false)}
              className="!border-border !text-foreground !rounded-[5px] !text-xs !normal-case"
            >
              Cancel
            </Button>
            <Button
              variant="contained"
              size="small"
              color="error"
              onClick={() => {
                if (job) {
                  deleteMutation.mutate(job.id);
                }
              }}
              disabled={deleteMutation.isPending}
              className="!bg-destructive !text-destructive-foreground !rounded-[5px] !text-xs !font-semibold !normal-case"
            >
              {deleteMutation.isPending ? "Deleting..." : "Delete Posting"}
            </Button>
          </div>
        }
      >
        <p className="text-xs text-muted-foreground leading-relaxed">
          Are you sure you want to permanently delete job posting{" "}
          <strong className="text-foreground">{job.title}</strong> ({job.job_code})?
        </p>
      </CustomDialog>
    </StaggerContainer>
  );
};

export default JobPostingDetail;
