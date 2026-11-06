import 'dart:convert';

// This is a Supabase client key (anon/public), which is designed to be shipped
// in client applications. Database access is still constrained by grants/RLS.
const _defaultSupabaseUrl = 'https://jkxucvortrhssfesswmx.supabase.co';
const _defaultSupabasePublicKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpreHVjdm9ydHJoc3NmZXNzd214Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwMTM1MTEsImV4cCI6MjEwODU4OTUxMX0.gsQVdLaLJyy1xjLrNGBA5DGm_7mXc4-m_FriT3aJlzg';

class SupabaseConfig {
  const SupabaseConfig(this.url, this.key);
  final String url, key;
  factory SupabaseConfig.environment() => const SupabaseConfig(
    String.fromEnvironment('SUPABASE_URL', defaultValue: _defaultSupabaseUrl),
    String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: _defaultSupabasePublicKey,
      ),
    ),
  );
  void validate() {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        key.isEmpty) {
      throw const FormatException(
        'Configuração pública de acesso ausente ou inválida.',
      );
    }
    if (key.startsWith('sb_publishable_')) return;
    try {
      final pieces = key.split('.');
      if (pieces.length == 3) {
        final payload =
            jsonDecode(
                  utf8.decode(base64Url.decode(base64Url.normalize(pieces[1]))),
                )
                as Map;
        if (payload['role'] == 'anon') {
          if (uri.host.endsWith('.supabase.co') &&
              payload['ref'] != uri.host.split('.').first) {
            throw const FormatException(
              'Projeto e chave pública não correspondem.',
            );
          }
          return;
        }
      }
    } catch (error) {
      if (error is FormatException &&
          error.message == 'Projeto e chave pública não correspondem.') {
        rethrow;
      }
    }
    throw const FormatException(
      'Use somente uma chave pública anon ou publishable.',
    );
  }
}
