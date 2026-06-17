/// Supabase client config — anon key is safe in the mobile app.
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lqfzutfhhshditpewedt.supabase.co',
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxxZnp1dGZoaHNoZGl0cGV3ZWR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEwOTAzNDUsImV4cCI6MjA5NjY2NjM0NX0.nv-vnM98X9S8XYY-PwjtnsDfhe5ovYNBbLkG6XdUNZs',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
