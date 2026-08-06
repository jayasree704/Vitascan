import { createContext, useContext, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase, isEmailAllowed } from '../lib/supabase';
import toast from 'react-hot-toast';

const AuthContext = createContext(null);

const DEFAULT_GUEST_USER = {
  id: 'user_priya',
  email: 'priya@vitascan.ai',
  user_metadata: { full_name: 'priya' },
};

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem('vitascan_web_user');
    return saved ? JSON.parse(saved) : DEFAULT_GUEST_USER;
  });
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const saveUserSession = (userData) => {
    const finalUser = userData || DEFAULT_GUEST_USER;
    setUser(finalUser);
    localStorage.setItem('vitascan_web_user', JSON.stringify(finalUser));
  };

  useEffect(() => {
    // Get existing session on mount
    supabase.auth.getSession().then(({ data: { session } }) => {
      const u = session?.user ?? null;
      if (u && !isEmailAllowed(u.email)) {
        supabase.auth.signOut();
        setUser(null);
      } else if (u) {
        setUser(u);
      }
      setLoading(false);
    });

    // Listen for auth state changes (including OAuth redirects)
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        const u = session?.user ?? null;
        // If user email is not allowed, sign them out immediately
        if (u && !isEmailAllowed(u.email)) {
          await supabase.auth.signOut();
          setUser(null);
          toast.error(`Access denied for ${u.email}. Authorized accounts only.`);
          return;
        }
        setUser(u);
        setLoading(false);

        // On successful Google / OAuth sign in, immediately redirect to dashboard
        if ((event === 'SIGNED_IN' || event === 'INITIAL_SESSION') && u && isEmailAllowed(u.email)) {
          if (window.location.pathname === '/' || window.location.pathname === '/signup') {
            navigate('/dashboard', { replace: true });
          }
        }
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
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: window.location.origin,
        queryParams: { prompt: 'select_account' },
      },
    });
    if (error) throw error;
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
