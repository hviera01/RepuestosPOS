/// Credenciales de Supabase de este proyecto (Repuestos POS).
///
/// La "anon key" es pública A PROPÓSITO -así funciona Supabase-: es una app
/// de escritorio/móvil sin backend intermedio, así que la clave viaja
/// embebida en el binario igual que viajaba la configuración de Firebase
/// antes. La protección real no es ocultar esta clave (no se puede: cualquiera
/// que abra la app la puede extraer) sino Row Level Security en cada tabla
/// (ver supabase/schema.sql) -acá, con un login propio sin Supabase Auth
/// detrás, la política es "using (true)" para toda operación autenticada con
/// esta clave, igual de abierta que las reglas de Firestore que tenía esta
/// app antes.
class SupabaseConfig {
  static const String url = 'https://PENDIENTE.supabase.co';
  static const String anonKey =
      'PENDIENTE';
}
