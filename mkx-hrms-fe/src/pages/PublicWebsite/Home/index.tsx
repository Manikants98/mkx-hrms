import { Button, Chip } from "@mui/material";
import { ArrowRight, Code, Rocket, Users } from "lucide-react";
import { Link } from "react-router-dom";
import { useGetBlogs } from "services/blogs";
import { useGetJobPostings } from "services/job-postings";

export default function Home() {
  const { data: jobsResponse } = useGetJobPostings();
  const { data: blogsResponse } = useGetBlogs({ status: "Published" });

  const activeJobs = jobsResponse?.data?.filter((j) => j.status === "Active").slice(0, 3) || [];
  const latestBlogs = blogsResponse?.data?.slice(0, 3) || [];

  return (
    <div className="flex flex-col min-h-screen">
      {/* Hero Section */}
      <section className="relative overflow-hidden pt-24 pb-32">
        <div className="absolute inset-0 bg-gradient-premium opacity-5 -z-10" />
        <div className="absolute top-0 right-0 w-1/2 h-1/2 bg-chart-1 opacity-10 blur-[100px] rounded-full -z-10 transform translate-x-1/3 -translate-y-1/3" />
        <div className="absolute bottom-0 left-0 w-1/2 h-1/2 bg-chart-2 opacity-10 blur-[100px] rounded-full -z-10 transform -translate-x-1/3 translate-y-1/3" />

        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center animate-slide-in-from-bottom-4">
          <Chip
            label="Welcome to the Future of Work"
            variant="outlined"
            sx={{ mb: 4, borderColor: "var(--border)", color: "var(--muted-foreground)" }}
          />
          <h1 className="text-5xl md:text-7xl font-extrabold tracking-tight mb-8">
            Empowering Teams with <br className="hidden md:block" />
            <span className="text-gradient">MKX Technologies</span>
          </h1>
          <p className="mt-4 text-xl text-muted-foreground max-w-3xl mx-auto mb-10">
            We build cutting-edge enterprise solutions that transform the way organizations manage
            their human resources, recruitment, and day-to-step operations.
          </p>
          <div className="flex justify-center gap-4">
            <Button
              component={Link}
              to="/careers"
              variant="contained"
              size="large"
              endIcon={<ArrowRight size={18} />}
              sx={{
                background: "linear-gradient(135deg, var(--chart-1), var(--chart-2))",
                borderRadius: "9999px",
                px: 4,
                py: 1.5,
                fontWeight: 600,
                textTransform: "none",
              }}
            >
              Join Our Team
            </Button>
            <Button
              component={Link}
              to="/blogs"
              variant="outlined"
              size="large"
              sx={{
                borderRadius: "9999px",
                px: 4,
                py: 1.5,
                fontWeight: 600,
                textTransform: "none",
                borderColor: "var(--border)",
                color: "var(--foreground)",
              }}
            >
              Read Our Blog
            </Button>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-24 bg-secondary/30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl font-bold mb-4">Why MKX Technologies?</h2>
            <p className="text-muted-foreground max-w-2xl mx-auto">
              We're not just building software; we're crafting experiences that elevate productivity
              and foster innovation.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {[
              {
                icon: <Rocket size={24} className="text-chart-1" />,
                title: "Innovation First",
                desc: "Pushing boundaries with AI-driven HRMS capabilities.",
              },
              {
                icon: <Code size={24} className="text-chart-2" />,
                title: "Clean Architecture",
                desc: "Enterprise-grade scalable systems built for the modern web.",
              },
              {
                icon: <Users size={24} className="text-chart-3" />,
                title: "People Centric",
                desc: "Designed with the employee experience at the forefront.",
              },
            ].map((feature, i) => (
              <div key={i} className="glass-panel p-8 rounded-2xl hover-lift">
                <div className="w-12 h-12 rounded-xl bg-background flex items-center justify-center mb-6 shadow-sm border border-border">
                  {feature.icon}
                </div>
                <h3 className="text-xl font-bold mb-3">{feature.title}</h3>
                <p className="text-muted-foreground leading-relaxed">{feature.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Latest Careers Preview */}
      <section className="py-24">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-end mb-12">
            <div>
              <h2 className="text-3xl font-bold mb-2">Open Positions</h2>
              <p className="text-muted-foreground">Come build the future with us.</p>
            </div>
            <Button
              component={Link}
              to="/careers"
              endIcon={<ArrowRight size={16} />}
              sx={{ textTransform: "none", fontWeight: 600 }}
            >
              View All Jobs
            </Button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {activeJobs.map((job) => (
              <Link key={job.id} to="/careers" className="block">
                <div className="glass-panel p-6 rounded-xl hover-lift h-full flex flex-col cursor-pointer">
                  <div className="flex justify-between items-start mb-4">
                    <Chip
                      label={job.department_rel?.name || "General"}
                      size="small"
                      sx={{ bgcolor: "var(--primary)", color: "var(--primary-foreground)" }}
                    />
                    <span className="text-xs font-semibold px-2 py-1 bg-secondary rounded-full text-secondary-foreground">
                      {job.employment_type}
                    </span>
                  </div>
                  <h3 className="text-lg font-bold mb-2 line-clamp-2">{job.title}</h3>
                  <div className="mt-auto pt-4 flex justify-between items-center text-sm text-muted-foreground border-t border-border">
                    <span>{job.location}</span>
                    <span>{job.experience_level}</span>
                  </div>
                </div>
              </Link>
            ))}
            {activeJobs.length === 0 && (
              <div className="col-span-3 text-center py-12 text-muted-foreground border border-dashed border-border rounded-xl">
                No open positions at the moment. Check back later!
              </div>
            )}
          </div>
        </div>
      </section>

      {/* Latest Blogs Preview */}
      <section className="py-24 bg-secondary/30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-end mb-12">
            <div>
              <h2 className="text-3xl font-bold mb-2">Latest Insights</h2>
              <p className="text-muted-foreground">
                Read about our engineering journey and culture.
              </p>
            </div>
            <Button
              component={Link}
              to="/blogs"
              endIcon={<ArrowRight size={16} />}
              sx={{ textTransform: "none", fontWeight: 600 }}
            >
              View All Posts
            </Button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {latestBlogs.map((blog) => (
              <Link key={blog.id} to="/blogs" className="block group">
                <div className="glass-panel rounded-2xl hover-lift overflow-hidden h-full flex flex-col">
                  {blog.cover_image ? (
                    <div className="h-48 overflow-hidden">
                      <img
                        src={blog.cover_image}
                        alt={blog.title}
                        className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                      />
                    </div>
                  ) : (
                    <div className="h-48 bg-gradient-premium flex items-center justify-center opacity-80">
                      <span className="text-white font-bold opacity-50">MKX</span>
                    </div>
                  )}
                  <div className="p-6 flex-grow flex flex-col">
                    <div className="flex gap-2 mb-3">
                      <span className="text-xs font-semibold text-chart-1 tracking-wider uppercase">
                        {blog.category}
                      </span>
                    </div>
                    <h3 className="text-xl font-bold mb-3 group-hover:text-chart-1 transition-colors line-clamp-2">
                      {blog.title}
                    </h3>
                    <p className="text-muted-foreground text-sm line-clamp-3 mb-4 flex-grow">
                      {blog.excerpt}
                    </p>
                    <div className="flex items-center gap-3 mt-auto pt-4 border-t border-border">
                      <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-primary-foreground text-xs font-bold">
                        {blog.author_name?.charAt(0) || "M"}
                      </div>
                      <div className="text-sm">
                        <p className="font-semibold">{blog.author_name || "MKX Team"}</p>
                        <p className="text-muted-foreground text-xs">
                          {blog.published_at
                            ? new Date(blog.published_at).toLocaleDateString()
                            : "Recent"}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </Link>
            ))}
            {latestBlogs.length === 0 && (
              <div className="col-span-3 text-center py-12 text-muted-foreground border border-dashed border-border rounded-xl">
                No articles published yet.
              </div>
            )}
          </div>
        </div>
      </section>
    </div>
  );
}
