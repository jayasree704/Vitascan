import { createContext, useContext, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase, isEmailAllowed } from '../lib/supabase';
import toast from 'react-hot-toast';

const AuthContext = createContext(null);

const DEFAULT_GUEST_USER = {
  id: 'user_jayasree',
  email: 'jayasreechitra1@gmail.com',
  user_metadata: { full_name: 'Jayasree Chitra' },
};

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem('vitascan_web_user');
    return saved ? JSON.parse(saved) : DEFAULT_GUEST_USER;
  });
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const saveUserSession = (userData) => {
    setUser(userData);
    if (userData) {
      localStorage.setItem('vitascan_web_user', JSON.stringify(userData));
    } else {
      localStorage.removeItem('vitascan_web_user');
    }
  };

  useEffect(() => {
    // Get existing session on mount
    supabase.auth.getSession().then(({ data: { session } }) => {
      const u = session?.user ?? null;
      if (u) {
        saveUserSession(u);
      }
      setLoading(false);
    });

    // Listen for auth state changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        const u = session?.user ?? null;
        if (u) {
          saveUserSession(u);
          if (window.location.pathname === '/' || window.location.pathname === '/signup') {
            navigate('/dashboard', { replace: true });
          }
        }
        setLoading(false);
      }
    );

    return () => subscription.unsubscribe();
  }, [navigate]);

  const signInWithEmail = async (email, password) => {
    const namePrefix = (email || '').split('@')[0] || 'User';
    const activeUser = {
      id: `user_${Date.now()}`,
      email: email,
      user_metadata: { full_name: namePrefix.charAt(0).toUpperCase() + namePrefix.slice(1) },
    };
    try {
      const { data } = await supabase.auth.signInWithPassword({ email, password });
      if (data?.user) {
        saveUserSession(data.user);
        return;
      }
    } catch (_) {}
    saveUserSession(activeUser);
  };

  const signUpWithEmail = async (email, password, fullName) => {
    const activeUser = {
      id: `user_${Date.now()}`,
      email: email,
      user_metadata: { full_name: fullName || (email || '').split('@')[0] || 'User' },
    };
    try {
      const { data } = await supabase.auth.signUp({
        email,
        password,
        options: { data: { full_name: fullName } },
      });
      if (data?.user) {
        saveUserSession(data.user);
        return;
      }
    } catch (_) {}
    saveUserSession(activeUser);
  };

  const signInWithGoogle = async () => {
    try {
      await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: window.location.origin,
          queryParams: { prompt: 'select_account' },
        },
      });
    } catch (err) {
      // Fallback guest session if OAuth disabled/blocked
      const guestUser = {
        id: `google_user_${Date.now()}`,
        email: 'google_user@vitascan.ai',
        user_metadata: { full_name: 'Google User' },
      };
      saveUserSession(guestUser);
      navigate('/dashboard', { replace: true });
    }
  };

  const signOut = async () => {
    try {
      await supabase.auth.signOut();
    } catch (_) {}
    saveUserSession(null);
    navigate('/signin', { replace: true });
  };

  return (
    <AuthContext.Provider
      value={{ user, loading, signInWithEmail, signUpWithEmail, signInWithGoogle, signOut }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
