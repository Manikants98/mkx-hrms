import { Button, Chip, InputAdornment, InputBase } from "@mui/material";
import { useFormik } from "formik";
import { Edit2, Plus, Search, Trash2 } from "lucide-react";
import React, { useMemo, useState } from "react";
import {
  useCreateJobPosting,
  useDeleteJobPosting,
  useGetJobPostings,
  useUpdateJobPosting,
  type JobPosting,
} from "services/job-postings";
import { useGetMasterDepartments } from "services/masters";
import { DataTable, type ColumnDef } from "shared/DataTable";
import { AppDrawer } from "shared/Drawer";
import { RichTextEditor } from "shared/RichTextEditor";
import { Input } from "shared/Input";
import { Select, type SelectOption } from "shared/Select";
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

export const JobPostingMasterTab: React.FC = () => {
  const [searchTerm, setSearchTerm] = useState("");
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [editingJob, setEditingJob] = useState<JobPosting | null>(null);

  const { data: jobPostingsData, isLoading } = useGetJobPostings();
  const { data: departmentsResponse } = useGetMasterDepartments();
  const departmentsData = departmentsResponse?.data;

  const createMutation = useCreateJobPosting(() => {
    handleCloseDrawer();
  });

  const updateMutation = useUpdateJobPosting(() => {
    handleCloseDrawer();
  });

  const deleteMutation = useDeleteJobPosting();

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
    return jobPostings.filter(
      (job) =>
        job.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
        job.job_code.toLowerCase().includes(searchTerm.toLowerCase()),
    );
  }, [jobPostings, searchTerm]);

  const columns: ColumnDef<JobPosting>[] = [
    {
      header: "JOB TITLE",
      cell: (row) => (
        <div className="flex flex-col">
          <span className="font-semibold text-foreground text-sm">{row.title}</span>
          <span className="text-xs text-muted-foreground mt-0.5">{row.job_code}</span>
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
      cell: (row) => (
        <Chip
          label={row.status}
          size="small"
          className={`!h-6 !text-[11px] !font-medium ${
            row.status === "Active"
              ? "!bg-success/10 !text-success !border !border-success/20"
              : row.status === "Closed"
                ? "!bg-destructive/10 !text-destructive !border !border-destructive/20"
                : "!bg-secondary !text-muted-foreground !border !border-border"
          }`}
        />
      ),
      width: "10%",
    },
    {
      header: "ACTION",
      cell: (row) => (
        <div className="flex items-center justify-end gap-1">
          <Button
            size="small"
            className="!min-w-0 !p-1.5 !text-muted-foreground hover:!text-foreground hover:!bg-secondary"
            onClick={() => handleOpenDrawer(row)}
          >
            <Edit2 className="w-4 h-4" />
          </Button>
          <Button
            size="small"
            className="!min-w-0 !p-1.5 !text-muted-foreground hover:!text-destructive hover:!bg-destructive/10"
            onClick={() => {
              if (window.confirm("Are you sure you want to delete this job posting?")) {
                deleteMutation.mutate(row.id);
              }
            }}
          >
            <Trash2 className="w-4 h-4" />
          </Button>
        </div>
      ),
      width: "10%",
      align: "right",
    },
  ];

  return (
    <div className="space-y-4">
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 bg-card/40 p-4 border border-border rounded-[8px]">
        <div>
          <h2 className="text-base font-semibold text-foreground">Job Postings List</h2>
          <p className="text-xs text-muted-foreground mt-1">
            Manage open vacancies and hiring requisitions
          </p>
        </div>
        <div className="flex items-center gap-3 w-full sm:w-auto">
          <InputBase
            placeholder="Search job titles..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full sm:w-64 h-9 pl-3 pr-4 rounded-[5px] bg-secondary border border-border text-sm text-foreground [&_input]:p-0"
            startAdornment={
              <InputAdornment position="start">
                <Search className="w-4 h-4 text-muted-foreground" />
              </InputAdornment>
            }
          />
          <Button
            variant="contained"
            size="small"
            startIcon={<Plus className="w-3.5 h-3.5" />}
            onClick={() => handleOpenDrawer()}
            className="!bg-primary !text-primary-foreground hover:!bg-primary/90 !text-xs !normal-case !font-semibold !px-4 !py-2 !rounded-[5px] shadow-sm whitespace-nowrap"
          >
            Add Posting
          </Button>
        </div>
      </div>

      <DataTable data={filteredData} columns={columns} pageSize={10} loading={isLoading} />

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
    </div>
  );
};
