import { Close, PersonAdd } from "@mui/icons-material";
import { Button, CircularProgress } from "@mui/material";
import { useFormik } from "formik";
import React, { useMemo } from "react";
import * as Yup from "yup";

import { useGetMasterDepartments } from "services/masters";
import { useGetJobPostings } from "services/job-postings";

import { AppDrawer } from "shared/Drawer";
import { Input } from "shared/Input";
import { Select, type SelectOption } from "shared/Select";
import { ImagePicker } from "shared/ImagePicker";
import { DocumentPicker } from "shared/DocumentPicker";

export interface ManageCandidateFormValues {
  name: string;
  email: string;
  phone: string;
  position: string;
  department: string;
  experience: string;
  rating?: string;
  source?: string;
  resume_url?: string;
  job_posting_id?: number | "";
  avatar?: string;
}

export interface ManageCandidateProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (candidate: ManageCandidateFormValues) => Promise<void> | void;
}

const candidateValidationSchema = Yup.object({
  name: Yup.string()
    .trim()
    .required("Full name is required")
    .min(2, "Name must be at least 2 characters"),
  email: Yup.string().trim().email("Must be a valid email address").required("Email is required"),
  phone: Yup.string()
    .trim()
    .matches(/^[+0-9\s-]{10,15}$/, "Invalid phone number"),
  position: Yup.string().required("Position applied is required"),
  department: Yup.string().required("Department is required"),
  experience: Yup.string().required("Experience level is required"),
  source: Yup.string().nullable(),
  resume_url: Yup.string().nullable(),
  rating: Yup.number().typeError("Must be a number").min(0).max(5).nullable(),
});

const initialValues: ManageCandidateFormValues = {
  name: "",
  email: "",
  phone: "",
  position: "",
  department: "",
  experience: "Mid-Level",
  rating: "",
  source: "Company Website",
  resume_url: "",
  job_posting_id: "",
  avatar: "",
};

