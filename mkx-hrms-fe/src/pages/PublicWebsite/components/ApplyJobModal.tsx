import React from "react";
import { Button } from "@mui/material";
import { useFormik } from "formik";
import { useCreateCandidate } from "../../../services/recruitment";
import { CustomDialog } from "../../../components/shared/CustomDialog";
import { Input } from "../../../components/shared/Input";
import { DocumentPicker } from "../../../components/shared/DocumentPicker";

interface ApplyJobFormValues {
  name: string;
  email: string;
  phone: string;
  experience: string;
  resume_url: string;
}

interface ApplyJobModalProps {
  open: boolean;
  onClose: () => void;
  job: any;
}

export const ApplyJobModal: React.FC<ApplyJobModalProps> = ({ open, onClose, job }) => {
  const { mutateAsync, isPending } = useCreateCandidate();

  const formik = useFormik<ApplyJobFormValues>({
    initialValues: {
      name: "",
      email: "",
      phone: "",
      experience: "",
      resume_url: "",
    },
    onSubmit: (values, { resetForm }) => {
      if (!job) return;

      mutateAsync({
        name: values.name,
        email: values.email,
        phone: values.phone,
        experience: values.experience,
        resume_url: values.resume_url,
        position: job.title,
        department: job.department_rel?.name || "General",
        stage: "Screening",
        status: "Active",
        rating: "0",
        source: "Website",
        applied_date: new Date().toISOString(),
      })
        .then(() => {
          resetForm();
          onClose();
        })
        .catch(() => {});
    },
  });

  return (
    <CustomDialog
      open={open}
      onClose={onClose}
      title={`Apply for ${job?.title || "Job"}`}
      maxWidth="sm"
      actions={
        <>
          <Button
            onClick={onClose}
            variant="outlined"
            sx={{
              borderColor: "var(--border)",
              color: "var(--foreground)",
              textTransform: "none",
              fontWeight: 600,
            }}
          >
            Cancel
          </Button>
          <Button
            type="submit"
            form="apply-job-form"
            variant="contained"
            disabled={isPending}
            sx={{
              bgcolor: "var(--primary)",
              color: "var(--primary-foreground)",
              textTransform: "none",
              fontWeight: 600,
              "&:hover": { bgcolor: "var(--chart-1)" },
            }}
          >
            {isPending ? "Submitting..." : "Submit Application"}
          </Button>
        </>
      }
    >
      <form id="apply-job-form" onSubmit={formik.handleSubmit} className="flex flex-col gap-3">
        <DocumentPicker<ApplyJobFormValues>
          name="resume_url"
          label="Candidate Resume (Optional)"
          formik={formik}
        />

        <Input
          required
          label="Full Name"
          name="name"
          value={formik.values.name}
          onChange={formik.handleChange}
        />

        <div className="grid grid-cols-2 gap-2">
          <Input
            required
            label="Email"
            name="email"
            type="email"
            value={formik.values.email}
            onChange={formik.handleChange}
          />
          <Input
            required
            label="Phone Number"
            name="phone"
            value={formik.values.phone}
            onChange={formik.handleChange}
          />
        </div>

        <Input
          required
          label="Years of Experience"
          name="experience"
          value={formik.values.experience}
          onChange={formik.handleChange}
          placeholder="e.g. 3 years"
        />
      </form>
    </CustomDialog>
  );
};
