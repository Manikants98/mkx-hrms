import { ArrowBack, Badge, Email, EventNote, Person, Star, Work } from "@mui/icons-material";
import { Avatar, Button, Chip, Skeleton, Tab, Tabs } from "@mui/material";
import dayjs from "dayjs";
import React, { useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useGetCandidateById, useUpdateCandidateStatus } from "services/recruitment";

type CandidateDetailTab = "overview" | "interviews";

/**
 * Formats a date string to a readable format
 * @param {unknown} date - The date to format
 * @returns {string} The formatted date string
 */
const formatDate = (date: unknown): string => {
  if (!date) return "N/A";
  return dayjs(date as string).format("DD MMMM YYYY");
};

export default function CandidateDetail(): React.ReactElement {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState<CandidateDetailTab>("overview");

  const { data: candidateResponse, isLoading } = useGetCandidateById(id || "");
  const candidate = candidateResponse?.data;

  const updateStatus = useUpdateCandidateStatus();

  const handleStageUpdate = (stage: any, status: any) => {
    if (!candidate) return;
    updateStatus.mutate({ id: String(candidate.db_id || candidate.id), stage, status });
  };

  if (isLoading) {
    return (
      <div className="space-y-6 max-w-[1600px] mx-auto pb-10">
        <div className="flex items-center gap-3">
          <Skeleton variant="circular" width={40} height={40} />
          <div className="flex flex-col gap-2">
            <Skeleton variant="text" width={200} height={30} />
            <Skeleton variant="text" width={300} height={20} />
          </div>
        </div>
      </div>
    );
  }

  if (!candidate) {
    return (
      <div className="flex flex-col items-center justify-center py-20 text-center">
        <h2 className="text-xl font-semibold mb-2">Candidate Not Found</h2>
        <p className="text-muted-foreground mb-4">
          The candidate you are looking for does not exist or has been removed.
        </p>
        <Button
          variant="contained"
          onClick={() => navigate("/candidates")}
          startIcon={<ArrowBack />}
        >
          Back to Candidates
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-[1600px] mx-auto pb-10">
      <div className="flex flex-col md:flex-row md:items-start justify-between gap-4 bg-card/40 border border-border p-5 rounded-[8px]">
        <div className="flex items-start gap-4">
          <Avatar
            src={candidate.avatar || undefined}
            className="!w-16 !h-16 !bg-primary/20 !text-primary !text-2xl !font-bold"
          >
            {candidate.name.charAt(0)}
          </Avatar>

          <div className="flex flex-col gap-1">
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-bold text-foreground">{candidate.name}</h1>
              <Chip
                label={candidate.stage}
                size="small"
                className="!bg-primary/10 !text-primary !font-semibold !text-xs"
              />
              <Chip
                label={candidate.status}
                size="small"
                color={
                  candidate.status === "Offered" || candidate.status === "Active"
                    ? "success"
                    : candidate.status === "In Review"
                      ? "warning"
                      : "error"
                }
                className="!font-medium !text-xs"
              />
            </div>

            <p className="text-sm font-medium text-muted-foreground flex items-center gap-1.5 mt-1">
              <Badge className="!w-4 !h-4 text-primary" />
              {candidate.position} • {candidate.department}
            </p>
            <p className="text-xs text-muted-foreground mt-1">
              Applied on {formatDate(candidate.applied_date)}
            </p>
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-2 md:ml-auto">
          {candidate.stage !== "Offered" && candidate.stage !== "Hired" && (
            <Button
              variant="outlined"
              color="success"
              className="!text-xs !font-semibold !normal-case shadow-sm"
              onClick={() => handleStageUpdate("Offered", "Offered")}
            >
              Extend Offer
            </Button>
          )}
          {candidate.status !== "Rejected" && (
            <Button
              variant="outlined"
              color="error"
              className="!text-xs !font-semibold !normal-case shadow-sm"
              onClick={() => handleStageUpdate(candidate.stage, "Rejected")}
            >
              Reject Candidate
            </Button>
          )}
        </div>
      </div>

      <div className="border-b border-border mt-4">
        <Tabs
          value={activeTab}
          onChange={(_, newVal) => setActiveTab(newVal)}
          className="min-h-0 [&_.MuiTab-root]:min-h-0 [&_.MuiTab-root]:py-2.5"
          indicatorColor="primary"
        >
          <Tab
            value="overview"
            label="Overview"
            className="!text-sm !font-semibold !normal-case data-[state=active]:!text-primary"
          />
          <Tab
            value="interviews"
            label="Interviews"
            className="!text-sm !font-semibold !normal-case data-[state=active]:!text-primary"
          />
        </Tabs>
      </div>

      {activeTab === "overview" && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-6">
            <div className="bg-card/40 border border-border p-5 rounded-[8px]">
              <h3 className="text-sm font-semibold mb-4 text-foreground flex items-center gap-2">
                <Person className="text-primary !w-4 !h-4" /> Professional Profile
              </h3>

              <div className="grid grid-cols-2 gap-y-5 gap-x-8">
                <div className="flex flex-col gap-1.5">
                  <span className="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">
                    Experience
                  </span>
                  <span className="text-sm text-foreground">{candidate.experience}</span>
                </div>
                <div className="flex flex-col gap-1.5">
                  <span className="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">
                    Overall Rating
                  </span>
                  <span className="text-sm font-medium text-amber-500 flex items-center gap-1">
                    <Star className="!w-4 !h-4" /> {candidate.rating} / 5.0
                  </span>
                </div>
              </div>
            </div>

            {candidate.job_posting && (
              <div className="bg-card/40 border border-border p-5 rounded-[8px]">
                <h3 className="text-sm font-semibold mb-4 text-foreground flex items-center gap-2">
                  <Work className="text-primary !w-4 !h-4" /> Applied Job Posting
                </h3>

                <div className="flex flex-col gap-3">
                  <h4 className="font-semibold text-foreground">{candidate.job_posting.title}</h4>
                  <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mt-2">
                    <div className="flex flex-col gap-1.5">
                      <span className="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">
                        Location
                      </span>
                      <span className="text-sm text-foreground">
                        {candidate.job_posting.location}
                      </span>
                    </div>
                    <div className="flex flex-col gap-1.5">
                      <span className="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">
                        Type
                      </span>
                      <span className="text-sm text-foreground">
                        {candidate.job_posting.employment_type}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>

          <div className="space-y-6">
            <div className="bg-card/40 border border-border p-5 rounded-[8px]">
              <h3 className="text-sm font-semibold mb-4 text-foreground flex items-center gap-2">
                <Email className="text-primary !w-4 !h-4" /> Contact Information
              </h3>
              <div className="space-y-4">
                <div className="flex items-start gap-3">
                  <Email className="text-muted-foreground !w-4 !h-4 mt-0.5" />
                  <div className="flex flex-col">
                    <span className="text-xs text-muted-foreground">Email Address</span>
                    <span className="text-sm text-foreground mt-0.5">{candidate.email}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {activeTab === "interviews" && (
        <div className="bg-card/40 border border-border p-5 rounded-[8px]">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-sm font-semibold text-foreground flex items-center gap-2">
              <EventNote className="text-primary !w-4 !h-4" /> Interview Timeline
            </h3>
            <Button
              variant="contained"
              size="small"
              className="!text-xs !bg-primary !text-primary-foreground !normal-case"
            >
              Schedule Interview
            </Button>
          </div>

          {!candidate.interviews || candidate.interviews.length === 0 ? (
            <div className="text-center py-10 bg-secondary/30 rounded-[8px]">
              <EventNote className="mx-auto !w-10 !h-10 text-muted-foreground/50 mb-3" />
              <h4 className="text-sm font-medium text-foreground">No Interviews Scheduled</h4>
              <p className="text-xs text-muted-foreground mt-1">
                Schedule the first interview for this candidate
              </p>
            </div>
          ) : (
            <div className="space-y-4">
              {candidate.interviews.map((interview: any) => (
                <div
                  key={interview.id}
                  className="border border-border p-4 rounded-[8px] bg-background"
                >
                  <div className="flex justify-between items-start">
                    <div>
                      <h4 className="font-semibold text-sm">Interview</h4>
                      <p className="text-xs text-muted-foreground mt-1">
                        {new Date(interview.scheduled_at).toLocaleString()}
                      </p>
                    </div>
                    <Chip size="small" label={interview.status} className="!text-[11px]" />
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
