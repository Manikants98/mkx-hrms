import { Button } from "@mui/material";
import { useState } from "react";
import { useFormik } from "formik";
import * as Yup from "yup";
import { type Employee, useResetEmployeePassword } from "services/employees";
import { CustomDialog } from "components/shared/CustomDialog";
import { Input } from "components/shared/Input";

interface ResetPasswordDialogProps {
  open: boolean;
  onClose: () => void;
  employee: Employee | null;
}

const validationSchema = Yup.object({
  password: Yup.string()
    .min(8, "Password must be at least 8 characters long")
    .required("Password is required"),
  confirmPassword: Yup.string()
    .oneOf([Yup.ref("password")], "Passwords must match")
    .required("Please confirm your password"),
});

export function ResetPasswordDialog({ open, onClose, employee }: ResetPasswordDialogProps) {
  const [error, setError] = useState("");

  const resetMutation = useResetEmployeePassword(employee?.id || "");

  const formik = useFormik({
    initialValues: {
      password: "",
      confirmPassword: "",
    },
    validationSchema,
    validateOnMount: false,
    validateOnChange: true,
    onSubmit: async (values, { resetForm }) => {
      try {
        setError("");
        await resetMutation.mutateAsync({ password: values.password });
        resetForm();
        onClose();
      } catch (err: any) {
        setError(err?.response?.data?.message || "Failed to reset password");
      }
    },
  });

  const handleClose = () => {
    formik.resetForm();
    setError("");
    onClose();
  };

  if (!employee) return null;

  return (
    <CustomDialog
      open={open}
      onClose={handleClose}
      title="Reset Password"
      subtitle={`Set a new password for ${employee.name}`}
      maxWidth="xs"
      actions={
        <>
          <Button
            onClick={handleClose}
            className="!text-muted-foreground hover:!bg-secondary !text-sm !normal-case !font-medium"
          >
            Cancel
          </Button>
          <Button
            onClick={() => formik.handleSubmit()}
            variant="contained"
            disabled={resetMutation.isPending || !formik.isValid || !formik.dirty}
            className="!bg-primary hover:!bg-primary/90 !text-primary-foreground !text-sm !normal-case !font-semibold !rounded-lg !px-4"
          >
            {resetMutation.isPending ? "Resetting..." : "Reset Password"}
          </Button>
        </>
      }
    >
      {error && (
        <div className="p-3 rounded-lg bg-destructive/10 border border-destructive/20 text-destructive text-sm font-medium">
          {error}
        </div>
      )}

      <div>
        <label className="block text-sm font-medium text-foreground mb-1.5">New Password</label>
        <Input
          name="password"
          type="password"
          placeholder="Enter new password"
          formik={formik}
          className="!bg-secondary !rounded-lg"
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-foreground mb-1.5">Confirm Password</label>
        <Input
          name="confirmPassword"
          type="password"
          placeholder="Confirm new password"
          formik={formik}
          className="!bg-secondary !rounded-lg"
        />
      </div>
    </CustomDialog>
  );
}
