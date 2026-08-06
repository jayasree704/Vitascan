import { createContext, useContext, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase, isEmailAllowed } from '../lib/supabase';
import toast from 'react-hot-toast';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    // Get existing session on mount
    supabase.auth.getSession().then(({ data: { session } }) => {
      const u = session?.user ?? null;
      if (u && !isEmailAllowed(u.email)) {
        supabase.auth.signOut();
        setUser(null);
      } else {
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
    try {
      const { data, error } = await supabase.auth.signInWithPassword({ email, password });
      if (!error && data?.user) return;
    } catch (_) {}
  };

  const signUpWithEmail = async (email, password, fullName) => {
    try {
      await supabase.auth.signUp({
        email,
        password,
        options: { data: { full_name: fullName } },
      });
    } catch (_) {}
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
    await supabase.auth.signOut();
    setUser(null);
    navigate('/', { replace: true });
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
