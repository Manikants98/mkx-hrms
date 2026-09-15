import { LineChart } from "@mui/x-charts/LineChart";
import type { WorkforceTrendPoint } from "services/dashboard";

/**
 * Props for the WorkforceChart component
 */
interface WorkforceChartProps {
  /** Array of real monthly workforce data points from the API */
  data: WorkforceTrendPoint[];
  /** Whether the data is still loading */
  isLoading?: boolean;
}

/**
 * Area chart displaying real monthly workforce headcount for the current year
 *
 * @param props - Component props
 * @returns Rendered workforce growth trend chart
 */
export function WorkforceChart({ data, isLoading }: WorkforceChartProps) {
  return (
    <div className="bg-card border border-border rounded-xl p-5 h-[380px] animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h3 className="text-base font-semibold text-foreground">Workforce Growth Trend</h3>
          <p className="text-sm text-muted-foreground mt-0.5">Monthly active employees this year</p>
        </div>
        <div className="flex items-center gap-4 text-xs">
          <div className="flex items-center gap-1.5">
            <div className="w-2.5 h-2.5 rounded-full bg-chart-1"></div>
            <span className="text-muted-foreground">Employees</span>
          </div>
        </div>
      </div>

      <div className="h-[280px]">
        {isLoading ? (
          <div className="flex flex-col gap-4 py-8">
            <div className="h-4 bg-muted animate-pulse rounded" />
            <div className="h-4 bg-muted animate-pulse rounded w-3/4" />
            <div className="h-4 bg-muted animate-pulse rounded w-1/2" />
          </div>
        ) : data.length === 0 ? (
          <div className="flex items-center justify-center h-full text-muted-foreground text-sm">
            No workforce data available yet
          </div>
        ) : (
          <div className="w-full h-full relative">
            <LineChart
              dataset={data as any}
              xAxis={[
                {
                  scaleType: "point",
                  dataKey: "name",
                  tickLabelStyle: { fontSize: 12, fill: "var(--muted-foreground)" },
                },
              ]}
              yAxis={[
                {
                  tickLabelStyle: { fontSize: 12, fill: "var(--muted-foreground)" },
                },
              ]}
              series={[
                {
                  dataKey: "employees",
                  area: true,
                  color: "var(--chart-1)",
                  showMark: false,
                },
              ]}
              margin={{ top: 10, right: 10, bottom: 20, left: 0 }}
              grid={{ horizontal: true }}
              sx={{
                "& .MuiAreaElement-root": {
                  fill: "url(#colorEmployees)",
                },
                "& .MuiChartsGrid-line": {
                  strokeDasharray: "3 3",
                  stroke: "var(--border)",
                  opacity: 0.5,
                },
                "& .MuiChartsAxis-line, & .MuiChartsAxis-tick": {
                  display: "none",
                },
              }}
            >
              <defs>
                <linearGradient id="colorEmployees" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="var(--chart-1)" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="var(--chart-1)" stopOpacity={0} />
                </linearGradient>
              </defs>
            </LineChart>
          </div>
        )}
      </div>
    </div>
  );
}
