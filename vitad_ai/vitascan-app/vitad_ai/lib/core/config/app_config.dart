class AppConfig {
  static const String supabaseUrl = 'https://wjhpvnlgzithobsarpxg.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqaHB2bmxneml0aG9ic2FycHhnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ3MjA1OTUsImV4cCI6MjEwMDI5NjU5NX0.yHGMV8mIpnoSmoOJC_RLzgsxdrA1Knb9vOjGN6t3TEI';
  static const String geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'YOUR_GEMINI_API_KEY_HERE');

  static const Set<String> allowedEmails = {
    'jayasreechitra1@gmail.com',
    'jagadishwarreddyn11@gmail.com',
  };

  static bool isEmailAllowed(String? email) {
    if (email == null) return false;
    return allowedEmails.contains(email.trim().toLowerCase());
  }
}