export const ManageCandidate: React.FC<ManageCandidateProps> = ({ open, onClose, onSubmit }) => {
  const { data: masterDepartmentsResponse } = useGetMasterDepartments();
  const { data: jobPostingsResponse } = useGetJobPostings();

  const departmentOptions: SelectOption[] = useMemo(() => {
    const depts = masterDepartmentsResponse?.data || [];
    return depts
      .filter((dept) => dept.status === "Active")
      .map((dept) => ({ label: dept.name, value: dept.name }));
  }, [masterDepartmentsResponse?.data]);

  const jobPostingOptions: SelectOption[] = useMemo(() => {
    const jobs = jobPostingsResponse?.data || [];
    return jobs
      .filter((job) => job.status === "Active")
      .map((job) => ({ label: `${job.title} (${job.job_code})`, value: job.id }));
  }, [jobPostingsResponse?.data]);

  const experienceOptions: SelectOption[] = [
    { label: "Entry-Level", value: "Entry-Level" },
    { label: "Mid-Level", value: "Mid-Level" },
    { label: "Senior", value: "Senior" },
    { label: "Lead", value: "Lead" },
    { label: "Executive", value: "Executive" },
  ];

  const sourceOptions: SelectOption[] = [
    { label: "Company Website", value: "Company Website" },
    { label: "LinkedIn", value: "LinkedIn" },
    { label: "Indeed", value: "Indeed" },
    { label: "Referral", value: "Referral" },
    { label: "Agency", value: "Agency" },
    { label: "Other", value: "Other" },
  ];

  const formik = useFormik<ManageCandidateFormValues>({
    initialValues,
    validationSchema: candidateValidationSchema,
    validateOnBlur: true,
    validateOnChange: true,
    onSubmit: async (values, { setSubmitting, resetForm }) => {
      try {
        await onSubmit(values);
        resetForm();
        onClose();
      } catch (err: unknown) {
        console.error(err);
      } finally {
        setSubmitting(false);
      }
    },
  });

  const handleClose = () => {
    formik.resetForm();
    onClose();
  };

  // Auto-fill position and department when a job posting is selected
  React.useEffect(() => {
    const jobId = formik.values.job_posting_id;
    if (jobId) {
      const job = (jobPostingsResponse?.data || []).find((j) => j.id === jobId);
      if (job) {
        if (!formik.touched.position) formik.setFieldValue("position", job.title);
        if (!formik.touched.department && job.department_rel?.name) {
          formik.setFieldValue("department", job.department_rel.name);
        }
      }
    }
  }, [formik.values.job_posting_id, formik.touched, jobPostingsResponse?.data]);

  return (
    <AppDrawer
      open={open}
      onClose={handleClose}
      title="Add New Candidate"
      subtitle="Manually add a candidate to the recruitment pipeline for evaluation."
      width={700}
      footer={
        <>
          <Button
            variant="outlined"
            onClick={handleClose}
            disabled={formik.isSubmitting}
            startIcon={<Close className="!w-4 !h-4" />}
            className="!border-border !bg-secondary !text-muted-foreground hover:!text-foreground !text-xs !normal-case !font-normal !px-4 !py-2 !rounded-[5px]"
          >
            Cancel
          </Button>
          <Button
            variant="contained"
            onClick={() => formik.handleSubmit()}
            disabled={formik.isSubmitting}
            startIcon={
              formik.isSubmitting ? (
                <CircularProgress size={14} color="inherit" />
              ) : (
                <PersonAdd className="!w-4 !h-4" />
              )
            }
            className="!bg-primary !text-primary-foreground hover:!bg-primary/90 !text-xs !normal-case !font-semibold !px-4 !py-2 !rounded-[5px] shadow-sm"
          >
            {formik.isSubmitting ? "Saving..." : "Save Candidate"}
          </Button>
        </>
      }
    >
      <form onSubmit={formik.handleSubmit} className="flex flex-col gap-4">
        <ImagePicker<ManageCandidateFormValues>
          name="avatar"
          label="Profile Picture"
          formik={formik}
          initials={formik.values.name ? formik.values.name.charAt(0).toUpperCase() : "CAN"}
        />

        <DocumentPicker<ManageCandidateFormValues>
          name="resume_url"
          label="Candidate Resume"
          formik={formik}
        />

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <Input<ManageCandidateFormValues>
            name="name"
            label="Full Name"
            placeholder="e.g. John Doe"
            required
            formik={formik}
          />

          <Input<ManageCandidateFormValues>
            name="email"
            label="Email Address"
            type="email"
            placeholder="e.g. john@example.com"
            required
            formik={formik}
          />
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <Input<ManageCandidateFormValues>
            name="phone"
            label="Phone Number"
            type="tel"
            placeholder="e.g. +1 234 567 8900"
            formik={formik}
          />

          <Select<ManageCandidateFormValues>
            name="source"
            label="Source of Hire"
            options={sourceOptions}
            formik={formik}
          />
        </div>

        <div className="flex flex-col gap-1.5 mt-2">
          <h4 className="text-sm font-bold text-foreground">Application Details</h4>
          <p className="text-xs text-muted-foreground mt-0.5 mb-2">
            Link this candidate to an open requisition or manually specify their role.
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <Select<ManageCandidateFormValues>
            name="job_posting_id"
            label="Link to Job Posting (Optional)"
            placeholder="Select a Job Posting"
            options={jobPostingOptions}
            formik={formik}
          />

          <Select<ManageCandidateFormValues>
            name="department"
            label="Department"
            placeholder="Select Department"
            options={departmentOptions}
            required
            formik={formik}
          />
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <Input<ManageCandidateFormValues>
            name="position"
            label="Position Applied"
            placeholder="e.g. Senior Developer"
            required
            formik={formik}
          />

          <Select<ManageCandidateFormValues>
            name="experience"
            label="Experience Level"
            options={experienceOptions}
            required
            formik={formik}
          />
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <Input<ManageCandidateFormValues>
            name="rating"
            type="number"
            label="Initial Rating (0-5)"
            placeholder="e.g. 4.5"
            formik={formik}
          />
        </div>
      </form>
    </AppDrawer>
  );
};

export default ManageCandidate;
