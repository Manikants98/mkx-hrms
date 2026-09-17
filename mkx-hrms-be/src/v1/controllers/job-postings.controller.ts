import type { Request, Response } from "express";
import { prisma } from "../../libraries/prisma";

/**
 * Generates a unique Job Posting Code (JP-XXX)
 */
async function generateJobCode(): Promise<string> {
  const lastPosting = await prisma.jobPosting.findFirst({
    orderBy: { id: "desc" },
  });

  if (!lastPosting || !lastPosting.job_code) {
    return "JP-001";
  }

  const match = lastPosting.job_code.match(/JP-(\d+)/);
  if (!match) return "JP-001";

  const nextNum = parseInt(match[1], 10) + 1;
  return `JP-${nextNum.toString().padStart(3, "0")}`;
}

export const getJobPostings = async (req: Request, res: Response) => {
  try {
    const jobPostings = await prisma.jobPosting.findMany({
      orderBy: { created_at: "desc" },
      include: {
        department_rel: true,
        _count: {
          select: { candidates: true },
        },
      },
    });
    res.json({ data: jobPostings });
  } catch (error) {
    console.error("Error fetching job postings:", error);
    res.status(500).json({ error: "Failed to fetch job postings" });
  }
};

export const getJobPostingById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const jobPosting = await prisma.jobPosting.findUnique({
      where: { id: Number(id) },
      include: {
        department_rel: true,
        candidates: true,
      },
    });

    if (!jobPosting) {
      return res.status(404).json({ error: "Job posting not found" });
    }

    res.json({ data: jobPosting });
  } catch (error) {
    console.error("Error fetching job posting:", error);
    res.status(500).json({ error: "Failed to fetch job posting" });
  }
};

export const createJobPosting = async (req: Request, res: Response) => {
  try {
    const {
      title,
      department_id,
      location,
      employment_type,
      experience_level,
      salary_range,
      description,
      vacancies,
      status,
      role_id,
      shift_id,
    } = req.body;

    const job_code = await generateJobCode();

    const jobPosting = await prisma.jobPosting.create({
      data: {
        job_code,
        title,
        department_id: department_id ? Number(department_id) : undefined,
        location,
        employment_type,
        experience_level,
        salary_range,
        description,
        vacancies: vacancies ? Number(vacancies) : 1,
        status: status || "Active",
        role_id: role_id ? Number(role_id) : null,
        shift_id: shift_id ? Number(shift_id) : null,
      },
    });

    res.status(201).json({
      message: "Job posting created successfully",
      data: jobPosting,
    });
  } catch (error) {
    console.error("Error creating job posting:", error);
    res.status(500).json({ error: "Failed to create job posting" });
  }
};

export const updateJobPosting = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const {
      title,
      department_id,
      location,
      employment_type,
      experience_level,
      salary_range,
      description,
      vacancies,
      status,
      role_id,
      shift_id,
    } = req.body;

    const jobPosting = await prisma.jobPosting.update({
      where: { id: Number(id) },
      data: {
        title,
        department_id: department_id ? Number(department_id) : undefined,
        location,
        employment_type,
        experience_level,
        salary_range,
        description,
        vacancies: vacancies ? Number(vacancies) : undefined,
        status,
        role_id: role_id ? Number(role_id) : null,
        shift_id: shift_id ? Number(shift_id) : null,
      },
    });

    res.json({
      message: "Job posting updated successfully",
      data: jobPosting,
    });
  } catch (error) {
    console.error("Error updating job posting:", error);
    res.status(500).json({ error: "Failed to update job posting" });
  }
};

export const deleteJobPosting = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    // Check if there are candidates tied to this job posting
    const count = await prisma.candidate.count({
      where: { job_posting_id: Number(id) },
    });

    if (count > 0) {
      return res.status(400).json({
        error: "Cannot delete job posting with attached candidates. Mark it as Closed instead.",
      });
    }

    await prisma.jobPosting.delete({
      where: { id: Number(id) },
    });

    res.json({ message: "Job posting deleted successfully" });
  } catch (error) {
    console.error("Error deleting job posting:", error);
    res.status(500).json({ error: "Failed to delete job posting" });
  }
};
