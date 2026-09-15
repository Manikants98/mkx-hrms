import {
  Add,
  Cancel,
  CheckCircle,
  Delete,
  Edit,
  Group,
  MoreHoriz,
  Search,
  WorkOutlined,
} from "@mui/icons-material";
import { Button, Chip, IconButton, InputAdornment, InputBase, MenuItem } from "@mui/material";
import { useFormik } from "formik";
import React, { useMemo, useState } from "react";
import {
  useCreateJobPosting,
  useDeleteJobPosting,
  useGetJobPostings,
  useUpdateJobPosting,
  type JobPosting,
} from "services/job-postings";
import { useGetMasterDepartments } from "services/masters";
import { ArrowMenu } from "shared/ArrowMenu";
import { CustomDialog } from "shared/CustomDialog";
import { DataTable, type ColumnDef } from "shared/DataTable";
import { AppDrawer } from "shared/Drawer";
import { Input } from "shared/Input";
import { RichTextEditor } from "shared/RichTextEditor";
import { Select, type SelectOption } from "shared/Select";
import { StatsCard } from "shared/StatsCard";
import * as Yup from "yup";

const JobPostingSchema = Yup.object().shape({
  title: Yup.string().required("Title is required"),
  department_id: Yup.number().nullable(),
  location: Yup.string().required("Location is required"),
  employment_type: Yup.string().required("Employment type is required"),
  experience_level: Yup.string().required("Experience level is required"),
  salary_range: Yup.string(),
  description: Yup.string(),
  vacancies: Yup.number().min(1, "Must be at least 1").required("Vacancies are required"),
  status: Yup.string().required("Status is required"),
});

type StatusFilter = "All" | "Active" | "Closed" | "Draft" | "On Hold";
const filterOptions: StatusFilter[] = ["All", "Active", "Closed"];

interface JobPostingRowActionsProps {
  row: JobPosting;
  onEdit: (item: JobPosting) => void;
  onDelete: (item: JobPosting) => void;
}

const JobPostingRowActions: React.FC<JobPostingRowActionsProps> = ({ row, onEdit, onDelete }) => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);

  return (
    <>
      <IconButton
        size="small"
        className="!text-muted-foreground hover:!text-foreground"
        onClick={(e) => setAnchorEl(e.currentTarget)}
      >
        <MoreHoriz />
      </IconButton>
      <ArrowMenu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={() => setAnchorEl(null)}
        arrowPosition="right"
        paperClassName="!min-w-[140px]"
      >
        <MenuItem
          onClick={() => {
            setAnchorEl(null);
            onEdit(row);
          }}
          className="!text-xs !py-2 !px-3 !gap-2 !rounded-[5px] !text-muted-foreground hover:!text-foreground hover:!bg-secondary/70"
        >
          <Edit className="!w-4 !h-4" />
          Edit
        </MenuItem>
        <MenuItem
          onClick={() => {
            setAnchorEl(null);
            onDelete(row);
          }}
          className="!text-xs !py-2 !px-3 !gap-2 !rounded-[5px] !text-destructive hover:!bg-destructive/10"
        >
          <Delete className="!w-4 !h-4 text-destructive" />
          <span className="text-destructive font-medium">Delete</span>
        </MenuItem>
      </ArrowMenu>
    </>
  );
};

