/// Public configuration only. Server secrets never belong in this model.
final class ClientConfig {
  final String environment;
  final Uri? supabaseUrl;
  final String? anonKey;
  final Uri? functionsUrl;
  final bool debugTools;

  const ClientConfig._(
    this.environment,
    this.supabaseUrl,
    this.anonKey,
    this.functionsUrl,
    this.debugTools,
  );

  factory ClientConfig.fromEnvironment(
    Map<String, String> values, {
    bool allowOffline = false,
  }) {
    final environment = values['APP_ENV'] ?? 'production';
    final debug = values['ENABLE_DEBUG_TOOLS'] == 'true';
    if (environment == 'production' && debug) {
      throw const FormatException(
        'Debug tools must be disabled in production.',
      );
    }
    Uri? endpoint(String name) {
      final value = values[name]?.trim() ?? '';
      if (value.isEmpty && allowOffline) return null;
      final uri = Uri.tryParse(value);
      if (uri == null ||
          !uri.hasAuthority ||
          (uri.scheme != 'https' &&
              !(environment == 'development' &&
                  uri.scheme == 'http' &&
                  ['localhost', '127.0.0.1'].contains(uri.host)))) {
        throw FormatException('$name must be a valid HTTPS endpoint.');
      }
      return uri;
    }

    final url = endpoint('SUPABASE_URL');
    final functions = endpoint('SUPABASE_EDGE_FUNCTIONS_URL');
    final key = values['SUPABASE_ANON_KEY']?.trim();
    if (!allowOffline && (key == null || key.isEmpty)) {
      throw const FormatException('SUPABASE_ANON_KEY is required.');
    }
    return ClientConfig._(environment, url, key, functions, debug);
  }
}
