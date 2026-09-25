import {
  DoneAll,
  Logout,
  NotificationsNone,
  Person,
  CardGiftcard,
  Settings as SettingsIcon,
} from "@mui/icons-material";
import {
  Avatar,
  Badge,
  Button,
  Chip,
  CircularProgress,
  Divider,
  IconButton,
  ListItemIcon,
  MenuItem,
} from "@mui/material";
import { useTheme } from "context/ThemeContext/useTheme";
import { useAuth } from "contexts/AuthContext";
import { Moon, Sun } from "lucide-react";
import { useQueryClient } from "@tanstack/react-query";
import { useState, type MouseEvent } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { ArrowMenu } from "../ArrowMenu";
import { FontSwitcherModal } from "../FontSwitcherModal";
import {
  useGetNotifications,
  useMarkNotificationRead,
  useMarkAllNotificationsRead,
  type AppNotification,
} from "services/dashboard";

/**
 * Formats an ISO date string into a relative time label
 *
 * @param dateStr - ISO date string to format
 * @returns Human-readable relative time string
 */
const formatRelativeTime = (dateStr: string): string => {
  const diff = Math.floor((Date.now() - new Date(dateStr).getTime()) / 1000);
  if (diff < 60) return "Just now";
  if (diff < 3600) return `${Math.floor(diff / 60)} min ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)} hr ago`;
  return `${Math.floor(diff / 86400)}d ago`;
};

/**
 * Standard Header component with interactive Date Filter, Theme Toggle, Notification Popover, and Profile Menu.
 */
