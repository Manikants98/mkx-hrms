import React from "react";
import { Button } from "@mui/material";
import { useFormik } from "formik";
import { useContactUs } from "../../../services/contact";
import { CustomDialog } from "../../../components/shared/CustomDialog";
import { Input } from "../../../components/shared/Input";

interface ContactUsModalProps {
  open: boolean;
  onClose: () => void;
}

export const ContactUsModal: React.FC<ContactUsModalProps> = ({ open, onClose }) => {
  const { mutateAsync, isPending } = useContactUs();

  const formik = useFormik({
    initialValues: {
      name: "",
      email: "",
      number: "",
      subject: "",
      message: "",
    },
    onSubmit: (values, { resetForm }) => {
      mutateAsync(values)
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
      title="Contact Us"
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
            form="contact-us-form"
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
            {isPending ? "Sending..." : "Send Message"}
          </Button>
        </>
      }
    >
      <form id="contact-us-form" onSubmit={formik.handleSubmit} className="flex flex-col gap-3">
        <Input required label="Name" name="name" value={formik.values.name} onChange={formik.handleChange} />
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
            label="Phone Number (Optional)"
            name="number"
            value={formik.values.number}
            onChange={formik.handleChange}
          />
        </div>

        <Input
          required
          label="Subject"
          name="subject"
          value={formik.values.subject}
          onChange={formik.handleChange}
        />
        <Input
          required
          label="Message"
          name="message"
          type="textarea"
          value={formik.values.message}
          onChange={formik.handleChange}
        />
      </form>
    </CustomDialog>
  );
};
