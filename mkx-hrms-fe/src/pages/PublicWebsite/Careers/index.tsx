import { useState } from "react";
import { Button, Chip } from "@mui/material";
import { ArrowRight, Briefcase, Clock, MapPin } from "lucide-react";
import { useGetJobPostings } from "services/job-postings";
import { ApplyJobModal } from "../components/ApplyJobModal";

export default function Careers() {
  const { data: response, isLoading } = useGetJobPostings();
  const jobs = response?.data?.filter((j) => j.status === "Active") || [];
  const [selectedJob, setSelectedJob] = useState<any>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  return (
    <div className="flex flex-col min-h-screen pt-10">
      {/* Header */}
      <section className="py-20 bg-secondary/30 relative overflow-hidden">
        <div className="absolute top-0 left-1/2 w-full h-full bg-chart-1 opacity-5 blur-[120px] rounded-full -z-10 transform -translate-x-1/2" />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <Chip
            label="Join the Team"
            sx={{ mb: 4, bgcolor: "var(--primary)", color: "var(--primary-foreground)" }}
          />
          <h1 className="text-4xl md:text-6xl font-extrabold tracking-tight mb-6">
            Build the <span className="text-gradient">Future</span> With Us
          </h1>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            Discover opportunities to push boundaries, innovate, and grow your career at MKX
            Technologies.
          </p>
        </div>
      </section>

      {/* Jobs List */}
      <section className="py-16 flex-grow">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="mb-10 flex items-center justify-between border-b border-border pb-6">
            <h2 className="text-2xl font-bold">Open Positions ({jobs.length})</h2>
          </div>

          {isLoading ? (
            <div className="flex justify-center py-20">
              <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
            </div>
          ) : jobs.length === 0 ? (
            <div className="glass-panel p-16 text-center rounded-2xl border border-dashed border-border">
              <Briefcase size={48} className="mx-auto mb-4 text-muted-foreground opacity-50" />
              <h3 className="text-xl font-bold mb-2">No Open Roles Right Now</h3>
              <p className="text-muted-foreground">
                We are not actively hiring at this moment. Please check back later.
              </p>
            </div>
          ) : (
            <div className="flex flex-col gap-6">
              {jobs.map((job) => (
                <div
                  key={job.id}
                  className="glass-panel p-6 sm:p-8 rounded-2xl hover-lift group cursor-pointer transition-all border border-transparent hover:border-border"
                >
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-6">
                    <div>
                      <div className="flex items-center gap-3 mb-3">
                        <Chip
                          label={job.department_rel?.name || "General"}
                          size="small"
                          variant="outlined"
                        />
                        <span className="text-sm font-semibold text-chart-1">{job.job_code}</span>
                      </div>
                      <h3 className="text-2xl font-bold mb-4 group-hover:text-chart-1 transition-colors">
                        {job.title}
                      </h3>
                      <div className="flex flex-wrap gap-4 text-sm text-muted-foreground">
                        <div className="flex items-center gap-1.5">
                          <MapPin size={16} />
                          <span>{job.location}</span>
                        </div>
                        <div className="flex items-center gap-1.5">
                          <Clock size={16} />
                          <span>{job.employment_type}</span>
                        </div>
                        <div className="flex items-center gap-1.5">
                          <Briefcase size={16} />
                          <span>{job.experience_level}</span>
                        </div>
                      </div>
                    </div>
                    <div className="sm:text-right flex flex-col sm:items-end justify-center">
                      <Button
                        variant="contained"
                        endIcon={<ArrowRight size={16} />}
                        onClick={() => {
                          setSelectedJob(job);
                          setIsModalOpen(true);
                        }}
                        sx={{
                          borderRadius: "9999px",
                          textTransform: "none",
                          fontWeight: 600,
                          bgcolor: "var(--primary)",
                          color: "var(--primary-foreground)",
                          "&:hover": { bgcolor: "var(--chart-1)" },
                        }}
                      >
                        Apply Now
                      </Button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </section>

      <ApplyJobModal
        open={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        job={selectedJob}
      />
    </div>
  );
}