export const JobPostingMasterTab: React.FC = () => {
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState<StatusFilter>("All");
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [editingJob, setEditingJob] = useState<JobPosting | null>(null);
  const [deletingItem, setDeletingItem] = useState<JobPosting | null>(null);

  const { data: jobPostingsData, isLoading, refetch } = useGetJobPostings();
  const { data: departmentsResponse } = useGetMasterDepartments();
  const departmentsData = departmentsResponse?.data;

  const createMutation = useCreateJobPosting(() => {
    handleCloseDrawer();
    refetch();
  });

  const updateMutation = useUpdateJobPosting(() => {
    handleCloseDrawer();
    refetch();
  });

  const deleteMutation = useDeleteJobPosting(() => {
    refetch();
    setDeletingItem(null);
  });

  const formik = useFormik({
    initialValues: {
      title: "",
      department_id: "" as number | "",
      location: "",
      employment_type: "Full-Time",
      experience_level: "Mid-Level",
      salary_range: "",
      description: "",
      vacancies: 1,
      status: "Active",
    },
    validationSchema: JobPostingSchema,
    onSubmit: (values) => {
      const payload = {
        ...values,
        department_id: values.department_id === "" ? null : Number(values.department_id),
      };
      if (editingJob) {
        updateMutation.mutate({ id: editingJob.id, ...payload });
      } else {
        createMutation.mutate(payload);
      }
    },
  });

  const handleOpenDrawer = (job?: JobPosting) => {
    if (job) {
      setEditingJob(job);
      formik.setValues({
        title: job.title,
        department_id: job.department_id || "",
        location: job.location,
        employment_type: job.employment_type,
        experience_level: job.experience_level,
        salary_range: job.salary_range || "",
        description: job.description || "",
        vacancies: job.vacancies,
        status: job.status,
      });
    } else {
      setEditingJob(null);
      formik.resetForm();
    }
    setIsDrawerOpen(true);
  };

  const handleCloseDrawer = () => {
    setIsDrawerOpen(false);
    setTimeout(() => {
      setEditingJob(null);
      formik.resetForm();
    }, 200);
  };

  const departmentOptions: SelectOption[] = useMemo(() => {
    return (departmentsData || []).map((d) => ({ label: d.name, value: d.id }));
  }, [departmentsData]);

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
    { label: "Draft", value: "Draft" },
    { label: "Active", value: "Active" },
    { label: "Closed", value: "Closed" },
    { label: "On Hold", value: "On Hold" },
  ];

  const jobPostings = useMemo(() => jobPostingsData?.data || [], [jobPostingsData]);

  const filteredData = useMemo(() => {
    return jobPostings.filter((job) => {
      const matchesSearch =
        job.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
        job.job_code.toLowerCase().includes(searchTerm.toLowerCase());
      const matchesStatus = statusFilter === "All" || job.status === statusFilter;
      return matchesSearch && matchesStatus;
    });
  }, [jobPostings, searchTerm, statusFilter]);

  const dynamicKpiCards = useMemo(() => {
    const total = jobPostings.length;
    const active = jobPostings.filter((s) => s.status === "Active").length;
    const closed = jobPostings.filter((s) => s.status === "Closed").length;
    const totalVacancies = jobPostings.reduce((acc, s) => acc + (s.vacancies || 0), 0);

    return [
      {
        id: "total-postings",
        title: "Total Postings",
        value: String(total),
        subtext: "Job requisitions",
        icon: WorkOutlined,
        icon_color: "text-[#00b1d8]",
        icon_bg: "bg-[#00b1d8]/10",
      },
      {
        id: "active-postings",
        title: "Active Postings",
        value: String(active),
        subtext: `${total > 0 ? ((active / total) * 100).toFixed(1) : 0}% open positions`,
        icon: CheckCircle,
        icon_color: "text-[#45ba50]",
        icon_bg: "bg-[#45ba50]/10",
      },
      {
        id: "closed-postings",
        title: "Closed Postings",
        value: String(closed),
        subtext: `${total > 0 ? ((closed / total) * 100).toFixed(1) : 0}% filled or closed`,
        icon: Cancel,
        icon_color: "text-[#f14d4c]",
        icon_bg: "bg-[#f14d4c]/10",
      },
      {
        id: "total-vacancies",
        title: "Total Vacancies",
        value: String(totalVacancies),
        subtext: "Open headcount positions",
        icon: Group,
        icon_color: "text-[#ad87ed]",
        icon_bg: "bg-[#ad87ed]/10",
      },
    ];
  }, [jobPostings]);

  const columns: ColumnDef<JobPosting>[] = [
    {
      header: "JOB TITLE",
      cell: (row) => (
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-[5px] bg-primary/10 text-primary flex items-center justify-center shrink-0">
            <WorkOutlined className="!w-4 !h-4" />
          </div>
          <div className="flex flex-col">
            <span className="font-semibold text-foreground text-sm">{row.title}</span>
            <span className="text-xs text-muted-foreground mt-0.5">{row.job_code}</span>
          </div>
        </div>
      ),
      width: "25%",
    },
    {
      header: "DEPARTMENT & LOCATION",
      cell: (row) => (
        <div className="flex flex-col">
          <span className="text-sm font-medium text-foreground">
            {row.department_rel?.name || "General"}
          </span>
          <span className="text-xs text-muted-foreground mt-0.5">{row.location}</span>
        </div>
      ),
      width: "20%",
    },
    {
      header: "TYPE & EXP",
      cell: (row) => (
        <div className="flex flex-col">
          <span className="text-sm text-foreground">{row.employment_type}</span>
          <span className="text-xs text-muted-foreground mt-0.5">{row.experience_level}</span>
        </div>
      ),
      width: "15%",
    },
    {
      header: "VACANCIES",
      cell: (row) => <span className="text-sm font-medium text-foreground">{row.vacancies}</span>,
      width: "10%",
    },
    {
      header: "CANDIDATES",
      cell: (row) => (
        <span className="text-sm font-medium text-primary bg-primary/10 px-2 py-0.5 rounded-[5px]">
          {row._count?.candidates || 0}
        </span>
      ),
      width: "10%",
    },
    {
      header: "STATUS",
      cell: (row) => {
        if (row.status === "Active") {
          return (
            <Chip
              icon={<CheckCircle className="!w-3.5 !h-3.5" />}
              label="Active"
              size="small"
              color="success"
              variant="outlined"
              className="!h-6 !text-xs !bg-success/10 !border-success/20 !font-medium"
            />
          );
        }
        if (row.status === "Closed") {
          return (
            <Chip
              icon={<Cancel className="!w-3.5 !h-3.5" />}
              label="Closed"
              size="small"
              color="error"
              variant="outlined"
              className="!h-6 !text-xs !bg-destructive/10 !border-destructive/20 !font-medium"
            />
          );
        }
        return (
          <Chip
            label={row.status}
            size="small"
            variant="outlined"
            className="!h-6 !text-xs !bg-secondary !text-muted-foreground !border !border-border !font-medium"
          />
        );
      },
      width: "10%",
    },
    {
      header: "ACTION",
      align: "right",
      cell: (row) => (
        <JobPostingRowActions
          row={row}
          onEdit={(item) => handleOpenDrawer(item)}
          onDelete={(item) => setDeletingItem(item)}
        />
      ),
      width: "5%",
    },
  ];

  return (
    <div className="space-y-4">
      {/* KPI Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {dynamicKpiCards.map((card) => (
          <StatsCard
            key={card.id}
            title={card.title}
            value={card.value}
            subtext={card.subtext}
            icon={card.icon}
            iconBg={card.icon_bg}
            iconColor={card.icon_color}
          />
        ))}
      </div>

      {/* Action Toolbar */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div className="flex flex-wrap items-center gap-3 w-full sm:w-auto">
          <InputBase
            placeholder="Search job titles..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full sm:w-64 h-9 pl-3 pr-4 rounded-[5px] bg-secondary border border-border text-sm text-foreground [&_input]:p-0 [&_input::placeholder]:text-muted-foreground [&_input::placeholder]:opacity-100 transition-all duration-200"
            startAdornment={
              <InputAdornment position="start">
                <Search className="!w-4 !h-4 text-muted-foreground" />
              </InputAdornment>
            }
          />
          <div className="flex items-center gap-1 bg-card/60 p-0.5 h-9 rounded-[5px] border border-border/50 box-border">
            {filterOptions.map((status) => (
              <Button
                key={status}
                size="small"
                onClick={() => setStatusFilter(status)}
                className={`${
                  statusFilter === status
                    ? "!bg-accent !text-accent-foreground"
                    : "!text-muted-foreground"
                }`}
              >
                {status}
              </Button>
            ))}
          </div>
        </div>

        <div className="flex items-center gap-2">
          <Button
            variant="contained"
            size="small"
            onClick={() => handleOpenDrawer()}
            startIcon={<Add className="!w-4 !h-4" />}
            className="!bg-primary !text-primary-foreground hover:!bg-primary/90 !text-xs !normal-case !font-semibold !px-3.5 !py-2 !rounded-[5px] shadow-sm"
          >
            Add Posting
          </Button>
        </div>
      </div>

      {/* Data Table */}
      <DataTable data={filteredData} columns={columns} pageSize={10} loading={isLoading} />

      {/* Form Drawer */}
      <AppDrawer
        open={isDrawerOpen}
        onClose={handleCloseDrawer}
        title={editingJob ? "Edit Job Posting" : "Create Job Posting"}
        footer={
          <div className="flex justify-end gap-2 pt-4">
            <Button variant="outlined" onClick={handleCloseDrawer} className="!normal-case">
              Cancel
            </Button>
            <Button
              variant="contained"
              onClick={() => formik.handleSubmit()}
              disabled={createMutation.isPending || updateMutation.isPending}
              className="!normal-case"
            >
              {editingJob ? "Save Changes" : "Create Posting"}
            </Button>
          </div>
        }
        width={750}
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
              formik={formik as any}
              minHeight={250}
              placeholder="Write the job description, responsibilities, and requirements here..."
            />
          </div>
        </form>
      </AppDrawer>

      {/* Delete Confirmation Dialog */}
      <CustomDialog
        open={Boolean(deletingItem)}
        onClose={() => setDeletingItem(null)}
        title="Delete Job Posting"
        maxWidth="xs"
        actions={
          <div className="flex items-center justify-end gap-2 w-full">
            <Button
              variant="outlined"
              size="small"
              onClick={() => setDeletingItem(null)}
              className="!border-border !text-foreground !rounded-[5px] !text-xs"
            >
              Cancel
            </Button>
            <Button
              variant="contained"
              size="small"
              color="error"
              onClick={() => {
                if (deletingItem) {
                  deleteMutation.mutate(deletingItem.id);
                }
              }}
              disabled={deleteMutation.isPending}
              className="!bg-destructive !text-destructive-foreground !rounded-[5px] !text-xs !font-semibold"
            >
              {deleteMutation.isPending ? "Deleting..." : "Delete Posting"}
            </Button>
          </div>
        }
      >
        <p className="text-xs text-muted-foreground leading-relaxed">
          Are you sure you want to delete job posting{" "}
          <strong className="text-foreground">{deletingItem?.title}</strong>?
        </p>
      </CustomDialog>
    </div>
  );
};
