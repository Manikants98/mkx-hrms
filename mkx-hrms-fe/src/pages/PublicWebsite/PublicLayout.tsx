import React, { useState } from "react";
import { Link, Outlet } from "react-router-dom";
import { Button } from "@mui/material";
import { ContactUsModal } from "./components/ContactUsModal";

export const PublicLayout: React.FC = () => {
  const [isContactOpen, setIsContactOpen] = useState(false);

  return (
    <div className="min-h-screen bg-background text-foreground font-sans flex flex-col">
      {/* Navbar */}
      <header className="sticky top-0 z-50 glass-panel border-b border-border">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-20">
            {/* Logo */}
            <div className="flex-shrink-0 flex items-center gap-2">
              <div className="w-8 h-8 rounded bg-gradient-premium flex items-center justify-center text-white font-bold text-xl">
                M
              </div>
              <Link to="/" className="font-bold text-2xl tracking-tight">
                MKX <span className="text-gradient">Technologies</span>
              </Link>
            </div>

            {/* Desktop Navigation */}
            <nav className="hidden md:flex space-x-8">
              <Link
                to="/"
                className="text-muted-foreground hover:text-foreground transition-colors font-medium"
              >
                Home
              </Link>
              <Link
                to="/careers"
                className="text-muted-foreground hover:text-foreground transition-colors font-medium"
              >
                Careers
              </Link>
              <Link
                to="/blogs"
                className="text-muted-foreground hover:text-foreground transition-colors font-medium"
              >
                Blogs
              </Link>
            </nav>

            {/* Actions */}
            <div className="flex items-center space-x-4">
              <Button
                onClick={() => setIsContactOpen(true)}
                variant="contained"
                sx={{
                  borderRadius: "9999px",
                  textTransform: "none",
                  fontWeight: 600,
                  px: 4,
                  py: 1,
                  background: "linear-gradient(135deg, var(--chart-1), var(--chart-2))",
                  color: "white",
                }}
              >
                Contact Us
              </Button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-grow">
        <Outlet />
      </main>

      {/* Footer */}
      <footer className="glass-panel border-t border-border mt-auto py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div>
              <div className="flex items-center gap-2 mb-4">
                <div className="w-6 h-6 rounded bg-gradient-premium flex items-center justify-center text-white font-bold text-sm">
                  M
                </div>
                <span className="font-bold text-xl tracking-tight">MKX Technologies</span>
              </div>
              <p className="text-muted-foreground">
                Innovating the future of enterprise solutions and human resource management.
              </p>
            </div>
            <div>
              <h4 className="font-semibold mb-4">Quick Links</h4>
              <ul className="space-y-2">
                <li>
                  <Link to="/" className="text-muted-foreground hover:text-foreground">
                    Home
                  </Link>
                </li>
                <li>
                  <Link to="/careers" className="text-muted-foreground hover:text-foreground">
                    Careers
                  </Link>
                </li>
                <li>
                  <Link to="/blogs" className="text-muted-foreground hover:text-foreground">
                    Blogs
                  </Link>
                </li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold mb-4">Connect</h4>
              <ul className="space-y-2">
                <li>
                  <a href="#" className="text-muted-foreground hover:text-foreground">
                    Twitter
                  </a>
                </li>
                <li>
                  <a href="#" className="text-muted-foreground hover:text-foreground">
                    LinkedIn
                  </a>
                </li>
                <li>
                  <a href="#" className="text-muted-foreground hover:text-foreground">
                    GitHub
                  </a>
                </li>
              </ul>
            </div>
          </div>
          <div className="border-t border-border mt-12 pt-8 text-center text-muted-foreground">
            <p>&copy; {new Date().getFullYear()} MKX Technologies. All rights reserved.</p>
          </div>
        </div>
      </footer>
      <ContactUsModal open={isContactOpen} onClose={() => setIsContactOpen(false)} />
    </div>
  );
};