export function Header() {
  const { theme, setTheme } = useTheme();
  const { user, logout } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const [notificationAnchorEl, setNotificationAnchorEl] = useState<HTMLElement | null>(null);
  const [fontModalOpen, setFontModalOpen] = useState(false);
  const [profileAnchorEl, setProfileAnchorEl] = useState<HTMLElement | null>(null);

  const { data: notifData, isLoading: notifLoading } = useGetNotifications();
  const { mutate: markRead } = useMarkNotificationRead();
  const { mutate: markAllRead } = useMarkAllNotificationsRead();

  const notifications = notifData?.data?.notifications ?? [];
  const unreadCount = notifData?.data?.unread_count ?? 0;

  const isDark =
    theme === "dark" || (theme === "system" && document.documentElement.classList.contains("dark"));

  const toggleTheme = () => {
    setTheme(isDark ? "light" : "dark");
  };

  /**
   * Mark a notification as read and refresh the list
   */
  const handleMarkRead = (n: AppNotification) => {
    if (n.is_read) return;
    markRead(n.id);
    queryClient.invalidateQueries({ queryKey: ["notifications"] });
  };

  /**
   * Mark all notifications as read and refresh the list
   */
  const handleMarkAllRead = () => {
    markAllRead();
    queryClient.invalidateQueries({ queryKey: ["notifications"] });
  };

  /**
   * Determine the page title from current URL pathname
   */
  const getPageTitle = (): string => {
    if (location.pathname.startsWith("/employees")) return "Employees";
    if (location.pathname.startsWith("/reports")) return "Reports";
    if (location.pathname.startsWith("/settings")) return "Settings";
    if (location.pathname.startsWith("/attendance")) return "Attendance";
    if (location.pathname.startsWith("/leaves")) return "Leaves";
    if (location.pathname.startsWith("/recruitment")) return "Recruitment";
    if (location.pathname.startsWith("/payroll")) return "Payroll";
    return "Dashboard";
  };

  return (
    <header className="h-16 border-b border-border bg-background/80 backdrop-blur-sm sticky top-0 z-30 flex items-center justify-between px-6">
      <div className="flex items-center gap-6">
        <h1 className="text-xl font-semibold text-foreground">{getPageTitle()}</h1>
      </div>

      <div className="flex items-center gap-3">
        {/* Dynamic Notifications Popover Menu */}
        <IconButton
          onClick={(e: MouseEvent<HTMLButtonElement>) => setNotificationAnchorEl(e.currentTarget)}
          aria-label="View notifications"
        >
          <Badge
            color="primary"
            variant={unreadCount > 0 ? "dot" : "standard"}
            className="[&_.MuiBadge-badge]:animate-pulse"
          >
            <NotificationsNone className="!w-5 !h-5" />
          </Badge>
        </IconButton>

        <ArrowMenu
          anchorEl={notificationAnchorEl}
          open={Boolean(notificationAnchorEl)}
          onClose={() => setNotificationAnchorEl(null)}
          arrowPosition="right"
          paperClassName="!w-[360px] sm:!w-[380px] !p-0"
        >
          <div className="px-4 pt-1 pb-3 border-b border-border flex items-center justify-between bg-card relative z-10 rounded-t-[5px]">
            <div className="flex items-center gap-2">
              <span className="text-sm font-semibold text-foreground">Notifications</span>
              {unreadCount > 0 && (
                <Chip
                  label={`${unreadCount} New`}
                  size="small"
                  className="!h-5 !text-[10px] !bg-primary/10 !text-primary !font-semibold"
                />
              )}
            </div>
            {unreadCount > 0 && (
              <Button
                size="small"
                variant="text"
                startIcon={<DoneAll className="!w-3.5 !h-3.5" />}
                onClick={handleMarkAllRead}
                className="!text-[11px] !normal-case !text-muted-foreground hover:!text-foreground !p-0 !min-w-0"
              >
                Mark all read
              </Button>
            )}
          </div>

          <div className="max-h-[340px] overflow-y-auto custom-scrollbar divide-y divide-border/40 p-1">
            {notifLoading ? (
              <div className="py-8 flex justify-center">
                <CircularProgress size={24} />
              </div>
            ) : notifications.length === 0 ? (
              <div className="py-8 text-center text-xs text-muted-foreground">
                No notifications at this time
              </div>
            ) : (
              notifications.map((n) => (
                <div
                  key={n.id}
                  onClick={() => handleMarkRead(n)}
                  className={`p-3 rounded-[5px] transition-colors cursor-pointer flex gap-3 ${
                    !n.is_read
                      ? "bg-secondary/40 hover:bg-secondary/70"
                      : "hover:bg-secondary/30 opacity-75 hover:opacity-100"
                  }`}
                >
                  <div className="mt-0.5">
                    <CardGiftcard className="!w-4 !h-4 !text-amber-500" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-1">
                      <p
                        className={`text-xs ${
                          !n.is_read
                            ? "font-semibold text-foreground"
                            : "font-medium text-muted-foreground"
                        }`}
                      >
                        {n.title}
                      </p>
                      <span className="text-[10px] text-muted-foreground whitespace-nowrap">
                        {formatRelativeTime(n.created_at)}
                      </span>
                    </div>
                    {n.sender_name && (
                      <p className="text-[10px] text-primary/70 font-medium mt-0.5">
                        From: {n.sender_name}
                      </p>
                    )}
                    <p className="text-[11px] text-muted-foreground line-clamp-2 mt-0.5">
                      {n.message}
                    </p>
                  </div>
                  {!n.is_read && (
                    <div className="w-1.5 h-1.5 rounded-full bg-primary mt-1.5 shrink-0" />
                  )}
                </div>
              ))
            )}
          </div>

          <div className="px-4 pb-1 pt-3 border-t border-border bg-card/50 flex items-center justify-between">
            <Button
              size="small"
              variant="text"
              onClick={() => {
                setNotificationAnchorEl(null);
                navigate("/settings");
              }}
              className="!text-xs !normal-case !text-muted-foreground hover:!text-foreground !w-full"
            >
              Notification Preferences
            </Button>
          </div>
        </ArrowMenu>

        {/* Dynamic User Profile Menu */}
        <IconButton
          onClick={(e: MouseEvent<HTMLButtonElement>) => setProfileAnchorEl(e.currentTarget)}
          aria-label="User account menu"
          className="!p-1 !rounded-[5px] ring-2 ring-transparent"
        >
          <Avatar
            variant="rounded"
            src={user?.avatar || undefined}
            className="!w-9 !h-9 !bg-chart-1 !text-black !text-xs !font-semibold cursor-pointer"
          >
            {user ? `${user.first_name[0] || ""}${user.last_name[0] || ""}` : "MK"}
          </Avatar>
        </IconButton>

        <ArrowMenu
          anchorEl={profileAnchorEl}
          open={Boolean(profileAnchorEl)}
          onClose={() => setProfileAnchorEl(null)}
          arrowPosition="right"
          paperClassName="!w-60 !px-1"
        >
          <div className="px-2 pb-1.5 pt-0.5 flex items-center gap-3 border-b border-border/50 mb-1 relative z-10">
            <Avatar
              variant="rounded"
              src={user?.avatar || undefined}
              className="!w-8 !h-8 !bg-chart-1 !text-black !text-xs !font-semibold"
            >
              {user ? `${user.first_name[0] || ""}${user.last_name[0] || ""}` : "MK"}
            </Avatar>
            <div className="flex flex-col min-w-0">
              <span className="text-xs font-semibold text-foreground truncate">
                {user?.name || "Mustafa Khan"}
              </span>
              <span className="text-[11px] text-muted-foreground truncate">
                {user?.email || "admin@mkx.dev"}
              </span>
            </div>
          </div>

          <MenuItem
            onClick={() => {
              setProfileAnchorEl(null);
              navigate("/settings");
            }}
            className="!text-xs !py-2 !px-2.5 !rounded-[5px] !text-muted-foreground hover:!text-foreground hover:!bg-secondary/70 flex items-center gap-2.5"
          >
            <ListItemIcon className="!min-w-0 !text-muted-foreground">
              <Person className="!w-4 !h-4" />
            </ListItemIcon>
            <span className="text-xs">My Profile</span>
          </MenuItem>

          <MenuItem
            onClick={() => {
              setProfileAnchorEl(null);
              navigate("/settings");
            }}
            className="!text-xs !py-2 !px-2.5 !rounded-[5px] !text-muted-foreground hover:!text-foreground hover:!bg-secondary/70 flex items-center gap-2.5"
          >
            <ListItemIcon className="!min-w-0 !text-muted-foreground">
              <SettingsIcon className="!w-4 !h-4" />
            </ListItemIcon>
            <span className="text-xs">Settings & Security</span>
          </MenuItem>

          <Divider className="!my-1 !border-border/60" />

          <MenuItem
            onClick={() => {
              setProfileAnchorEl(null);
              toggleTheme();
            }}
            className="!text-xs !py-2 !px-2.5 !gap-1 !rounded-[5px] !text-muted-foreground hover:!text-foreground hover:!bg-secondary/70 flex items-center justify-between"
          >
            <div className="flex items-center gap-2.5">
              <ListItemIcon className="!min-w-0 !text-muted-foreground">
                {isDark ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
              </ListItemIcon>
              <span className="text-xs">Appearance</span>
            </div>
            <span className="text-[10px] uppercase font-semibold text-muted-foreground/80 bg-secondary px-1.5 py-0.5 rounded">
              {isDark ? "Dark" : "Light"}
            </span>
          </MenuItem>
          <Divider className="!my-1 !border-border/60" />

          <MenuItem
            onClick={() => {
              setProfileAnchorEl(null);
              logout();
            }}
            className="!text-xs !py-2 !px-2.5 !rounded-[5px] !text-destructive hover:!bg-destructive/10 flex items-center gap-2.5"
          >
            <ListItemIcon className="!min-w-0 !text-destructive">
              <Logout className="!w-4 !h-4 text-destructive" />
            </ListItemIcon>
            <span className="text-xs font-medium text-destructive">Log out</span>
          </MenuItem>
        </ArrowMenu>
      </div>

      <FontSwitcherModal open={fontModalOpen} onClose={() => setFontModalOpen(false)} />
    </header>
  );
}
