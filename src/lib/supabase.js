import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || 'https://wjhpvnlgzithobsarpxg.supabase.co';
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqaHB2bmxneml0aG9ic2FycHhnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ3MjA1OTUsImV4cCI6MjEwMDI5NjU5NX0.yHGMV8mIpnoSmoOJC_RLzgsxdrA1Knb9vOjGN6t3TEI';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

const allowedList = (import.meta.env.VITE_ALLOWED_EMAILS || 'jayasreechitra1@gmail.com,jagadishwarreddyn11@gmail.com')
  .split(',')
  .map(e => e.trim().toLowerCase());

export const ALLOWED_EMAILS = new Set(allowedList);

export const isEmailAllowed = (email) =>
  ALLOWED_EMAILS.has((email || '').trim().toLowerCase());
