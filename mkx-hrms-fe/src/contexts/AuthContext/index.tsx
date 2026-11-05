import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { api } from "libraries/axios";

/**
 * Logged-in user profile structure
 */
export interface AuthUser {
  id: number;
  employee_id: string;
  first_name: string;
  last_name: string;
  name: string;
  email: string;
  avatar: string | null;
  role: string;
  department: string;
  status: string;
  timezone: string;
}

/**
 * Authentication context contract
 */
export interface AuthContextType {
  user: AuthUser | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<string>;
  setSession: (token: string, user: AuthUser) => void;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

/**
 * Authentication Provider component managing JWT session lifecycle
 *
 * @param props - Component children props
 * @returns The wrapped AuthContext provider
 */
export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [token, setToken] = useState<string | null>(() => {
    return typeof window !== "undefined" ? localStorage.getItem("token") : null;
  });

  const [user, setUser] = useState<AuthUser | null>(() => {
    if (typeof window !== "undefined") {
      const stored = localStorage.getItem("user");
      if (stored) {
        try {
          return JSON.parse(stored) as AuthUser;
        } catch {
          return null;
        }
      }
    }
    return null;
  });

  const [isLoading, setIsLoading] = useState<boolean>(true);

  /**
   * Verify existing session on application launch
   */
  useEffect(() => {
    const verifySession = async () => {
      const currentToken = localStorage.getItem("token");
      if (!currentToken) {
        setIsLoading(false);
        return;
      }

      try {
        const [response] = await Promise.all([
          api.get<{ success: boolean; data: AuthUser }>("/v1/auth/me"),
          new Promise((resolve) => setTimeout(resolve, 600)),
        ]);
        if (response.data?.data) {
          setUser(response.data.data);
          localStorage.setItem("user", JSON.stringify(response.data.data));
        }
      } catch {
        localStorage.removeItem("token");
        localStorage.removeItem("user");
        setToken(null);
        setUser(null);
      } finally {
        setIsLoading(false);
      }
    };

    verifySession();
  }, []);

  /**
   * Set active authentication session from token and user profile
   *
   * @param newToken - JWT session token
   * @param newUser - Authenticated user profile
   */
  const setSession = (newToken: string, newUser: AuthUser): void => {
    localStorage.setItem("token", newToken);
    localStorage.setItem("user", JSON.stringify(newUser));
    setToken(newToken);
    setUser(newUser);
  };

  /**
   * Execute authentication login request
   */
  const login = async (email: string, password: string): Promise<string> => {
    const response = await api.post<{
      success: boolean;
      statusCode: number;
      message: string;
      data: { token: string; user: AuthUser };
    }>("/v1/auth/login", {
      email,
      password,
    });

    const { token: receivedToken, user: receivedUser } = response.data.data;
    setSession(receivedToken, receivedUser);

    return response.data.message;
  };

  /**
   * Terminate active session and clear credentials
   */
  const logout = async (): Promise<void> => {
    try {
      await api.post("/v1/auth/logout");
    } catch {
      /** Ignore network error during logout */
    } finally {
      localStorage.removeItem("token");
      localStorage.removeItem("user");
      setToken(null);
      setUser(null);
      window.location.href = "/login";
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        isAuthenticated: Boolean(token),
        isLoading,
        login,
        setSession,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

/**
 * Access the active authentication context
 *
 * @returns AuthContextType containing auth operations and active session
 */
export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};
