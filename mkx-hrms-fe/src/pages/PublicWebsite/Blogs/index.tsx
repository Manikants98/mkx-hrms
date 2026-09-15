import { Chip } from "@mui/material";
import { Search } from "lucide-react";
import { useState } from "react";
import { useGetBlogs } from "services/blogs";

export default function Blogs() {
  const [searchTerm, setSearchTerm] = useState("");
  const { data: response, isLoading } = useGetBlogs({
    status: "Published",
    search: searchTerm || undefined,
  });
  const blogs = response?.data || [];

  return (
    <div className="flex flex-col min-h-screen pt-10">
      {/* Header */}
      <section className="py-20 bg-secondary/30 relative overflow-hidden">
        <div className="absolute top-0 right-1/4 w-96 h-96 bg-chart-2 opacity-10 blur-[120px] rounded-full -z-10" />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <Chip
            label="Engineering & Culture"
            sx={{ mb: 4, bgcolor: "var(--primary)", color: "var(--primary-foreground)" }}
          />
          <h1 className="text-4xl md:text-6xl font-extrabold tracking-tight mb-6">
            Inside <span className="text-gradient">MKX</span>
          </h1>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto mb-10">
            Insights, tutorials, and stories from the team building enterprise software for the
            modern workforce.
          </p>

          <div className="max-w-xl mx-auto relative group">
            <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
              <Search className="h-5 w-5 text-muted-foreground group-focus-within:text-chart-1 transition-colors" />
            </div>
            <input
              type="text"
              className="block w-full pl-12 pr-4 py-4 rounded-full bg-background border border-border focus:border-chart-1 focus:ring-1 focus:ring-chart-1 transition-all outline-none shadow-sm"
              placeholder="Search articles..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
        </div>
      </section>

      {/* Blog Grid */}
      <section className="py-16 flex-grow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          {isLoading ? (
            <div className="flex justify-center py-20">
              <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
            </div>
          ) : blogs.length === 0 ? (
            <div className="glass-panel p-16 text-center rounded-2xl border border-dashed border-border">
              <h3 className="text-xl font-bold mb-2">No Articles Found</h3>
              <p className="text-muted-foreground">
                We couldn't find any articles matching your search.
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
              {blogs.map((blog) => (
                <div
                  key={blog.id}
                  className="glass-panel rounded-2xl hover-lift overflow-hidden h-full flex flex-col group cursor-pointer border border-transparent hover:border-border transition-all"
                >
                  {blog.cover_image ? (
                    <div className="h-56 overflow-hidden">
                      <img
                        src={blog.cover_image}
                        alt={blog.title}
                        className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
                      />
                    </div>
                  ) : (
                    <div className="h-56 bg-gradient-premium flex items-center justify-center opacity-80">
                      <span className="text-white font-bold opacity-50 text-2xl">MKX</span>
                    </div>
                  )}
                  <div className="p-6 flex-grow flex flex-col">
                    <div className="flex items-center justify-between mb-4">
                      <span className="text-xs font-semibold text-chart-2 tracking-wider uppercase bg-chart-2/10 px-2 py-1 rounded">
                        {blog.category}
                      </span>
                      <span className="text-xs text-muted-foreground">
                        {blog.published_at
                          ? new Date(blog.published_at).toLocaleDateString(undefined, {
                              month: "short",
                              day: "numeric",
                              year: "numeric",
                            })
                          : "Recently"}
                      </span>
                    </div>
                    <h3 className="text-2xl font-bold mb-3 group-hover:text-chart-2 transition-colors line-clamp-2">
                      {blog.title}
                    </h3>
                    <p className="text-muted-foreground text-sm line-clamp-3 mb-6 flex-grow leading-relaxed">
                      {blog.excerpt}
                    </p>
                    <div className="flex items-center gap-3 mt-auto pt-4 border-t border-border">
                      <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-primary-foreground text-xs font-bold">
                        {blog.author_name?.charAt(0) || "M"}
                      </div>
                      <div className="text-sm font-semibold">{blog.author_name || "MKX Team"}</div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </section>
    </div>
  );
}
