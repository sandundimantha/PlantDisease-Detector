// ─────────────────────────────────────────────────────────────────────────────
// env.dart — Supabase credentials & inference URL
//
// TODO: Replace the placeholder values below with your real Supabase project
// credentials (found in Supabase dashboard → Settings → API).
//
// IMPORTANT: Never commit real credentials to a public repo.
// In production, load these from a .env file using flutter_dotenv.
// ─────────────────────────────────────────────────────────────────────────────
class Env {
  static const String supabaseUrl = 'https://zoqameluujemvtpfbrmm.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpvcWFtZWx1dWplbXZ0cGZicm1tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk0OTQxNzIsImV4cCI6MjEwNTA3MDE3Mn0.i-zPCIfhKMLCKJXcGzGYsOxJJ0AH7Sd0oxueIPtVWZE';
  static const String inferenceUrl = 'https://YOUR_INFERENCE_SERVICE.onrender.com';
}

// ─────────────────────────────────────────────────────────────────────────────
// Confidence thresholds (from crop.md Section 2)
// ─────────────────────────────────────────────────────────────────────────────
class Thresholds {
  /// ≥70% → show result automatically
  static const double autoShow = 0.70;

  /// 40–70% → flag as uncertain, offer cloud inference
  static const double uncertain = 0.40;

  /// <40% → escalate to officer
}