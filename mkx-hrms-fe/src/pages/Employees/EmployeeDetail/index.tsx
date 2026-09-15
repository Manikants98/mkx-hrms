import {
  AccountBalanceWallet,
  ArrowBack,
  Badge,
  BeachAccess,
  CalendarMonth,
  CheckCircle,
  Edit,
  Email,
  LocationOn,
  Paid,
  Person,
  Phone,
  Schedule,
  SupervisorAccount,
  Visibility,
  Work,
} from "@mui/icons-material";
import { Avatar, Button, Chip, IconButton, Skeleton, Tab, Tabs } from "@mui/material";
import React, { useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import {
  useGetEmployeeById,
  useUpdateEmployee,
  type Employee,
  type LeaveBalance,
} from "services/employees";
import { exportPayslipPdf } from "services/payroll";
import { DataTable, type ColumnDef } from "shared/DataTable";
import { AppDrawer } from "shared/Drawer";

const parseAmt = (val: string | number | undefined) =>
  Number(String(val || 0).replace(/[^0-9.-]+/g, "")) || 0;

import { StatsCard } from "shared/StatsCard";
import { ManageEmployee, type ManageEmployeeFormValues } from "../ManageEmployee";
import { GenerateEmployeeSalaryDialog } from "./GenerateEmployeeSalaryDialog";

/**
 * Tab identifiers supported on Employee Detail workspace
 */
type DetailTab = "overview" | "compensation" | "payroll" | "shift" | "leaves";

/**
 * Dedicated Employee Detail Page component providing comprehensive employee records,
 * personal and organizational data, compensation structure breakdown,
 * and direct salary calculation & generation workflow.
 *
 * @returns The rendered Employee Detail view
 */
export default function EmployeeDetail(): React.ReactElement {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [activeTab, setActiveTab] = useState<DetailTab>("overview");
  const [isSalaryDialogOpen, setIsSalaryDialogOpen] = useState<boolean>(false);
  const [isEditDrawerOpen, setIsEditDrawerOpen] = useState<boolean>(false);
  const [isDownloadingPdf, setIsDownloadingPdf] = useState(false);
  const [viewingPayslip, setViewingPayslip] = useState<
    NonNullable<Employee["payrolls"]>[number] | null
  >(null);

  const { data: employeeResponse, isLoading, refetch: refetchEmployee } = useGetEmployeeById(id);
  const employee = employeeResponse?.data;

  const updateEmployee = useUpdateEmployee(employee?.id || "", () => {
    refetchEmployee();
    setIsEditDrawerOpen(false);
  });

  const handleDownloadPdf = async () => {
    if (!viewingPayslip) return;
    try {
      setIsDownloadingPdf(true);
      await exportPayslipPdf(viewingPayslip.db_id || viewingPayslip.id);
    } catch (error) {
      console.error("Failed to download PDF", error);
    } finally {
      setIsDownloadingPdf(false);
    }
  };

  const payslipItems = useMemo(() => {
    if (viewingPayslip?.items && viewingPayslip.items.length > 0) {
      return viewingPayslip.items;
    }
    if (!employee?.salary_structures) return [];

    const baseStructure = employee.salary_structures.find(
      (s) => s.salary_structure?.is_base_salary,
    );
    const baseAmount = baseStructure ? Number(baseStructure.amount) : 0;

    return employee.salary_structures.map((ss) => {
      const isDed = ss.salary_structure?.is_deduction;
      const rawAmt = Number(ss.amount) || 0;
      let finalAmt = rawAmt;
      if (ss.salary_structure?.calculation_type === "Percentage") {
        finalAmt = (baseAmount * rawAmt) / 100;
      }

      return {
        name: ss.salary_structure?.name || `Structure #${ss.salary_structure_id}`,
        amount: finalAmt,
        category: isDed ? "Deduction" : "Earning",
      } as const;
    });
  }, [viewingPayslip, employee?.salary_structures]);

  /**
   * Financial summary metrics calculated across employee's active salary structures
   */
  const { totalGross, totalDeductions, netSalary, earningsCount, deductionsCount } = useMemo(() => {
    let gross = 0;
    let deductions = 0;
    let earn = 0;
    let ded = 0;

    const structures = employee?.salary_structures || [];

    const baseStructure = structures.find((s) => s.salary_structure?.is_base_salary);
    const baseAmount = baseStructure ? Number(baseStructure.amount) : 0;

    structures.forEach((item) => {
      const rawAmt = Number(item.amount) || 0;
      let amt = rawAmt;
      if (item.salary_structure?.calculation_type === "Percentage") {
        amt = (baseAmount * rawAmt) / 100;
      }

      if (item.salary_structure?.is_deduction) {
        deductions += amt;
        ded += 1;
      } else {
        gross += amt;
        earn += 1;
      }
    });

    return {
      totalGross: gross,
      totalDeductions: deductions,
      netSalary: Math.max(0, gross - deductions),
      earningsCount: earn,
      deductionsCount: ded,
    };
  }, [employee?.salary_structures]);

  /**
   * Handles saving edited profile from the drawer
   *
   * @param values - Form values submitted from ManageEmployee drawer
   */
  const handleSaveEdit = async (values: ManageEmployeeFormValues) => {
    if (!employee) return;
    await updateEmployee.mutateAsync({
      name: values.name,
      email: values.email,
      phone: values.phone,
      address: values.address,
      role_id: Number(values.role_id) || undefined,
      department_id: Number(values.department_id) || undefined,
      shift_id: values.shift_id ? Number(values.shift_id) : undefined,
      status: values.status,
      manager_id: values.manager_id ? Number(values.manager_id) : undefined,
      join_date: values.join_date,
      birth_date: values.birth_date || undefined,
      avatar: values.avatar,
      salary_structures: values.salary_structures,
    });
  };

  const salaryColumns = useMemo<
    ColumnDef<NonNullable<Employee["salary_structures"]>[number]>[]
  >(() => {
    const baseStructure = employee?.salary_structures?.find(
      (s) => s.salary_structure?.is_base_salary,
    );
    const baseAmount = baseStructure ? Number(baseStructure.amount) : 0;
    return [
      {
        header: "Structure Component",
        cell: (row) => {
          const master = row.salary_structure;
          return (
            <div className="flex items-center gap-3 py-1">
              <Avatar
                variant="rounded"
                className="!bg-secondary !text-foreground !border !border-border shrink-0"
              >
                {master?.name ? master.name.charAt(0).toUpperCase() : "S"}
              </Avatar>
              <div className="flex flex-col">
                <span className="font-semibold text-foreground">
                  {master?.name || `Structure #${row.salary_structure_id}`}
                </span>
                <span className="text-[11px] text-muted-foreground">{master?.code}</span>
              </div>
            </div>
          );
        },
      },
      {
        header: "Category",
        cell: (row) => {
          const isDeduction = row.salary_structure?.is_deduction;
          const isBase = row.salary_structure?.is_base_salary;
          return (
            <div className="flex items-center gap-1.5 py-1">
              <Chip
                label={isDeduction ? "Deduction" : "Earning"}
                size="small"
                color={isDeduction ? "error" : "success"}
                variant="outlined"
              />
              {isBase && <Chip label="Base" size="small" color="primary" variant="outlined" />}
            </div>
          );
        },
      },
      {
        header: "Tax Status",
        cell: (row) => (
          <span className="text-xs text-muted-foreground">
            {row.salary_structure?.is_taxable ? "Taxable" : "Exempt"}
          </span>
        ),
      },
      {
        header: "Calculation",
        cell: (row) => (
          <span className="text-xs text-muted-foreground">
            {row.salary_structure?.calculation_type || "Fixed"}
          </span>
        ),
      },
      {
        header: "Monthly Amount (₹)",
        align: "right",
        cell: (row) => {
          const rawAmt = Number(row.amount) || 0;
          const isPercentage = row.salary_structure?.calculation_type === "Percentage";
          const finalAmt = isPercentage ? (baseAmount * rawAmt) / 100 : rawAmt;
          return (
            <span className="font-semibold text-foreground">₹{finalAmt.toLocaleString()}</span>
          );
        },
      },
    ];
  }, [employee?.salary_structures]);

  const payrollColumns = useMemo<ColumnDef<NonNullable<Employee["payrolls"]>[number]>[]>(() => {
    return [
      {
        header: "Payslip Code",
        cell: (row) => <span className="font-mono font-semibold text-primary">{row.id}</span>,
      },
      {
        header: "Period",
        cell: (row) => (
          <span className="font-medium text-foreground">
            {row.month}/{row.year}
          </span>
        ),
      },
      {
        header: "Working Days",
        cell: (row) => (
          <span className="text-muted-foreground">{row.working_days ?? "—"} days</span>
        ),
      },
      {
        header: "LOP Days",
        cell: (row) => (
          <span
            className={`font-medium ${(row.lop_days || 0) > 0 ? "text-rose-500" : "text-muted-foreground"}`}
          >
            {row.lop_days || 0} days
          </span>
        ),
      },
      {
        header: "Gross Pay",
        cell: (row) => <span className="text-foreground font-medium">{row.gross_pay}</span>,
      },
      {
        header: "Deductions",
        cell: (row) => <span className="text-rose-500 font-medium">-{row.total_deductions}</span>,
      },
      {
        header: "Net Salary",
        cell: (row) => <span className="text-foreground font-bold text-sm">{row.net_pay}</span>,
      },
      {
        header: "Status",
        cell: (row) => (
          <Chip
            label={row.status}
            size="small"
            color={
              row.status === "Paid" ? "success" : row.status === "Processed" ? "success" : "warning"
            }
            variant="outlined"
            className="!h-6 !text-[11px]"
          />
        ),
      },
      {
        header: "Action",
        align: "center",
        cell: (row) => (
          <IconButton size="small" onClick={() => setViewingPayslip(row)}>
            <Visibility fontSize="small" />
          </IconButton>
        ),
      },
    ];
  }, []);

  if (isLoading) {
    return (
      <div className="flex flex-col gap-6 pb-12 animate-pulse">
        {/* Hero Card Skeleton */}
        <div className="p-6 rounded-[5px] bg-card border border-border shadow-xs flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
          <Skeleton variant="circular" width={80} height={80} />
          <div className="flex flex-col gap-2 w-full">
            <Skeleton width="30%" height={24} />
            <Skeleton width="50%" height={20} />
            <Skeleton width="40%" height={18} />
          </div>
        </div>
        {/* Tabs Skeleton */}
        <Skeleton variant="rectangular" width="100%" height={48} />
        {/* Content Skeleton */}
        <Skeleton variant="rectangular" width="100%" height={200} />
      </div>
    );
  }

  if (!employee) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4">
        <Person className="!w-16 !h-16 text-muted-foreground/30" />
        <h3 className="text-lg font-bold text-foreground">Employee Record Not Found</h3>
        <p className="text-xs text-muted-foreground max-w-sm text-center">
          The employee ID &quot;{id}&quot; does not exist or may have been deleted.
        </p>
        <Button
          variant="contained"
          size="small"
          onClick={() => navigate("/employees")}
          startIcon={<ArrowBack className="!w-4 !h-4" />}
          className="!bg-primary !text-primary-foreground !text-xs !normal-case !rounded-[5px]"
        >
          Back to Directory
        </Button>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      {/* Hero Profile Card */}
      <div className="p-6 rounded-[5px] bg-card border border-border shadow-xs flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
        <div className="flex items-center gap-5">
          <Avatar
            src={employee.avatar || undefined}
            variant="rounded"
            className="!w-20 !h-20 !text-2xl !font-bold !bg-primary/10 !text-primary !border !border-primary/20 shrink-0"
          >
            {employee.name.charAt(0)}
          </Avatar>
          <div className="flex flex-col gap-1.5">
            <div className="flex items-center gap-2.5 flex-wrap">
              <h2 className="text-xl font-bold text-foreground tracking-tight">{employee.name}</h2>
              <Chip
                label={employee.id}
                size="small"
                className="!text-[11px] !font-mono !bg-secondary !border !border-border !text-muted-foreground !h-5"
              />
              <Chip
                icon={<CheckCircle className="!w-3 !h-3" />}
                label={employee.status}
                size="small"
                color={employee.status === "Active" ? "success" : "error"}
                variant="outlined"
              />
            </div>

            <div className="flex items-center gap-3 text-xs text-muted-foreground flex-wrap">
              <div className="flex items-center gap-1">
                <Work className="!w-3.5 !h-3.5 text-primary" />
                <span className="font-semibold text-foreground">{employee.role}</span>
              </div>
              <span>•</span>
              <div className="flex items-center gap-1">
                <Badge className="!w-3.5 !h-3.5" />
                <span>{employee.department}</span>
              </div>
              <span>•</span>
              <div className="flex items-center gap-1">
                <Schedule className="!w-3.5 !h-3.5" />
                <span>
                  {employee.shift || "General Shift"}
                  {employee.shift_time ? ` (${employee.shift_time})` : ""}
                </span>
              </div>
            </div>

            <div className="flex items-center gap-4 text-xs text-muted-foreground mt-1 flex-wrap">
              <span className="flex items-center gap-1">
                <Email className="!w-3.5 !h-3.5 text-muted-foreground/70" />
                {employee.email}
              </span>
              {employee.phone && (
                <span className="flex items-center gap-1">
                  <Phone className="!w-3.5 !h-3.5 text-muted-foreground/70" />
                  {employee.phone}
                </span>
              )}
              {employee.manager && employee.manager !== "None" && (
                <span className="flex items-center gap-1">
                  <SupervisorAccount className="!w-3.5 !h-3.5 text-muted-foreground/70" />
                  Manager: <strong className="text-foreground">{employee.manager}</strong>
                </span>
              )}
            </div>
          </div>
        </div>

        {/* Quick Monthly Earnings Widget */}
        <div className="p-4 rounded-[5px] bg-secondary/30 border border-border flex flex-col gap-1 min-w-[220px] self-stretch md:self-auto justify-center">
          <span className="text-[11px] text-muted-foreground uppercase font-semibold tracking-wider">
            Net Monthly Compensation
          </span>
          <span className="text-2xl font-black text-foreground tracking-tight">
            ₹{netSalary.toLocaleString()}
          </span>
          <div className="flex items-center justify-between text-[11px] text-muted-foreground mt-1 pt-1 border-t border-border/60">
            <span className="text-emerald-600 dark:text-emerald-400 font-medium">
              +₹{totalGross.toLocaleString()} Gross
            </span>
            <span className="text-rose-500 font-medium">
              -₹{totalDeductions.toLocaleString()} Ded.
            </span>
          </div>
        </div>
      </div>

      {/* Tabs Navigation */}
      <div className="border-b border-border">
        <Tabs
          value={activeTab}
          onChange={(_, val: DetailTab) => setActiveTab(val)}
          className="[&_.MuiTabs-indicator]:!bg-primary"
        >
          <Tab
            value="overview"
            label="Overview & Personal"
            className="!text-xs !normal-case !font-semibold !min-h-[44px]"
          />
          <Tab
            value="compensation"
            label={`Salary Structures (${(employee.salary_structures || []).length})`}
            className="!text-xs !normal-case !font-semibold !min-h-[44px]"
          />
          <Tab
            value="payroll"
            label={`Payroll History (${(employee.payrolls || []).length})`}
            className="!text-xs !normal-case !font-semibold !min-h-[44px]"
          />
          <Tab
            value="shift"
            label="Shift & Organization"
            className="!text-xs !normal-case !font-semibold !min-h-[44px]"
          />
          <Tab
            value="leaves"
            label={`Leave Balances (${(employee.leave_balances || []).length})`}
            className="!text-xs !normal-case !font-semibold !min-h-[44px]"
          />
        </Tabs>
      </div>

      {/* TAB 1: OVERVIEW */}
      {activeTab === "overview" && (
        <div className="flex flex-col gap-6">
          {/* Key Metric Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <StatsCard
              title="Total Gross Pay"
              value={`₹${totalGross.toLocaleString()}`}
              subtext={`${earningsCount} active earning items`}
              iconColor="text-emerald-600"
              iconBg="bg-emerald-500/10"
              icon={AccountBalanceWallet}
            />
            <StatsCard
              title="Total Deductions"
              value={`₹${totalDeductions.toLocaleString()}`}
              subtext={`${deductionsCount} deduction items`}
              iconColor="text-rose-500"
              iconBg="bg-rose-500/10"
              icon={AccountBalanceWallet}
            />
            <StatsCard
              title="Net Monthly Salary"
              value={`₹${netSalary.toLocaleString()}`}
              subtext="Base take-home estimate"
              iconColor="text-primary"
              iconBg="bg-primary/10"
              icon={Paid}
            />
            <StatsCard
              title="Tenure / Join Date"
              value={employee.join_date || "—"}
              subtext="Date of employment"
              iconColor="text-amber-500"
              iconBg="bg-amber-500/10"
              icon={CalendarMonth}
            />
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Personal Details Card */}
            <div className="p-5 rounded-[5px] bg-card border border-border flex flex-col gap-4">
              <h3 className="text-sm font-bold text-foreground pb-2 border-b border-border flex items-center gap-2">
                <Person className="!w-4 !h-4 text-primary" />
                Personal Information
              </h3>
              <div className="grid grid-cols-2 gap-4 text-xs">
                <div>
                  <span className="text-muted-foreground block text-[11px]">Full Name</span>
                  <span className="font-semibold text-foreground mt-0.5 block">
                    {employee.name}
                  </span>
                </div>
                <div>
                  <span className="text-muted-foreground block text-[11px]">Email Address</span>
                  <span className="font-semibold text-foreground mt-0.5 block">
                    {employee.email}
                  </span>
                </div>
                <div>
                  <span className="text-muted-foreground block text-[11px]">Phone Number</span>
                  <span className="font-semibold text-foreground mt-0.5 block">
                    {employee.phone || "Not specified"}
                  </span>
                </div>
                <div>
                  <span className="text-muted-foreground block text-[11px]">Date of Birth</span>
                  <span className="font-semibold text-foreground mt-0.5 block">
                    {employee.birth_date || "Not specified"}
                  </span>
                </div>
                <div className="col-span-2">
                  <span className="text-muted-foreground block text-[11px]">
                    Residential Address
                  </span>
                  <span className="font-semibold text-foreground mt-0.5 block flex items-start gap-1">
                    <LocationOn className="!w-3.5 !h-3.5 text-muted-foreground/60 shrink-0 mt-0.5" />
                    {employee.address || "No address on record"}
                  </span>
                </div>
              </div>
            </div>

            {/* Employment & Organizational Details */}
            <div className="p-5 rounded-[5px] bg-card border border-border flex flex-col gap-4">
              <h3 className="text-sm font-bold text-foreground pb-2 border-b border-border flex items-center gap-2">
                <Work className="!w-4 !h-4 text-primary" />
                Employment & Organizational Details
              </h3>
              <div className="grid grid-cols-2 gap-4 text-xs">
                <div>
                  <span className="text-muted-foreground block text-[11px]">Department</span>
                  <span className="font-semibold text-foreground mt-0.5 block">
                    {employee.department}
                  </span>
                </div>
                <div>
                  <span className="text-muted-foreground block text-[11px]">
                    Role / Designation
                  </span>
                  <span className="font-semibold text-foreground mt-0.5 block">
                    {employee.role}
                  </span>
                </div>
                <div>
                  <span className="text-muted-foreground block text-[11px]">Work Shift</span>
                  <span className="font-semibold text-foreground mt-0.5 block">
                    {employee.shift || "General Shift"}
                    {employee.shift_time ? ` (${employee.shift_time})` : ""}
                  </span>
                </div>
                <div>
                  <span className="text-muted-foreground block text-[11px]">Reporting Manager</span>
                  <span className="font-semibold text-foreground mt-0.5 block">
                    {employee.manager || "None Assigned"}
                  </span>
                </div>
                <div>
                  <span className="text-muted-foreground block text-[11px]">Employment Status</span>
                  <span className="font-semibold text-foreground mt-0.5 block">
                    {employee.status}
                  </span>
                </div>
                <div>
                  <span className="text-muted-foreground block text-[11px]">
                    User Account Linked
                  </span>
                  <span className="font-semibold text-foreground mt-0.5 block">
                    {employee.user ? (
                      <span className="text-emerald-600 dark:text-emerald-400 font-medium">
                        Active Account ({employee.user.email})
                      </span>
                    ) : (
                      <span className="text-muted-foreground font-normal">No User Login</span>
                    )}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB 2: COMPENSATION & SALARY STRUCTURES */}
      {activeTab === "compensation" && (
        <div className="flex flex-col gap-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-sm font-bold text-foreground">
                Assigned Salary Structures & Allowances
              </h3>
              <p className="text-xs text-muted-foreground mt-0.5">
                Itemized breakdown of fixed earnings, recurring allowances, and mandatory
                deductions.
              </p>
            </div>
            <Button
              variant="outlined"
              size="small"
              onClick={() => setIsEditDrawerOpen(true)}
              startIcon={<Edit className="!w-4 !h-4" />}
              className="!text-xs !normal-case !border-primary !text-primary hover:!bg-primary/10 font-semibold !rounded-[5px] !px-3.5 !py-1.5"
            >
              Modify Structure Items
            </Button>
          </div>

          <DataTable
            data={employee.salary_structures || []}
            columns={salaryColumns}
            hidePagination={true}
          />

          {employee.salary_structures && employee.salary_structures.length > 0 && (
            <div className="flex justify-end p-4 bg-secondary/30 border border-border rounded-md text-xs">
              <div className="w-full max-w-[280px] flex flex-col gap-2.5">
                <div className="flex justify-between items-center text-muted-foreground">
                  <span>Total Gross Pay</span>
                  <span className="font-bold text-emerald-600 dark:text-emerald-400">
                    ₹{totalGross.toLocaleString()}
                  </span>
                </div>
                <div className="flex justify-between items-center text-muted-foreground">
                  <span>Total Deductions</span>
                  <span className="font-bold text-rose-600 dark:text-rose-400">
                    -₹{totalDeductions.toLocaleString()}
                  </span>
                </div>
                <div className="border-t border-border/60 pt-1 flex justify-between items-center">
                  <span className="font-bold text-foreground text-sm">Net Monthly Pay</span>
                  <span className="font-bold text-primary text-base">
                    ₹{netSalary.toLocaleString()}
                  </span>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* TAB 3: PAYROLL & PAYSLIP HISTORY */}
      {activeTab === "payroll" && (
        <div className="flex flex-col gap-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-sm font-bold text-foreground">Payroll & Payslip History</h3>
              <p className="text-xs text-muted-foreground mt-0.5">
                Past generated salaries, disbursed payslips, and attendance-adjusted disbursements.
              </p>
            </div>
            <Button
              variant="contained"
              size="small"
              onClick={() => setIsSalaryDialogOpen(true)}
              startIcon={<Paid className="!w-4 !h-4" />}
              className="!bg-primary !text-primary-foreground hover:!bg-primary/90 !text-xs !normal-case !font-semibold !rounded-[5px] !px-3.5 !py-1.5 shadow-sm"
            >
              Generate New Salary
            </Button>
          </div>

          <DataTable
            data={employee.payrolls || []}
            columns={payrollColumns}
            hidePagination={true}
          />
        </div>
      )}

      {/* TAB 4: SHIFT & ORGANIZATION */}
      {activeTab === "shift" && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="p-5 rounded-[5px] bg-card border border-border flex flex-col gap-4">
            <h3 className="text-sm font-bold text-foreground pb-2 border-b border-border flex items-center gap-2">
              <Schedule className="!w-4 !h-4 text-primary" />
              Work Shift Configuration
            </h3>
            <div className="flex flex-col gap-3 text-xs">
              <div className="flex justify-between py-1.5 border-b border-border/60">
                <span className="text-muted-foreground">Shift Name</span>
                <span className="font-semibold text-foreground">
                  {employee.shift || "General Shift"}
                </span>
              </div>
              <div className="flex justify-between py-1.5 border-b border-border/60">
                <span className="text-muted-foreground">Operating Hours</span>
                <span className="font-semibold text-foreground">
                  {employee.shift_time || "09:00 - 18:00"}
                </span>
              </div>
              <div className="flex justify-between py-1.5 border-b border-border/60">
                <span className="text-muted-foreground">Shift Code</span>
                <span className="font-mono text-muted-foreground">
                  {employee.shift_rel?.code || "GEN"}
                </span>
              </div>
              <div className="flex justify-between py-1.5">
                <span className="text-muted-foreground">Grace Period Allowed</span>
                <span className="font-semibold text-foreground">
                  {employee.shift_rel?.grace_mins ?? 15} minutes
                </span>
              </div>
            </div>
          </div>

          <div className="p-5 rounded-[5px] bg-card border border-border flex flex-col gap-4">
            <h3 className="text-sm font-bold text-foreground pb-2 border-b border-border flex items-center gap-2">
              <SupervisorAccount className="!w-4 !h-4 text-primary" />
              Reporting Structure & Hierarchy
            </h3>
            <div className="flex flex-col gap-3 text-xs">
              <div className="flex justify-between py-1.5 border-b border-border/60">
                <span className="text-muted-foreground">Department</span>
                <span className="font-semibold text-foreground">{employee.department}</span>
              </div>
              <div className="flex justify-between py-1.5 border-b border-border/60">
                <span className="text-muted-foreground">Designation / Role</span>
                <span className="font-semibold text-foreground">{employee.role}</span>
              </div>
              <div className="flex justify-between py-1.5 border-b border-border/60">
                <span className="text-muted-foreground">Direct Supervisor</span>
                <span className="font-semibold text-foreground">{employee.manager}</span>
              </div>
              <div className="flex justify-between py-1.5">
                <span className="text-muted-foreground">Join Date</span>
                <span className="font-semibold text-foreground">{employee.join_date}</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB 5: LEAVE BALANCES */}
      {activeTab === "leaves" && (
        <div className="flex flex-col gap-4">
          <div>
            <h3 className="text-sm font-bold text-foreground">Leave Balance Summary</h3>
            <p className="text-xs text-muted-foreground mt-0.5">
              Current year ({new Date().getFullYear()}) leave allocations, utilisation and remaining
              entitlements.
            </p>
          </div>

          {!employee.leave_balances || employee.leave_balances.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 gap-3 rounded-[5px] border border-dashed border-border bg-card">
              <BeachAccess className="!w-12 !h-12 text-muted-foreground/30" />
              <span className="text-sm font-medium text-foreground">No leave balances found</span>
              <span className="text-xs text-muted-foreground text-center max-w-xs">
                Leave balances are automatically created when an employee is provisioned. Run the
                backfill script if this employee was created before the feature was added.
              </span>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
              {(employee.leave_balances as LeaveBalance[]).map((lb) => {
                const usedPct =
                  lb.allocated > 0 ? Math.min((lb.used / lb.allocated) * 100, 100) : 0;
                const accentColor = lb.leave_type?.color || "#4f46e5";
                const circumference = 2 * Math.PI * 26;

                return (
                  <div
                    key={lb.id}
                    className="p-5 rounded-[5px] bg-card border border-border flex flex-col gap-4 hover:shadow-md transition-shadow"
                  >
                    {/* Header */}
                    <div className="flex items-start justify-between gap-2">
                      <div className="flex flex-col gap-0.5">
                        <span className="text-xs font-bold text-foreground leading-tight">
                          {lb.leave_type?.name || `Leave Type #${lb.leave_type_id}`}
                        </span>
                        <span className="text-[10px] font-mono text-muted-foreground">
                          {lb.leave_type?.code || "—"}
                        </span>
                      </div>
                      <span
                        className="text-[9px] font-bold px-1.5 py-0.5 rounded border shrink-0"
                        style={{
                          backgroundColor: `${accentColor}18`,
                          color: accentColor,
                          borderColor: `${accentColor}40`,
                        }}
                      >
                        {lb.leave_type?.is_paid ? "Paid" : "Unpaid"}
                      </span>
                    </div>

                    {/* Circular ring progress */}
                    <div className="flex items-center justify-center py-1">
                      <div className="relative flex items-center justify-center w-20 h-20">
                        <svg className="absolute inset-0 -rotate-90" width="80" height="80">
                          {/* Track */}
                          <circle
                            cx="40"
                            cy="40"
                            r="26"
                            fill="none"
                            strokeWidth="6"
                            className="stroke-secondary"
                          />
                          {/* Used segment */}
                          <circle
                            cx="40"
                            cy="40"
                            r="26"
                            fill="none"
                            strokeWidth="6"
                            stroke={accentColor}
                            strokeLinecap="round"
                            strokeDasharray={`${(usedPct / 100) * circumference} ${circumference}`}
                          />
                        </svg>
                        <div className="flex flex-col items-center leading-none">
                          <span className="text-base font-black text-foreground">
                            {lb.remaining}
                          </span>
                          <span className="text-[9px] text-muted-foreground mt-0.5">left</span>
                        </div>
                      </div>
                    </div>

                    {/* Stats row */}
                    <div className="grid grid-cols-3 gap-1 pt-2 border-t border-border/60 text-center">
                      <div>
                        <span className="text-[10px] text-muted-foreground block">Allocated</span>
                        <span className="text-xs font-bold text-foreground">{lb.allocated}</span>
                      </div>
                      <div>
                        <span className="text-[10px] text-muted-foreground block">Used</span>
                        <span className="text-xs font-bold text-rose-500">{lb.used}</span>
                      </div>
                      <div>
                        <span className="text-[10px] text-muted-foreground block">Remaining</span>
                        <span className="text-xs font-bold text-emerald-600 dark:text-emerald-400">
                          {lb.remaining}
                        </span>
                      </div>
                    </div>

                    {/* Thin progress bar */}
                    <div className="w-full h-1 rounded-full bg-secondary overflow-hidden">
                      <div
                        className="h-full rounded-full transition-all duration-500"
                        style={{ width: `${usedPct}%`, backgroundColor: accentColor }}
                      />
                    </div>
                    <span className="text-[10px] text-muted-foreground -mt-2 text-right">
                      {usedPct.toFixed(0)}% utilised · Year {lb.year}
                    </span>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* Salary Generation Dialog */}
      <GenerateEmployeeSalaryDialog
        open={isSalaryDialogOpen}
        onClose={() => setIsSalaryDialogOpen(false)}
        employee={employee}
        onSuccess={() => refetchEmployee()}
      />

      {/* Edit Employee Drawer */}
      <ManageEmployee
        open={isEditDrawerOpen}
        onClose={() => setIsEditDrawerOpen(false)}
        initialData={employee as any}
        onSubmit={handleSaveEdit}
      />

      {/* Payslip View Dialog */}
      {viewingPayslip && (
        <AppDrawer
          open={Boolean(viewingPayslip)}
          onClose={() => setViewingPayslip(null)}
          title={`Payslip Details — ${viewingPayslip.id}`}
          width={600}
          footer={
            <Button
              variant="outlined"
              size="small"
              onClick={() => setViewingPayslip(null)}
              className="!border-border !text-muted-foreground hover:!text-foreground !text-xs !normal-case !rounded-[5px]"
            >
              Close
            </Button>
          }
        >
          <div className="flex flex-col gap-6 text-xs bg-background/50 rounded-md ">
            {/* Header */}
            <div className="flex justify-between items-start border-b border-border pb-4">
              <div>
                <h2 className="text-xl font-bold tracking-tight text-foreground">
                  MKX Technologies Pvt. Ltd.
                </h2>
                <p className="text-muted-foreground text-[11px] mt-1">
                  129, Block A, Street Number 13,
                </p>
                <p className="text-muted-foreground text-[11px]">
                  New Ashok Nagar, New Delhi, India - 110096
                </p>
              </div>
              <div className="text-right">
                <h3 className="text-lg font-semibold text-primary uppercase tracking-widest">
                  Payslip
                </h3>
                <p className="font-medium text-foreground mt-1">
                  For the month of {viewingPayslip.month}/{viewingPayslip.year}
                </p>
                <p className="text-muted-foreground text-[11px] mt-0.5">
                  Pay Date: {viewingPayslip.pay_date}
                </p>
                <div className="mt-2 inline-block">
                  <Chip
                    label={viewingPayslip.status}
                    size="small"
                    color="success"
                    variant="outlined"
                  />
                </div>
              </div>
            </div>

            {/* Employee Details Grid */}
            <div className="grid grid-cols-2 gap-y-3 gap-x-6 p-4 bg-secondary/20 rounded-[5px] border border-border/60">
              <div className="flex flex-col">
                <span className="text-[10px] text-muted-foreground uppercase tracking-wider">
                  Employee Name
                </span>
                <span className="font-semibold text-sm text-foreground">{employee?.name}</span>
              </div>
              <div className="flex flex-col">
                <span className="text-[10px] text-muted-foreground uppercase tracking-wider">
                  Employee ID
                </span>
                <span className="font-medium text-foreground">{employee?.id}</span>
              </div>
              <div className="flex flex-col">
                <span className="text-[10px] text-muted-foreground uppercase tracking-wider">
                  Department
                </span>
                <span className="font-medium text-foreground">{employee?.department || "N/A"}</span>
              </div>
              <div className="flex flex-col">
                <span className="text-[10px] text-muted-foreground uppercase tracking-wider">
                  Designation
                </span>
                <span className="font-medium text-foreground">{employee?.role || "N/A"}</span>
              </div>
            </div>

            {/* Earnings & Deductions Table */}
            <div className="grid grid-cols-2 gap-4">
              <div className="border border-border rounded-[5px] overflow-hidden">
                <div className="bg-secondary/40 px-3 py-2 font-semibold text-[11px] text-muted-foreground border-b border-border flex justify-between uppercase tracking-wider">
                  <span>Earnings</span>
                  <span>Amount</span>
                </div>
                <div className="divide-y divide-border/60">
                  {payslipItems.filter((i) => i.category === "Earning").length > 0 ? (
                    payslipItems
                      .filter((i) => i.category === "Earning")
                      .map((item, idx) => (
                        <div key={idx} className="px-3 py-2 flex items-center justify-between">
                          <span className="text-foreground">{item.name}</span>
                          <span className="font-medium text-emerald-600 dark:text-emerald-400">
                            ₹
                            {parseAmt(item.amount).toLocaleString(undefined, {
                              minimumFractionDigits: 2,
                              maximumFractionDigits: 2,
                            })}
                          </span>
                        </div>
                      ))
                  ) : (
                    <div className="px-3 py-4 text-center text-muted-foreground text-[11px] italic">
                      No Earnings
                    </div>
                  )}
                </div>
              </div>

              <div className="border border-border rounded-[5px] overflow-hidden">
                <div className="bg-secondary/40 px-3 py-2 font-semibold text-[11px] text-muted-foreground border-b border-border flex justify-between uppercase tracking-wider">
                  <span>Deductions</span>
                  <span>Amount</span>
                </div>
                <div className="divide-y divide-border/60">
                  {payslipItems.filter((i) => i.category === "Deduction").length > 0 ? (
                    payslipItems
                      .filter((i) => i.category === "Deduction")
                      .map((item, idx) => (
                        <div key={idx} className="px-3 py-2 flex items-center justify-between">
                          <span className="text-foreground">{item.name}</span>
                          <span className="font-medium text-rose-500">
                            ₹
                            {parseAmt(item.amount).toLocaleString(undefined, {
                              minimumFractionDigits: 2,
                              maximumFractionDigits: 2,
                            })}
                          </span>
                        </div>
                      ))
                  ) : (
                    <div className="px-3 py-4 text-center text-muted-foreground text-[11px] italic">
                      No Deductions
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Totals Summary */}
            <div className="flex justify-end border-t border-border/80">
              <div className="w-full max-w-[320px] flex flex-col gap-2.5 text-sm">
                <div className="flex justify-between items-center text-muted-foreground">
                  <span>Total Earnings (Gross Pay)</span>
                  <span className="font-semibold text-emerald-600 dark:text-emerald-400">
                    ₹
                    {parseAmt(viewingPayslip.gross_pay).toLocaleString(undefined, {
                      minimumFractionDigits: 2,
                      maximumFractionDigits: 2,
                    })}
                  </span>
                </div>
                <div className="flex justify-between items-center text-muted-foreground">
                  <span>Total Deductions</span>
                  <span className="font-semibold text-rose-600 dark:text-rose-400">
                    ₹
                    {parseAmt(viewingPayslip.total_deductions).toLocaleString(undefined, {
                      minimumFractionDigits: 2,
                      maximumFractionDigits: 2,
                    })}
                  </span>
                </div>
                <div className="border-t border-border/60 flex justify-between items-center">
                  <span className="font-bold text-foreground text-base">Net Disbursed</span>
                  <span className="font-bold text-primary text-xl">
                    ₹
                    {parseAmt(viewingPayslip.net_pay).toLocaleString(undefined, {
                      minimumFractionDigits: 2,
                      maximumFractionDigits: 2,
                    })}
                  </span>
                </div>
              </div>
            </div>

            {/* Action Buttons & Footer Notes */}
            <div className="pt-6 border-t border-border flex flex-col items-center gap-4">
              <Button
                variant="outlined"
                size="small"
                onClick={handleDownloadPdf}
                disabled={isDownloadingPdf}
                sx={{ textTransform: "none", borderRadius: "6px" }}
              >
                {isDownloadingPdf ? "Generating PDF..." : "Download PDF"}
              </Button>
              <div className="text-center text-[10px] text-muted-foreground">
                <p>
                  This is a computer generated document and does not require a physical signature.
                </p>
              </div>
            </div>
          </div>
        </AppDrawer>
      )}
    </div>
  );
}
