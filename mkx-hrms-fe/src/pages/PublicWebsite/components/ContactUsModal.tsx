import React, { useState } from "react";
import { Button } from "@mui/material";
import { useContactUs } from "../../../services/contact";
import { CustomDialog } from "../../../components/shared/CustomDialog";
import { Input } from "../../../components/shared/Input";

interface ContactUsModalProps {
  open: boolean;
  onClose: () => void;
}

export const ContactUsModal: React.FC<ContactUsModalProps> = ({ open, onClose }) => {
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    number: "",
    subject: "",
    message: "",
  });

  const { mutate, isPending } = useContactUs(() => {
    onClose();
    setFormData({ name: "", email: "", number: "", subject: "", message: "" });
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  /**
   * Handle contact form submission
   */
  const handleSubmit = (e: React.SubmitEvent<HTMLFormElement>) => {
    e.preventDefault();
    mutate(formData);
  };

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
      <form id="contact-us-form" onSubmit={handleSubmit} className="flex flex-col gap-3">
        <Input required label="Name" name="name" value={formData.name} onChange={handleChange} />
        <div className="grid grid-cols-2 gap-2">
          <Input
            required
            label="Email"
            name="email"
            type="email"
            value={formData.email}
            onChange={handleChange}
          />
          <Input
            label="Phone Number (Optional)"
            name="number"
            value={formData.number}
            onChange={handleChange}
          />
        </div>

        <Input
          required
          label="Subject"
          name="subject"
          value={formData.subject}
          onChange={handleChange}
        />
        <Input
          required
          label="Message"
          name="message"
          type="textarea"
          value={formData.message}
          onChange={handleChange}
        />
      </form>
    </CustomDialog>
  );
};
